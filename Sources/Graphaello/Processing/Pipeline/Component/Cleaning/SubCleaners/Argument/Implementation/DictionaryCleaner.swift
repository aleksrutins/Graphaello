import Foundation

struct DictionaryCleaner<Key: Hashable, Value>: ArgumentCleaner {
    let keyCleaner: AnyArgumentCleaner<Key>
    let valueCleaner: AnyArgumentCleaner<Value>

    func clean(resolved: [Key : Value], using context: Cleaning.Argument.Context) throws -> Cleaning.Argument.Result<[Key : Value]> {
        return try resolved
            .reduce(context.result(value: [:])) { result, element in
                let value = try valueCleaner.clean(resolved: element.value, using: result)
                let key = try keyCleaner.clean(resolved: element.key, using: value)
                return key.map { result.value.merging([$0 : value.value]) { $1 } }
            }
    }
}
