import Foundation

struct EpisodePreview: Hashable, Identifiable {
    let id: Int
    let title: String?
    let typeAndNumber: String
    let uploadDate: Date

    static func == (lhs: EpisodePreview, rhs: EpisodePreview) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum EpisodePreviewSampleData {
    static let data = [
        EpisodePreview(
            id: 291395,
            title: "The Journey`s End",
            typeAndNumber: "1 серия",
            uploadDate: Date()
        ),
        EpisodePreview(
            id: 312552,
            title: nil,
            typeAndNumber: "2 серия",
            uploadDate: Date()
        ),
        EpisodePreview(
            id: 312553,
            title: nil,
            typeAndNumber: "3 серия",
            uploadDate: Calendar.current.date(byAdding: .second, value: -5, to: Date())!
        ),
        EpisodePreview(
            id: 312554,
            title: nil,
            typeAndNumber: "4 серия",
            uploadDate: Calendar.current.date(byAdding: .minute, value: -5, to: Date())!
        ),
        EpisodePreview(
            id: 312555,
            title: nil,
            typeAndNumber: "5 серия",
            uploadDate: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!
        ),
        EpisodePreview(
            id: 313150,
            title: nil,
            typeAndNumber: "6 серия",
            uploadDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        ),
        EpisodePreview(
            id: 313628,
            title: nil,
            typeAndNumber: "7 серия",
            uploadDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        ),
        EpisodePreview(
            id: 314104,
            title: nil,
            typeAndNumber: "8 серия",
            uploadDate: Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        )
    ]
}
