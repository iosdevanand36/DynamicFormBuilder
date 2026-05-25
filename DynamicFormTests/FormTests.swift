import XCTest
@testable import DynamicForm

final class FormTests: XCTestCase {
    func testParseValidForm() throws {
        let json = """
        {
            "form_title": "Registration",
            "fields": [
                {
                    "type": "TEXT",
                    "id": "username",
                    "label": "Username",
                    "placeholder": "Enter username",
                    "required": true,
                    "max_length": 16
                },
                {
                    "type": "DROPDOWN",
                    "id": "plan",
                    "label": "Plan",
                    "required": true,
                    "options": [
                        { "id": "basic", "label": "Basic" },
                        { "id": "pro", "label": "Pro" }
                    ]
                },
                {
                    "type": "CHECKBOX",
                    "id": "agreement",
                    "label": "Accept Terms",
                    "required": true
                }
            ]
        }
        """

        let result = FormParser().parse(json.data(using: .utf8)!)
        switch result {
        case .success(let parseResult):
            XCTAssertEqual(parseResult.form.formTitle, "Registration")
            XCTAssertEqual(parseResult.form.fields.count, 3)
            XCTAssertTrue(parseResult.warnings.isEmpty)

            let ids = parseResult.form.fields.map { $0.id }
            XCTAssertEqual(ids, ["username", "plan", "agreement"])
        case .failure(let error):
            XCTFail("Expected valid parse, got failure: \(error)")
        }
    }

    func testParseMalformedJSONReturnsFailure() {
        let malformedJson = "{ \"form_title\": \"Broken\", \"fields\": [ { \"type\": \"TEXT\", } ] }"
        let result = FormParser().parse(malformedJson.data(using: .utf8)!)

        switch result {
        case .success:
            XCTFail("Expected parse failure for malformed JSON")
        case .failure(let error):
            if case .decodingFailed = error {
                break
            } else {
                XCTFail("Expected decodingFailed error, got \(error)")
            }
        }
    }

    func testParseUnknownFieldTypeProducesUnknownFieldModel() throws {
        let json = """
        {
            "form_title": "Unknown Type Test",
            "fields": [
                {
                    "type": "MAGIC",
                    "id": "mystery",
                    "label": "Mystery Field"
                }
            ]
        }
        """

        let result = FormParser().parse(json.data(using: .utf8)!)
        switch result {
        case .success(let parseResult):
            XCTAssertEqual(parseResult.form.fields.count, 1)
            XCTAssertTrue(parseResult.form.fields.first is UnknownFieldModel)
            XCTAssertTrue(parseResult.warnings.isEmpty)
        case .failure(let error):
            XCTFail("Expected parse success with fallback unknown field model, got failure: \(error)")
        }
    }

    func testValidationFailsWhenRequiredTextFieldEmpty() throws {
        let json = """
        {
            "form_title": "Validation Test",
            "fields": [
                {
                    "type": "TEXT",
                    "id": "email",
                    "label": "Email",
                    "required": true
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let viewModel = FormViewModel()
        viewModel.load(from: data)
        viewModel.updateValue("", for: "email")

        XCTAssertFalse(viewModel.isFormValid)
        XCTAssertEqual(viewModel.fieldErrors["email"], "Email is required.")
    }

    func testValidationFailsWhenTextFieldExceedsMaxLength() throws {
        let json = """
        {
            "form_title": "Length Test",
            "fields": [
                {
                    "type": "TEXT",
                    "id": "nickname",
                    "label": "Nickname",
                    "max_length": 4
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let viewModel = FormViewModel()
        viewModel.load(from: data)
        viewModel.updateValue("toolong", for: "nickname")

        XCTAssertFalse(viewModel.isFormValid)
        XCTAssertEqual(viewModel.fieldErrors["nickname"], "Nickname must be at most 4 characters.")
    }

    func testValidationFailsWhenNumericFieldContainsNonNumericValue() throws {
        let json = """
        {
            "form_title": "Number Test",
            "fields": [
                {
                    "type": "TEXT",
                    "id": "age",
                    "label": "Age",
                    "subtype": "NUMBER"
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let viewModel = FormViewModel()
        viewModel.load(from: data)
        viewModel.updateValue("abc", for: "age")

        XCTAssertFalse(viewModel.isFormValid)
        XCTAssertEqual(viewModel.fieldErrors["age"], "Age must be a number.")
    }

    func testValidationFailsWhenCheckboxIsRequiredButUnchecked() throws {
        let json = """
        {
            "form_title": "Checkbox Test",
            "fields": [
                {
                    "type": "CHECKBOX",
                    "id": "accept",
                    "label": "Accept Terms",
                    "required": true
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let viewModel = FormViewModel()
        viewModel.load(from: data)
        viewModel.updateCheckbox(false, for: "accept")

        XCTAssertFalse(viewModel.isFormValid)
        XCTAssertEqual(viewModel.fieldErrors["accept"], "Accept Terms must be accepted.")
    }

    func testSubmitReturnsNilWhenValidationFails() throws {
        let json = """
        {
            "form_title": "Submit Test",
            "fields": [
                {
                    "type": "TEXT",
                    "id": "firstName",
                    "label": "First Name",
                    "required": true
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let viewModel = FormViewModel()
        viewModel.load(from: data)

        XCTAssertFalse(viewModel.submit())
    }
}
