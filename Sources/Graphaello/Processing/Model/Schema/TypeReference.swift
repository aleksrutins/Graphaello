import Foundation

extension Schema {

    struct TypeReference: Codable, Hashable {
        let name: String
    }

}

extension Schema.GraphQLType.Field {

    indirect enum TypeReference: Equatable, Hashable {
        case concrete(Definition)
        case complex(Definition, ofType: TypeReference)
    }

}

extension Schema.GraphQLType.Field.TypeReference {
    
    var underlyingTypeName: String {
        switch self {
        case .concrete(let definition):
            return definition.name ?? "Any"
        case .complex(_, let ofType):
            return ofType.underlyingTypeName
        }
    }
    
    var graphQLType: String {
        switch self {

        case .concrete(let definition):
            return definition.name ?? "Any"

        case .complex(let definition, let ofType):
            switch definition.kind {
            case .list:
                return "[\(ofType.graphQLType)]"
            case .nonNull:
                return "\(ofType.graphQLType)!"
            case .scalar, .object, .enum, .interface, .inputObject, .union:
                return ofType.graphQLType
            }
        }
    }

    func swiftType(api: String?, for fragment: GraphQLFragment? = nil) -> String {
        switch self {

        case .concrete(let definition):
            guard let name = definition.name, let api = api else { return "Any" }

            if case .scalar = definition.kind {
                switch name {
                case "Boolean":
                    return "Bool?"
                case "Int":
                    return "Int?"
                case "Float":
                    return "Double?"
                default:
                    return "String?"
                }
            }
            
            if let fragment = fragment {
                assert(fragment.target.name == definition.name)
                return "Apollo\(api.upperCamelized).\(fragment.name.upperCamelized)?"
            }

            return "\(api.upperCamelized).\(name.upperCamelized)?"

        case .complex(let definition, let ofType):
            switch definition.kind {
            case .list:
                return "[\(ofType.swiftType(api: api, for: fragment))]?"
            case .nonNull:
                return String(ofType.swiftType(api: api, for: fragment).dropLast())
            case .scalar, .object, .enum, .interface, .inputObject, .union:
                return ofType.swiftType(api: api, for: fragment)
            }
        }
    }

    var isFragment: Bool {
        switch self {
        case .concrete(let definition):
            return definition.kind.isFragment
        case .complex(_, let ofType):
            return ofType.isFragment
        }
    }

    var optional: Schema.GraphQLType.Field.TypeReference {
        switch self {
        case .concrete:
            return self
        case .complex(let definition, let ofType):
            switch definition.kind {
            case .nonNull:
                return ofType
            case .list, .scalar, .object, .enum, .interface, .inputObject, .union:
                return self
            }
        }
    }

    var nonNull: Schema.GraphQLType.Field.TypeReference {
        if case .complex(let definition, _) = self, case .nonNull = definition.kind {
            return self
        }
        return .complex(.init(kind: .nonNull, name: nil), ofType: self)
    }

    var isScalar: Bool {
        switch self {
        case .concrete(let definition):
            return definition.kind == .scalar
        case .complex(let definition, let ofType):
            if case .nonNull = definition.kind {
                return ofType.isScalar
            }
            return false
        }
    }

}
