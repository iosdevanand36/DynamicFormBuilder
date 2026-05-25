import Foundation
import Combine

public final class FormViewModel: ObservableObject {
    @Published public private(set) var form: FormDefinition?
    @Published public var fieldValues: [String: String] = [:]
    @Published public var multiSelectValues: [String: [String]] = [:]
    @Published public var checkboxValues: [String: Bool] = [:]
    @Published public private(set) var fieldErrors: [String: String] = [:]
    @Published public private(set) var warnings: [String] = []
    @Published public private(set) var errorMessage: String? = nil
    @Published public private(set) var isFormValid: Bool = false
    @Published public private(set) var isSubmitting: Bool = false
    @Published public private(set) var lastSubmissionJSON: String? = nil
    @Published public private(set) var lastSubmission: [String: Any] = [:]
    @Published public private(set) var touchedFields: Set<String> = []
    @Published public private(set) var showErrors: Bool = false

    private let parser: FormParser
    private var cancellables = Set<AnyCancellable>()

    public init(parser: FormParser = FormParser()) {
        self.parser = parser
    }

    public func load(from jsonData: Data) {
        switch parser.parse(jsonData) {
        case .success(let result):
            self.form = result.form
            self.warnings = result.warnings
            self.errorMessage = nil
            self.fieldErrors = [:]
            self.isFormValid = false
            self.touchedFields = []
            self.showErrors = false
            initializeFieldValues(from: result.form)
            validateForm()
        case .failure(let error):
            self.form = nil
            self.warnings = []
            self.errorMessage = error.localizedDescription
            self.fieldValues = [:]
            self.fieldErrors = [:]
            self.multiSelectValues = [:]
            self.checkboxValues = [:]
            self.isFormValid = false
            self.touchedFields = []
            self.showErrors = false
        }
    }

    public func updateValue(_ value: String, for fieldId: String) {
        fieldValues[fieldId] = value
        touchedFields.insert(fieldId)
        validate(fieldId: fieldId)
        validateForm()
    }

    public func updateSelection(_ values: [String], for fieldId: String) {
        multiSelectValues[fieldId] = values
        touchedFields.insert(fieldId)
        validate(fieldId: fieldId)
        validateForm()
    }

    public func updateCheckbox(_ isOn: Bool, for fieldId: String) {
        checkboxValues[fieldId] = isOn
        touchedFields.insert(fieldId)
        validate(fieldId: fieldId)
        validateForm()
    }

    public func validate(fieldId: String) {
        guard let field = field(withId: fieldId) else { return }
        let result = validate(field: field)
        fieldErrors[fieldId] = result.errorMessage
    }

    public func validateForm() {
        fieldErrors = [:]
        guard let fields = form?.fields else {
            isFormValid = false
            return
        }

        for entry in fields {
            let field = entry.field
            let result = validate(field: field)
            fieldErrors[field.id] = result.errorMessage
        }

        isFormValid = fieldErrors.values.allSatisfy { $0 == nil }
    }

    public func submit() -> Bool {
        showErrors = true
        validateForm()
        guard isFormValid, let form = form else { return false }

        // Build submission payload from current state
        var payload: [String: Any] = [:]
        payload["form_title"] = form.formTitle

        var fieldsPayload: [String: Any] = [:]
        for entry in form.fields {
            let field = entry.field
            switch field {
            case let text as TextFieldModel:
                fieldsPayload[field.id] = fieldValues[field.id] ?? ""
            case let dropdown as DropdownFieldModel:
                if dropdown.allowMultiple {
                    fieldsPayload[field.id] = multiSelectValues[field.id] ?? []
                } else {
                    fieldsPayload[field.id] = fieldValues[field.id] ?? ""
                }
            case let checkbox as CheckboxFieldModel:
                fieldsPayload[field.id] = checkboxValues[field.id] ?? false
            case let color as ColorPickerFieldModel:
                fieldsPayload[field.id] = fieldValues[field.id] ?? ""
            case let unknown as UnknownFieldModel:
                var rd: [String: Any] = [:]
                for (k, v) in unknown.rawData {
                    rd[k] = v.value
                }
                fieldsPayload[field.id] = ["raw_type": unknown.rawType, "raw_data": rd]
            default:
                fieldsPayload[field.id] = ""
            }
        }

        payload["fields"] = fieldsPayload

        // Serialize to pretty JSON for UI + console
        if JSONSerialization.isValidJSONObject(payload),
           let data = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
           let jsonString = String(data: data, encoding: .utf8) {
            lastSubmissionJSON = jsonString
        } else {
            lastSubmissionJSON = nil
        }

        lastSubmission = payload
        print("Form submission:\n", lastSubmission)

        isSubmitting = true
        defer { isSubmitting = false }
        return true
    }

    public func shouldShowError(for fieldId: String) -> Bool {
        showErrors || touchedFields.contains(fieldId)
    }

    public func value(for fieldId: String) -> String {
        fieldValues[fieldId] ?? ""
    }

    public func selectedValues(for fieldId: String) -> [String] {
        multiSelectValues[fieldId] ?? []
    }

    public func isChecked(_ fieldId: String) -> Bool {
        checkboxValues[fieldId] ?? false
    }

    // MARK: - Private helpers

    private func initializeFieldValues(from form: FormDefinition) {
        var values: [String: String] = [:]
        var multiValues: [String: [String]] = [:]
        var checks: [String: Bool] = [:]

        for entry in form.fields {
            let field = entry.field
            switch field {
            case let text as TextFieldModel:
                values[field.id] = text.defaultValue ?? ""
            case let dropdown as DropdownFieldModel:
                if !dropdown.allowMultiple, let first = dropdown.options.first {
                    values[field.id] = first.id
                } else {
                    multiValues[field.id] = []
                }
            case let checkbox as CheckboxFieldModel:
                checks[field.id] = false
            default:
                break
            }
        }

        fieldValues = values
        multiSelectValues = multiValues
        checkboxValues = checks
    }

    private func validate(field: FieldModel) -> ValidationResult {
        if field.required {
            if let text = fieldValues[field.id], !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // continue
            } else if let selections = multiSelectValues[field.id], !selections.isEmpty {
                // continue
            } else if let checked = checkboxValues[field.id], checked {
                // continue
            } else {
                return .failure(field.errorMessage ?? "\(field.label) is required.")
            }
        }

        switch field {
        case let text as TextFieldModel:
            if text.subtype == .number {
                let value = fieldValues[field.id] ?? ""
                if !value.isEmpty && Double(value) == nil {
                    return .failure(text.errorMessage ?? "\(text.label) must be a number.")
                }
            }
            if let maxLength = text.maxLength, let value = fieldValues[field.id], value.count > maxLength {
                return .failure(text.errorMessage ?? "\(text.label) must be at most \(maxLength) characters.")
            }
        case let dropdown as DropdownFieldModel:
            if dropdown.allowMultiple {
                let values = multiSelectValues[field.id] ?? []
                if values.isEmpty {
                    return .failure(dropdown.errorMessage ?? "\(dropdown.label) requires at least one selection.")
                }
            } else {
                let value = fieldValues[field.id] ?? ""
                if value.isEmpty {
                    return .failure(dropdown.errorMessage ?? "\(dropdown.label) is required.")
                }
            }
        case is CheckboxFieldModel:
            if let checked = checkboxValues[field.id], !checked {
                return .failure(field.errorMessage ?? "\(field.label) must be accepted.")
            }
        default:
            break
        }

        return .success
    }

    private func field(withId id: String) -> FieldModel? {
        form?.fields.first(where: { $0.field.id == id })?.field
    }
}

public struct ValidationResult {
    public let isValid: Bool
    public let errorMessage: String?

    public static var success: ValidationResult {
        ValidationResult(isValid: true, errorMessage: nil)
    }

    public static func failure(_ message: String) -> ValidationResult {
        ValidationResult(isValid: false, errorMessage: message)
    }
}
