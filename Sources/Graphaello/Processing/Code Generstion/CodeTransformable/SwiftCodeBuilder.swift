import Foundation
import Stencil

@_functionBuilder
struct CodeBuilder {
    
    static func buildBlock(_ transformable: CodeTransformable) -> CodeTransformable {
        return transformable
    }
    
    static func buildBlock(_ transformables: CodeTransformable...) -> CodeTransformable {
        return transformables.map { AnyCodeTransformable(transformable: $0) }
    }
    
}
