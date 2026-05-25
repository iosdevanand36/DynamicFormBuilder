# DynamicForm

A Server-Driven UI SwiftUI sample that demonstrates dynamic form rendering from JSON, polymorphic Codable decoding, defensive parsing, validation, and lightweight MVVM state management.

## Overview

This project shows how to build a server-driven form engine using native Swift tools:

- `SwiftUI` for declarative UI rendering
- `Codable` for JSON-driven component mapping
- `MVVM` for form state, validation, and submission
- `XCTest` for parsing and validation coverage

## Architecture

- `DynamicForm/Models` — form and field models, polymorphic decoding for dynamic component types
- `DynamicForm/Services` — parser layer for JSON-to-model translation
- `DynamicForm/ViewModels` — stateful form view model with validation and submit logic
- `DynamicForm/Views` — SwiftUI views for dynamic form layout and runtime rendering

## Key Features

- JSON-driven form definition parsing
- Safe fallback for unknown or unsupported field types
- Dynamic field rendering for text, dropdown, checkbox, and more
- Required field validation, numeric validation, max-length checks, and checkbox validation
- Test coverage for parsing, malformed JSON, unknown component types, and validation edge cases

## Project Structure

- `DynamicForm/DynamicFormApp.swift` — app entry point
- `DynamicForm/ContentView.swift` — sample form host view
- `DynamicForm/Models/Core` — core form contract and theme model
- `DynamicForm/Models/Fields` — concrete field models and polymorphic wrapper
- `DynamicForm/Services/Parsing` — form parser and parse result handling
- `DynamicForm/ViewModels` — form state, validation, and submit flow
- `DynamicForm/Views/Dynamic` — dynamic form UI renderer
- `DynamicFormTests/` — unit tests covering parser and view model behavior

## JSON Schema

The dynamic form JSON supports:

- `form_title` — displayed form title
- `fields` — array of field definitions
- field `type` values such as `TEXT`, `DROPDOWN`, `CHECKBOX`, and unknown values handled safely
- field-specific properties such as `label`, `required`, `max_length`, `options`, and `subtype`

## Architecture

The app follows **MVVM** with clear separation of concerns:

```
JSON → Parser → FormDefinition → ViewModel (validation state) → View (renders dynamically)
```

- **Models**: `FormDefinition`, `AnyFieldModel`, type-specific field models. Polymorphic `Codable` decoding handles unknown field types safely.
- **Parser**: Converts raw JSON into strongly-typed models. Returns warnings for recoverable issues.
- **ViewModel** (`FormViewModel`): Manages form state (`fieldValues`, `fieldErrors`, `touchedFields`, `isFormValid`). Orchestrates validation on field change and submit.
- **View** (`DynamicFormView`): Renders form dynamically using `@ViewBuilder` and `switch` statements. Observes ViewModel for reactive updates.

**Data Flow**: TextField input → `updateValue()` → validation → `fieldErrors` update → UI re-renders.

## Setup

1. **Clone/open** the project in Xcode 15+.
2. **Select scheme**: `DynamicForm` for the app, `DynamicFormTests` for tests.
3. **Choose simulator**: iPhone 16 iOS 18.3.1 (or any iOS 18+).
4. **Build & run**: `Cmd+R` or via terminal:
   ```bash
   xcodebuild -project DynamicForm.xcodeproj -scheme DynamicForm build
   ```

No external dependencies—uses only Apple frameworks (Combine, SwiftUI).

## Validation

Validation happens at two points:

1. **On Field Change** (`updateValue`, `updateSelection`, `updateCheckbox`):
   - Field is marked as "touched"
   - Single field validation runs
   - Error only shows if field is touched OR form submit attempted

2. **On Submit** (`submit()`):
   - Sets `showErrors = true`
   - All fields validated
   - Returns success only if no errors exist

**Validation Rules**:
- `required: true` — field must have a value (non-empty string, selection, or checked checkbox)
- `subtype: "NUMBER"` — textfield must be numeric
- `max_length` — textfield character limit
- Multi-select dropdown — requires at least one option selected

## TDD

Test file: `DynamicFormTests/FormTests.swift`.

Coverage includes:
- **Parsing**: Valid JSON → correct model structure; malformed JSON → safe defaults
- **Unknown fields**: Graceful handling via `UnknownFieldModel`
- **Validation**: Required fields, numeric validation, character limits, multi-select logic
- **Edge cases**: Empty form, all-required fields, invalid field types

Run tests:
```bash
xcodebuild -project DynamicForm.xcodeproj -scheme DynamicFormTests test
```

Tests are written *after* implementation for comprehensive validation of parser and ViewModel behavior.

## AI Workflow

This project was built using an AI-assisted iterative workflow:

1. **Discovery**: Parse requirements (blank screen → interactive form → validation → UI polish)
2. **Implementation**: AI generates/refines code, handles model design, view structure
3. **Validation**: Each change verified via build and runtime testing
4. **Iteration**: User feedback → code adjustment → re-test
5. **Documentation**: Concise inline comments and README sections

The workflow emphasizes:
- Rapid prototyping with immediate feedback loops
- Defensive coding (safe fallbacks, error handling)
- Modular design (easy to extend field types, validation rules)
- Test coverage from the start

## Testing

- The test target is `DynamicFormTests`.
- Test file: `DynamicFormTests/FormTests.swift`.
- Run tests via Xcode or using the command line:

```bash
xcodebuild -project DynamicForm.xcodeproj -scheme DynamicFormTests -destination 'platform=iOS Simulator,name=iPhone 15' test
```

## Notes

- The current parser returns default values and safe fallback models for malformed or unsupported JSON structures.
- The view model is designed for easy unit testing by isolating load, update, validation, and submit behavior.
- Future improvements can include a plugin-style component registry, remote schema fetching, and more advanced validation rules.

## License

This repository is intended for educational use and sample implementation of server-driven UI concepts.
