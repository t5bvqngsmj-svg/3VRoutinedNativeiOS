import Foundation

struct Routine: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var tasks: [TaskItem]
    var targetTime: TimeInterval = 0
    var imageData: Data? = nil
    var isScheduled: Bool = false
    var scheduledTime: Date? = nil

    init(id: UUID = UUID(), name: String, tasks: [TaskItem], targetTime: TimeInterval = 0, imageData: Data? = nil, isScheduled: Bool = false, scheduledTime: Date? = nil) {
        self.id = id
        self.name = name
        self.tasks = tasks
        self.targetTime = targetTime
        self.imageData = imageData
        self.isScheduled = isScheduled
        self.scheduledTime = scheduledTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        tasks = (try? c.decode([TaskItem].self, forKey: .tasks)) ?? []
        targetTime = (try? c.decode(TimeInterval.self, forKey: .targetTime)) ?? 0
        imageData = try? c.decodeIfPresent(Data.self, forKey: .imageData)
        isScheduled = (try? c.decode(Bool.self, forKey: .isScheduled)) ?? false
        scheduledTime = try? c.decodeIfPresent(Date.self, forKey: .scheduledTime)
    }

    var totalTargetTime: TimeInterval {
        tasks.reduce(0) { $0 + $1.targetTime }
    }

    var targetSummary: String {
        if isScheduled {
            guard let scheduledTime else { return "Scheduled" }
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Scheduled \(formatter.string(from: scheduledTime))"
        }

        let minutes = Int(totalTargetTime) / 60
        let seconds = Int(totalTargetTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var targetTime: TimeInterval = 0
    var scheduledTime: Date? = nil

    init(id: UUID = UUID(), name: String, targetTime: TimeInterval = 0, scheduledTime: Date? = nil) {
        self.id = id
        self.name = name
        self.targetTime = targetTime
        self.scheduledTime = scheduledTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        targetTime = (try? c.decode(TimeInterval.self, forKey: .targetTime)) ?? 0
        scheduledTime = try? c.decodeIfPresent(Date.self, forKey: .scheduledTime)
    }

    var formattedTargetTime: String {
        let minutes = Int(targetTime) / 60
        let seconds = Int(targetTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
