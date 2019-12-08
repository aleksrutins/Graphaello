//
//  PathResolver.swift
//  Graphaello
//
//  Created by Mathias Quintero on 08.12.19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftSyntax

struct PathResolver: ValueResolver {
    
    func resolve(value: Stage.Validated.Path,
                 in property: Property<Stage.Validated>,
                 using context: StructResolution.Context) throws -> StructResolution.Result<Stage.Resolved.Path> {
        
        guard value.components.last?.parsed == .fragment else {
            return .resolved(.init(validated: value, referencedFragment: nil))
        }
        
        let fragmentName = try StructResolution.FragmentName(typeName: property.type)
        guard let fragment = context[fragmentName] else { return .missingFragment }
        
        return .resolved(Stage.Resolved.Path(validated: value, referencedFragment: fragment))
    }
    
}

extension StructResolution.FragmentName {
    
    init(typeName: String) throws {
        guard let syntax = try SourceCode(content: typeName).syntaxTree().singleItem() else  {
            throw GraphQLFragmentResolverError.invalidTypeNameForFragment(typeName)
        }
        try self.init(syntax: syntax)
    }
    
    init(syntax: Syntax) throws {
        switch syntax {
        case let expression as IdentifierExprSyntax:
            self = .fullName(expression.identifier.text)
        case let expression as MemberAccessExprSyntax:
            guard let base = expression.base else { throw GraphQLFragmentResolverError.invalidTypeNameForFragment(syntax.description) }
            self = .typealiasOnStruct(base.description, expression.name.text)
        case let expression as OptionalChainingExprSyntax:
            try self.init(syntax: expression.expression)
        case let expression as ArrayExprSyntax:
            guard let syntax = Array(expression.elements).single()?.expression else { throw GraphQLFragmentResolverError.invalidTypeNameForFragment(expression.description) }
            try self.init(syntax: syntax)
        default:
            throw GraphQLFragmentResolverError.invalidTypeNameForFragment(syntax.description)
        }
    }
    
}
