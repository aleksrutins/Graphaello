import Foundation

struct BasicValidator: Validator {
    let validator: PathValidator
    
    func validate(parsed: Struct<Stage.Parsed>, using apis: [API]) throws -> Struct<Stage.Validated> {
        return try parsed.map { path in
            return try path.map { path in
                return try locateErrors(with: path.extracted.code.location) {
                    return try validator.validate(path: path, using: apis)
                }
            }
        }
    }
}

extension BasicValidator {
    
    init(validator: () -> PathValidator) {
        self.validator = validator()
    }
    
}
