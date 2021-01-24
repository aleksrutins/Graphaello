import Foundation

protocol GraphQLStage: StageProtocol {
    associatedtype Path
    static var pathKey: Context.Key<Path?> { get }
}

extension Property where CurrentStage: GraphQLStage {

    var graphqlPath: CurrentStage.Path? {
        return context[CurrentStage.pathKey]
    }

}

extension Property where CurrentStage: GraphQLStage {
    
    init(code: SourceCode, name: String, type: PropertyType, usr: String, graphqlPath: CurrentStage.Path?) {
        self.init(code: code, name: name, type: type, usr: usr) { CurrentStage.pathKey ~> graphqlPath }
    }
    
}
