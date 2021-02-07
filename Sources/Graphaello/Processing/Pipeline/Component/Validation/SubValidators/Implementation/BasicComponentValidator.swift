import Foundation

struct BasicComponentValidator: ComponentValidator {
    let operationValidator: OperationTypeValidator
    let transpiler: GraphQLToSwiftTranspiler
    
    func validate(component: Stage.Parsed.Component,
                  using context: ComponentValidation.Context) throws -> ComponentValidation.Result {
        
        switch (component, context.type) {

        case (.operation(let operation), _):
            let type = try operationValidator.validate(operation: operation, using: context)
            let component = Stage.Validated.Component(reference: .type(type),
                                                      underlyingType: context.type.graphQLType,
                                                      parsed: component)

            return .init(component: component, type: context.type)

        case (.property(let name), .object(let type)):
            if let interface = type.interfaces?[name.upperCamelized] {
                let type = try context.api[interface.name] ?!
                    GraphQLPathValidationError.typeNotFound(interface.name, api: context.api)

                let component = Stage.Validated.Component(reference: .casting(.up),
                                                 underlyingType: type.graphQLType,
                                                 parsed: component)

                return .init(component: component, type: type)
            } else if let possibleType = type.possibleTypes?[name.upperCamelized] {
                let type = try context.api[possibleType.name] ?!
                    GraphQLPathValidationError.typeNotFound(possibleType.name, api: context.api)

                let component = Stage.Validated.Component(reference: .casting(.down),
                                                          underlyingType: type.graphQLType,
                                                          parsed: component)

                return .init(component: component, type: type)
            }

            let field = try type.fields?[name] ?! GraphQLPathValidationError.fieldNotFoundInType(name, type: type)
            if field.arguments.isEmpty {
                let type = try context.api[field.type.underlyingTypeName] ?!
                    GraphQLPathValidationError.typeNotFound(field.type.underlyingTypeName, api: context.api)

                let component = Stage.Validated.Component(reference: .field(field),
                                                          underlyingType: type.graphQLType,
                                                          parsed: component)
                
                return .init(component: component, type: type)
            } else {
                return try validate(component: .call(name, []), using: context)
            }

        case (.fragment, .object):
            return .init(component: context.fragmentComponent(), type: context.type)

        case (.call(let name, let arguments), .object(let type)):
            let field = try type.fields?[name] ?! GraphQLPathValidationError.fieldNotFoundInType(name, type: type)

            let arguments = try field.defaultArgumentDictionary(using: transpiler,
                                                                with: context.api,
                                                                merged: arguments)

            let type = try context.api[field.type.underlyingTypeName] ?!
                GraphQLPathValidationError.typeNotFound(field.type.underlyingTypeName, api: context.api)

            let component = Stage.Validated.Component(reference: .field(field),
                                                      underlyingType: type.graphQLType,
                                                      parsed: .call(name, arguments))
            
            return .init(component: component, type: type)

        case (_, .scalar(let type)):
            throw GraphQLPathValidationError.cannotCallUseComponentForScalar(component, type: type)

        }
    }
    
}

extension BasicComponentValidator {

    init(operationValidator: () -> OperationTypeValidator, transpiler: () -> GraphQLToSwiftTranspiler) {
        self.init(operationValidator: operationValidator(), transpiler: transpiler())
    }

}

extension Schema.GraphQLType.Field {

    func defaultArgumentDictionary(using transpiler: GraphQLToSwiftTranspiler,
                                   with api: API,
                                   merged otherArguments: [Field.Argument] = []) throws -> [Field.Argument] {

        let otherArguments = Dictionary(uniqueKeysWithValues: otherArguments.map { ($0.name, $0.value) })
        return try self.arguments.map { argument in
            let value = try otherArguments[argument.name] ??
                transpiler.expression(from: argument.defaultValue,
                                      for: argument.type,
                                      using: api).map { .argument(.withDefault($0.erased())) } ?? .argument(.forced)

            return Field.Argument(name: argument.name, value: value)
        }
    }

}
