import Foundation
import SourceKittenFramework

extension Pipeline {
    
    func extract(from project: Project) throws -> Project.State<Stage.Extracted> {
        let apis = try project.scanAPIs().sorted { $0.name <= $1.name }
        let swiftFiles = try project.files()
            .filter { $0.value.extension == "swift" }
            .filter { $0.value.lastComponentWithoutExtension != "Graphaello" }
            .sorted { $0.value.lastComponentWithoutExtension <= $1.value.lastComponentWithoutExtension }
            .compactMap { pathWithTargets in
                pathWithTargets.compactMap { File(path: $0.string) }
            }
    
        let extracted = try extract(from: swiftFiles)
        return Project.State(apis: apis, structs: extracted, cache: nil)
    }
    
    func parse(extracted: Project.State<Stage.Extracted>) throws -> Project.State<Stage.Parsed> {
        return extracted.with(structs: try parse(extracted: extracted.structs).filter { $0.hasGraphQLValues })
    }
    
    func validate(parsed: Project.State<Stage.Parsed>) throws -> Project.State<Stage.Validated> {
        return parsed.with(structs: try validate(parsed: parsed.structs, using: parsed.apis))
    }
    
    func resolve(validated: Project.State<Stage.Validated>) throws -> Project.State<Stage.Resolved> {
        return validated.with(structs: try resolve(validated: validated.structs))
    }

    func clean(resolved: Project.State<Stage.Resolved>) throws -> Project.State<Stage.Cleaned> {
        return resolved.with(structs: try clean(resolved: resolved.structs))
    }

    func diagnose(parsed: Project.State<Stage.Parsed>) throws -> [Warning] {
        return try parsed.structs.flatMap { try diagnose(parsed: $0) }
    }
    
}
