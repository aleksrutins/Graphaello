import Foundation
import SwiftSyntax

extension StructResolution.ReferencedMutationResultFragment {
    
    init(typeName: String) throws {
        try self.init(syntax: try SyntaxParser.parse(source: typeName).singleItem() ?! GraphQLFragmentResolverError.invalidTypeNameForFragment(typeName))
    }

    fileprivate init(syntax: Syntax) throws {
        try self.init(expression: try syntax.as(SpecializeExprSyntax.self) ?! GraphQLFragmentResolverError.invalidTypeNameForFragment(syntax.description))
    }
    
    fileprivate init(expression: SpecializeExprSyntax) throws {
        let argument = try Array(expression.genericArgumentClause.arguments).single() ?! GraphQLFragmentResolverError.invalidTypeNameForFragment(expression.description)
        self.init(mutationName: expression.expression.description,
                  fragmentName: try StructResolution.FragmentName(syntax: argument.argumentType.erased()))
    }
    
}
