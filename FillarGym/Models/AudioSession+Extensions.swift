import Foundation
import CoreData

extension AudioSession {
    convenience init(context: NSManagedObjectContext, title: String? = nil, duration: Double = 0.0) {
        let entity = NSEntityDescription.entity(forEntityName: "AudioSession", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.createdAt = Date()
        self.title = title
        self.duration = duration
    }
}