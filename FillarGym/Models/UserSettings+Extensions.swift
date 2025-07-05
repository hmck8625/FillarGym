import Foundation
import CoreData

extension UserSettings {
    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "UserSettings", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.updatedAt = Date()
        self.language = "ja"
        self.monthlyGoal = 10
        self.detectionSensitivity = 1
        self.isPremium = false
        self.notificationEnabled = true
    }
    
    var customFillerWordsArray: [String] {
        get {
            return customFillerWords?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        }
        set {
            customFillerWords = newValue.joined(separator: ", ")
        }
    }
    
    var disabledDefaultWordsArray: [String] {
        get {
            // customFillerWordsから直接取得（customFillerWordsArrayを使わない）
            guard let words = customFillerWords else { return [] }
            let allWords = words.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            return allWords.filter { $0.hasPrefix("DISABLED:") }
                          .map { String($0.dropFirst(9)) } // "DISABLED:"を削除
        }
        set {
            // customFillerWordsから直接操作（customFillerWordsArrayを使わない）
            guard let existingWords = customFillerWords else {
                let disabledWithPrefix = newValue.map { "DISABLED:\($0)" }
                customFillerWords = disabledWithPrefix.joined(separator: ", ")
                return
            }
            
            let allWords = existingWords.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let customOnly = allWords.filter { !$0.hasPrefix("DISABLED:") }
            let disabledWithPrefix = newValue.map { "DISABLED:\($0)" }
            customFillerWords = (customOnly + disabledWithPrefix).joined(separator: ", ")
        }
    }
    
    var activeCustomFillerWordsArray: [String] {
        get {
            // customFillerWordsから直接取得（customFillerWordsArrayを使わない）
            guard let words = customFillerWords else { return [] }
            return words.components(separatedBy: ",")
                       .map { $0.trimmingCharacters(in: .whitespaces) }
                       .filter { !$0.hasPrefix("DISABLED:") }
        }
    }
    
    static func defaultFillerWords(for language: String) -> [String] {
        switch language {
        case "ja":
            return ["えー", "あー", "その", "あの", "えっと", "まあ", "なんか", "ちょっと", "やっぱり"]
        case "en":
            return ["um", "uh", "like", "you know", "actually", "basically", "literally"]
        default:
            return ["えー", "あー", "その", "あの", "えっと", "まあ", "なんか", "ちょっと", "やっぱり"]
        }
    }
}