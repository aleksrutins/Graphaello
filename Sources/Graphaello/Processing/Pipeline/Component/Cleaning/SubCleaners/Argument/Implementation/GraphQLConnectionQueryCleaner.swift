import Foundation

struct GraphQLConnectionQueryCleaner: ArgumentCleaner {
    let queryCleaner: AnyArgumentCleaner<GraphQLQuery>

    func clean(resolved: GraphQLConnectionQuery,
               using context: Cleaning.Argument.Context) throws -> Cleaning.Argument.Result<GraphQLConnectionQuery> {

        return try queryCleaner
            .clean(resolved: resolved.query, using: context)
            .map { query in
                GraphQLConnectionQuery(query: query,
                                       fragment: resolved.fragment,
                                       propertyName: resolved.propertyName)
            }
    }
}
