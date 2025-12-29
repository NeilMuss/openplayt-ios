import Foundation

enum ArchiveSource: String, CaseIterable, Hashable, Identifiable {
    case bundledTestArchive
    case localArchive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bundledTestArchive:
            return "Bundled (Test)"
        case .localArchive:
            return "Local (On Device)"
        }
    }
}
