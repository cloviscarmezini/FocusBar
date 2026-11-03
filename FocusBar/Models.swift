import Foundation

// Representa um grupo de sites bloqueados (ex: "Redes Sociais")
struct BlockGroup: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var domains: [String] // Lista de domínios (ex: "youtube.com")
}

// Representa uma regra de horário associada a um grupo
struct Schedule: Identifiable, Codable, Hashable {
    var id = UUID()
    var groupId: UUID
    var isEnabled: Bool = true // Toggle para ligar/desligar a qualquer momento
    
    var startHour: Int = 8
    var startMinute: Int = 0
    var endHour: Int = 12
    var endMinute: Int = 0
    
    var selectedDays: Set<Int> = [2, 3, 4, 5, 6] // 1 = Dom, 2 = Seg... (Padrão: dias úteis)
    
    // Propriedades computadas para a Interface do SwiftUI
    var startTime: Date {
        get { Calendar.current.date(from: DateComponents(hour: startHour, minute: startMinute)) ?? Date() }
        set {
            startHour = Calendar.current.component(.hour, from: newValue)
            startMinute = Calendar.current.component(.minute, from: newValue)
        }
    }
    
    var endTime: Date {
        get { Calendar.current.date(from: DateComponents(hour: endHour, minute: endMinute)) ?? Date() }
        set {
            endHour = Calendar.current.component(.hour, from: newValue)
            endMinute = Calendar.current.component(.minute, from: newValue)
        }
    }
}
