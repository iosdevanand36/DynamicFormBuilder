import Foundation

public enum FieldType: String, Codable {
    case text = "TEXT"
    case dropdown = "DROPDOWN"
    case colorPicker = "COLOR_PICKER"
    case checkbox = "CHECKBOX"
    case unknown = "UNKNOWN"

    public init(_ rawValue: String) {
        self = FieldType(rawValue: rawValue) ?? .unknown
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = FieldType(rawValue: rawValue) ?? .unknown
    }
}

public enum TextSubtype: String, Codable {
    case plain = "PLAIN"
    case number = "NUMBER"
    case unknown = "UNKNOWN"

    public init(_ rawValue: String) {
        self = TextSubtype(rawValue: rawValue) ?? .unknown
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = TextSubtype(rawValue: rawValue) ?? .unknown
    }
}

public struct FieldOption: Codable {
    public let id: String
    public let label: String
}

public protocol FieldModel: FormComponent {
    var required: Bool { get }
    var errorMessage: String? { get }
}

public struct TextFieldModel: FieldModel {
    public let id: String
    public let type: FieldType = .text
    public let label: String
    public let order: Int?
    public let subtype: TextSubtype
    public let placeholder: String?
    public let defaultValue: String?
    public let maxLength: Int?
    public let errorMessage: String?
    public let required: Bool

    enum CodingKeys: String, CodingKey {
        case id, label, order, subtype, placeholder
        case defaultValue = "default_value"
        case maxLength = "max_length"
        case errorMessage = "error_message"
        case required
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        self.order = try container.decodeIfPresent(Int.self, forKey: .order)
        self.subtype = try container.decodeIfPresent(TextSubtype.self, forKey: .subtype) ?? .plain
        self.placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
        self.defaultValue = try container.decodeIfPresent(String.self, forKey: .defaultValue)
        self.maxLength = try container.decodeIfPresent(Int.self, forKey: .maxLength)
        self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        self.required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
    }
}

public struct DropdownFieldModel: FieldModel {
    public let id: String
    public let type: FieldType = .dropdown
    public let label: String
    public let order: Int?
    public let allowMultiple: Bool
    public let options: [FieldOption]
    public let errorMessage: String?
    public let required: Bool

    enum CodingKeys: String, CodingKey {
        case id, label, order
        case allowMultiple = "allow_multiple"
        case options, errorMessage = "error_message", required
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        self.order = try container.decodeIfPresent(Int.self, forKey: .order)
        self.allowMultiple = try container.decodeIfPresent(Bool.self, forKey: .allowMultiple) ?? false
        self.options = try container.decodeIfPresent([FieldOption].self, forKey: .options) ?? []
        self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        self.required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
    }
}

public struct ColorPickerFieldModel: FieldModel {
    public let id: String
    public let type: FieldType = .colorPicker
    public let label: String
    public let order: Int?
    public let errorMessage: String?
    public let required: Bool

    enum CodingKeys: String, CodingKey {
        case id, label, order, errorMessage = "error_message", required
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        self.order = try container.decodeIfPresent(Int.self, forKey: .order)
        self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        self.required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
    }
}

public struct CheckboxFieldModel: FieldModel {
    public let id: String
    public let type: FieldType = .checkbox
    public let label: String
    public let order: Int?
    public let metadata: [String: String]?
    public let clickableTextColor: String?
    public let errorMessage: String?
    public let required: Bool

    enum CodingKeys: String, CodingKey {
        case id, label, order, metadata
        case clickableTextColor = "clickable_text_color"
        case errorMessage = "error_message"
        case required
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        self.order = try container.decodeIfPresent(Int.self, forKey: .order)
        self.metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
        self.clickableTextColor = try container.decodeIfPresent(String.self, forKey: .clickableTextColor)
        self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        self.required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
    }
}

private struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

public struct UnknownFieldModel: FieldModel {
    public let id: String
    public let type: FieldType = .unknown
    public let label: String
    public let order: Int?
    public let rawType: String
    public let rawData: [String: AnyCodable]
    public let errorMessage: String? = nil
    public let required: Bool = false

    public init(id: String, label: String, order: Int?, rawType: String, rawData: [String: AnyCodable]) {
        self.id = id
        self.label = label
        self.order = order
        self.rawType = rawType
        self.rawData = rawData
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        self.id = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "id")!) ?? UUID().uuidString
        self.label = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "label")!) ?? "Unknown"
        self.order = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKeys(stringValue: "order")!)
        self.rawType = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "type")!) ?? "UNKNOWN"

        var rawData: [String: AnyCodable] = [:]
        for key in container.allKeys {
            if let value = try container.decodeIfPresent(AnyCodable.self, forKey: key) {
                rawData[key.stringValue] = value
            }
        }
        self.rawData = rawData
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encode(id, forKey: DynamicCodingKeys(stringValue: "id")!)
        try container.encode(label, forKey: DynamicCodingKeys(stringValue: "label")!)
        try container.encodeIfPresent(order, forKey: DynamicCodingKeys(stringValue: "order")!)
        try container.encode(rawType, forKey: DynamicCodingKeys(stringValue: "type")!)

        for (key, value) in rawData {
            try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
        }
    }
}

public struct AnyFieldModel: Codable {
    public let field: FieldModel

    public init(_ field: FieldModel) {
        self.field = field
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeRaw = try container.decodeIfPresent(String.self, forKey: .type) ?? "UNKNOWN"
        let type = FieldType(rawValue: typeRaw) ?? .unknown

        do {
            switch type {
            case .text:
                self.field = try TextFieldModel(from: decoder)
            case .dropdown:
                self.field = try DropdownFieldModel(from: decoder)
            case .colorPicker:
                self.field = try ColorPickerFieldModel(from: decoder)
            case .checkbox:
                self.field = try CheckboxFieldModel(from: decoder)
            case .unknown:
                self.field = try UnknownFieldModel(from: decoder)
            }
        } catch {
            self.field = try UnknownFieldModel(from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        try field.encode(to: encoder)
    }

    enum CodingKeys: String, CodingKey {
        case type
    }
}

public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intVal = try? container.decode(Int.self) {
            self.value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            self.value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            self.value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            self.value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            self.value = arrayVal.map { $0.value }
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            self.value = dictVal.mapValues { $0.value }
        } else if container.decodeNil() {
            self.value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let arrayVal as [Any]:
            try container.encode(arrayVal.map { AnyCodable($0) })
        case let dictVal as [String: Any]:
            try container.encode(dictVal.mapValues { AnyCodable($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported value"))
        }
    }
}
