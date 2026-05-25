import Foundation

public protocol FormComponent: Codable {
    var id: String { get }
    var type: FieldType { get }
    var label: String { get }
}

public struct FormDefinition: Codable {
    public let formTitle: String
    public let theme: Theme?
    public let fields: [AnyFieldModel]

    enum CodingKeys: String, CodingKey {
        case formTitle = "form_title"
        case theme
        case fields
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.formTitle = try container.decodeIfPresent(String.self, forKey: .formTitle) ?? ""
        self.theme = try container.decodeIfPresent(Theme.self, forKey: .theme)
        self.fields = try container.decodeIfPresent([AnyFieldModel].self, forKey: .fields) ?? []
    }
}
