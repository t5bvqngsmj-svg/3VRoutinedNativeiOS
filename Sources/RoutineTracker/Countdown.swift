import Foundation

enum CountdownReminder: String, Codable, CaseIterable, Identifiable {
    case dayOf
    case dayBefore
    case weekBefore

    var id: String { rawValue }

    var translationKey: String {
        switch self {
        case .dayOf: return "day_of"
        case .dayBefore: return "day_before"
        case .weekBefore: return "week_before"
        }
    }
}

struct CountdownItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var targetDate: Date
    var includesTime: Bool
    var imageData: Data?
    var reminders: [CountdownReminder]
    var createdAt: Date
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        name: String,
        targetDate: Date,
        includesTime: Bool,
        imageData: Data? = nil,
        reminders: [CountdownReminder] = [.dayOf],
        createdAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.name = name
        self.targetDate = targetDate
        self.includesTime = includesTime
        self.imageData = imageData
        self.reminders = reminders
        self.createdAt = createdAt
        self.isPinned = isPinned
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        targetDate = (try? c.decode(Date.self, forKey: .targetDate)) ?? Date()
        includesTime = (try? c.decode(Bool.self, forKey: .includesTime)) ?? false
        imageData = try? c.decodeIfPresent(Data.self, forKey: .imageData)
        reminders = (try? c.decode([CountdownReminder].self, forKey: .reminders)) ?? [.dayOf]
        createdAt = (try? c.decode(Date.self, forKey: .createdAt)) ?? Date()
        isPinned = (try? c.decode(Bool.self, forKey: .isPinned)) ?? false
    }

    var remainingInterval: TimeInterval {
        targetDate.timeIntervalSinceNow
    }

    var hasEnded: Bool {
        remainingInterval <= 0
    }
}
