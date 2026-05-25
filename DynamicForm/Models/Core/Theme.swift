import Foundation

public struct Theme: Codable {
    public let backgroundColor: String?
    public let textColor: String?
    public let borderColor: String?
    public let errorColor: String?

    enum CodingKeys: String, CodingKey {
        case backgroundColor = "background_color"
        case textColor = "text_color"
        case borderColor = "border_color"
        case errorColor = "error_color"
    }
}
