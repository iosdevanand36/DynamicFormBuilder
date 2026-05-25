import SwiftUI
import UIKit

public struct DynamicFormView: View {
    @StateObject private var viewModel: FormViewModel
    @State private var selectedColors: [String: Color] = [:]
    @FocusState private var focusedFieldId: String?

    public init(viewModel: FormViewModel = FormViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationView {
            Group {
                if let form = viewModel.form {
                    let themeTextColor = color(from: form.theme?.textColor) ?? .primary

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(form.formTitle)
                                .font(.title)
                                .bold()
                                .foregroundColor(themeTextColor)

                            ForEach(form.fields.indices, id: \.self) { index in
                                let field = form.fields[index].field
                                fieldView(for: field, textColor: themeTextColor)
                                    .padding(.vertical, 8)
                            }

                            if !viewModel.warnings.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(viewModel.warnings, id: \ .self) { warning in
                                        Text(warning)
                                            .font(.footnote)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }

                            Button(action: submitForm) {
                                Text(viewModel.isSubmitting ? "Submitting..." : "Submit")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
                            .opacity(viewModel.isFormValid ? 1 : 0.5)
                        }
                        .padding()
                        .foregroundColor(themeTextColor)
                        .tint(themeTextColor)
                        .background((color(from: form.theme?.backgroundColor) ?? Color(.systemBackground)).opacity(0.96))
                        .cornerRadius(12)
                        .padding()
                    }
                } else if let message = viewModel.errorMessage {
                    Text(message)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    Text("Loading form...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Dynamic Form")
        }
        .onAppear(perform: loadSampleForm)
    }

    private func loadSampleForm() {
        if let url = Bundle.main.url(forResource: "sample_form", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            viewModel.load(from: data)
            return
        }

        let fallbackJSON = """
        {
          "theme": {
            "background_color": "#121212",
            "text_color": "#E0E0E0",
            "border_color": "#333333",
            "error_color": "#CF6679"
          },
          "form_title": "Comprehensive Campaign Setup",
          "fields": [
            {
              "id": "campaign_name",
              "order": 1,
              "type": "TEXT",
              "subtype": "PLAIN",
              "label": "Campaign Name",
              "default_value": "Summer Sale 2026 Extended Promotional Edition",
              "error_message": "Name is required.",
              "required": true
            },
            {
              "id": "daily_budget",
              "order": 2,
              "type": "TEXT",
              "subtype": "NUMBER",
              "label": "Daily Budget ($)",
              "placeholder": "0.00",
              "error_message": "Budget is required and must be a valid number.",
              "required": true
            },
            {
              "id": "ad_networks",
              "order": 4,
              "type": "DROPDOWN",
              "label": "Ad Networks",
              "allow_multiple": true,
              "error_message": "Please select at least one network.",
              "required": true,
              "options": [
                { "id": "net_google", "label": "Google Search" },
                { "id": "net_meta", "label": "Meta Platforms" },
                { "id": "net_tiktok", "label": "TikTok" }
              ]
            },
            {
              "id": "brand_color",
              "order": 6,
              "type": "COLOR_PICKER",
              "label": "Primary Brand Color",
              "required": true
            },
            {
              "id": "accept_legal",
              "order": 10,
              "type": "CHECKBOX",
              "label": "I have read and agree to the Terms of Service and Privacy Policy.",
              "error_message": "You must accept the legal terms to launch.",
              "required": true,
              "metadata": {
                "Terms of Service": "https://example.com/terms",
                "Privacy Policy": "https://example.com/privacy"
              },
              "clickable_text_color": "#BB86FC"
            }
          ]
        }
        """

        if let data = fallbackJSON.data(using: .utf8) {
            viewModel.load(from: data)
        }
    }

    @ViewBuilder
    private func fieldView(for field: FieldModel, textColor: Color) -> some View {
        switch field {
        case let text as TextFieldModel:
            VStack(alignment: .leading, spacing: 6) {
                Text(text.label)
                    .font(.headline)
                    .foregroundColor(textColor)

                ZStack(alignment: .leading) {
                    if viewModel.value(for: text.id).isEmpty {
                        Text(text.placeholder ?? "Enter value")
                            .foregroundColor(.yellow)
                            .font(.body)
                    }
                    TextField("", text: textBinding(for: text))
                        .foregroundColor(.black)
                        .font(.body)
                        .keyboardType(text.subtype == .number ? .decimalPad : .default)
                        .focused($focusedFieldId, equals: text.id)
                        .padding(.vertical, 4)
                }
                .padding(12)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(textColor.opacity(0.2), lineWidth: 1))

                if viewModel.shouldShowError(for: text.id), let error = viewModel.fieldErrors[text.id] {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
        case let dropdown as DropdownFieldModel:
            VStack(alignment: .leading, spacing: 8) {
                Text(dropdown.label)
                    .font(.headline)
                    .foregroundColor(textColor)

                if dropdown.allowMultiple {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(dropdown.options, id: \.id) { option in
                            Toggle(isOn: Binding(
                                get: { viewModel.selectedValues(for: dropdown.id).contains(option.id) },
                                set: { isOn in
                                    var values = viewModel.selectedValues(for: dropdown.id)
                                    if isOn {
                                        values.append(option.id)
                                    } else {
                                        values.removeAll { $0 == option.id }
                                    }
                                    viewModel.updateSelection(values, for: dropdown.id)
                                }
                            )) {
                                Text(option.label)
                                    .foregroundColor(textColor)
                                    .fontWeight(.medium)
                            }
                            .tint(textColor)
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(12)
                    .background(Color.clear)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(textColor.opacity(0.3), lineWidth: 1))
                } else {
                    Picker(selection: Binding(
                        get: { viewModel.value(for: dropdown.id) },
                        set: { viewModel.updateValue($0, for: dropdown.id) }
                    ), label: Text("Select")) {
                        ForEach(dropdown.options, id: \.id) { option in
                            Text(option.label).tag(option.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(textColor)
                    .padding(12)
                    .background(Color.clear)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(textColor.opacity(0.3), lineWidth: 1))
                }

                if viewModel.shouldShowError(for: dropdown.id), let error = viewModel.fieldErrors[dropdown.id] {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
        case let colorPicker as ColorPickerFieldModel:
            VStack(alignment: .leading, spacing: 6) {
                Text(colorPicker.label)
                    .font(.headline)
                    .foregroundColor(textColor)

                HStack(spacing: 12) {
                    Circle()
                        .fill(selectedColors[colorPicker.id] ?? color(from: viewModel.value(for: colorPicker.id)) ?? .gray)
                        .frame(width: 50, height: 50)
                        .overlay(Circle().stroke(textColor.opacity(0.2), lineWidth: 2))

                    ColorPicker("Select Color", selection: Binding(
                        get: { selectedColors[colorPicker.id] ?? color(from: viewModel.value(for: colorPicker.id)) ?? .gray },
                        set: { newColor in
                            selectedColors[colorPicker.id] = newColor
                            viewModel.updateValue(hexString(from: newColor), for: colorPicker.id)
                        }
                    ))
                    .foregroundColor(textColor)
                    .labelsHidden()
                }
                .padding(12)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(textColor.opacity(0.2), lineWidth: 1))
            }
        case let checkbox as CheckboxFieldModel:
            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: Binding(
                    get: { viewModel.isChecked(checkbox.id) },
                    set: { viewModel.updateCheckbox($0, for: checkbox.id) }
                )) {
                    Text(checkbox.label)
                        .font(.headline)
                        .foregroundColor(textColor)
                }
                .tint(textColor)

                if let metadata = checkbox.metadata {
                    ForEach(metadata.sorted(by: { $0.key < $1.key }), id: \ .key) { key, value in
                        Text("\(key): \(value)")
                            .font(.footnote)
                            .foregroundColor(textColor.opacity(0.8))
                    }
                }

                if viewModel.shouldShowError(for: checkbox.id), let error = viewModel.fieldErrors[checkbox.id] {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
        case let unknown as UnknownFieldModel:
            VStack(alignment: .leading, spacing: 6) {
                Text(unknown.label)
                    .font(.headline)
                Text("Unknown field type: \(unknown.rawType)")
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        default:
            EmptyView()
        }
    }

    private func textBinding(for field: TextFieldModel) -> Binding<String> {
        Binding(
            get: { viewModel.value(for: field.id) },
            set: { viewModel.updateValue($0, for: field.id) }
        )
    }

    private func submitForm() {
        _ = viewModel.submit()
    }

    private func hexString(from color: Color) -> String {
        let uiColor = UIColor(color)
        guard let components = uiColor.cgColor.components, components.count >= 3 else {
            return "#808080"
        }
        let red = Int((components[0] * 255.0).rounded())
        let green = Int((components[1] * 255.0).rounded())
        let blue = Int((components[2] * 255.0).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    private func color(from hex: String?) -> Color? {
        guard let hex = hex else { return nil }
        var normalized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasPrefix("#") {
            normalized.removeFirst()
        }

        guard normalized.count == 6 else { return nil }
        let scanner = Scanner(string: normalized)
        var rgb: UInt64 = 0
        guard scanner.scanHexInt64(&rgb) else { return nil }

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        return Color(red: red, green: green, blue: blue)
    }
}
