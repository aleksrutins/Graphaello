import Foundation
import SourceKittenFramework

struct BasicExtractor: Extractor {
    let extractor: StructExtractor

    func extract(from file: WithTargets<File>) throws -> [Struct<Stage.Extracted>] {
        guard let path = file.value.path else { fatalError("File provided to extractor is not an actual file") }
        let location = Location(file: URL(fileURLWithPath: path), line: nil, column: nil)
        let code = try SourceCode(file: file, index: LineColumnIndex(string: file.value.contents), location: location)
        let structs = try code.structs()
        return try structs.map { try extractor.extract(code: $0) }
    }
}

extension SourceCode {

    fileprivate func structs() throws -> [SourceCode] {
        let kind = try optional { try $0.kind() }
        let substructure = try optional { try $0.substructure() } ?? []
        if kind == .struct {
            return try substructure.flatMap { try $0.structs() } + [self]
        } else {
            return try substructure.flatMap { try $0.structs() }
        }
    }

}
