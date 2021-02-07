import Foundation
import SwiftSyntax

extension SubParser {
    
    static func argumentList(parser: @escaping () -> SubParser<ExprSyntax, Argument>) -> SubParser<TupleExprElementListSyntax, [Field.Argument]> {
        return .init { arguments in
            let parser = parser()
            return try arguments.map { Field.Argument(name: $0.label?.text ?! fatalError(),
                                                      value: try parser.parse(from: $0.expression)) }
        }
    }
    
}
