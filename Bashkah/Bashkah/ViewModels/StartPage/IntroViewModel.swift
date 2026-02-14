import Foundation
import FirebaseFirestore

class IntroViewModel: ObservableObject {
    
    @Published var nameInput: String = ""
    @Published var goToStartPage: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func createPlayer() {
        
        let trimmedName = nameInput.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        isLoading = true
        
        let playerId = UUID().uuidString
        
        // ✅ Updated player structure
        let playerData: [String: Any] = [
            "name": trimmedName,
            "coins": 100,  // Starting coins
            "createdAt": FieldValue.serverTimestamp(),
            "totalGames": 0,
            "wins": 0,
            "isOnline": true
        ]
        
        db.collection("players")
            .document(playerId)
            .setData(playerData) { [weak self] error in
                
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        print("❌ Firestore error:", error.localizedDescription)
                    } else {
                        
                        // ✅ Save locally AFTER Firestore success
                        UserDefaults.standard.set(playerId, forKey: "playerId")
                        UserDefaults.standard.set(trimmedName, forKey: "playerName")
                        
                        print("✅ Player stored successfully")
                        print("   - Player ID: \(playerId)")
                        print("   - Name: \(trimmedName)")
                        print("   - Starting Coins: 100")
                        
                        self?.goToStartPage = true
                    }
                }
            }
    }
}
