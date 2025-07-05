import Foundation
import CoreData

extension FillerWord {
    convenience init(context: NSManagedObjectContext, word: String, analysis: FillerAnalysis) {
        let entity = NSEntityDescription.entity(forEntityName: "FillerWord", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.word = word
        self.count = 0
        self.confidence = 0.0
        self.timestamp = 0.0
        self.analysis = analysis
    }
}