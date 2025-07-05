import Foundation
import CoreData

extension FillerAnalysis {
    convenience init(context: NSManagedObjectContext, audioSession: AudioSession) {
        let entity = NSEntityDescription.entity(forEntityName: "FillerAnalysis", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.analysisDate = Date()
        self.audioSession = audioSession
        self.fillerCount = 0
        self.fillerRate = 0.0
        self.speakingSpeed = 0.0
    }
    
    func calculateImprovement(from previousAnalysis: FillerAnalysis?) -> Double {
        guard let previous = previousAnalysis else { return 0.0 }
        
        let previousRate = previous.fillerRate
        let currentRate = self.fillerRate
        
        if previousRate == 0 { return currentRate == 0 ? 0 : -100 }
        
        return ((previousRate - currentRate) / previousRate) * 100
    }
    
    // analysisDateを常に非nilとして扱うための計算プロパティ
    var safeAnalysisDate: Date {
        return analysisDate ?? Date()
    }
}