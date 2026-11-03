import Foundation
import Combine

class BlockEngine: ObservableObject {
    static let shared = BlockEngine()
    @Published var activeDomains: Set<String> = []
    
    @Published var isHyperfocusActive: Bool = false
    @Published var activeGroupIDs: Set<UUID> = []
    @Published var temporaryBlocks: [UUID: Date] = [:]
    
    // Nova variável segura para exibir o tempo na barra de menus
    @Published var shortestTimerString: String = ""
    
    private var timer: Timer?
    private var displayTimer: Timer? // Timer exclusivo para a UI (1 segundo)
    
    func start(store: Store) {
        evaluate(store: store)
        
        // Motor principal de regras (10 em 10 segundos)
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.evaluate(store: store)
        }
        
        // Motor visual do cronômetro da barra de menus (1 em 1 segundo)
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimerDisplay()
        }
    }
    
    // Calcula o texto do cronômetro de forma segura para não crashar o MenuBar
    private func updateTimerDisplay() {
        guard !isHyperfocusActive, !temporaryBlocks.isEmpty else {
            if shortestTimerString != "" {
                DispatchQueue.main.async { self.shortestTimerString = "" }
            }
            return
        }
        
        if let earliest = temporaryBlocks.values.min() {
            let remaining = earliest.timeIntervalSince(Date())
            if remaining > 0 {
                let mins = Int(remaining) / 60
                let secs = Int(remaining) % 60
                let timeStr = String(format: "%02d:%02d", mins, secs)
                DispatchQueue.main.async {
                    self.shortestTimerString = timeStr
                }
            } else {
                DispatchQueue.main.async { self.shortestTimerString = "" }
            }
        }
    }
    
    func evaluate(store: Store) {
        var domainsToBlock = Set<String>()
        var currentActiveGroups = Set<UUID>()
        let now = Date()
        
        if isHyperfocusActive {
            temporaryBlocks.removeAll()
            for group in store.groups { currentActiveGroups.insert(group.id) }
        } else {
            for (groupId, expirationDate) in temporaryBlocks {
                if now >= expirationDate {
                    temporaryBlocks.removeValue(forKey: groupId)
                } else {
                    currentActiveGroups.insert(groupId)
                }
            }
            
            let calendar = Calendar.current
            let currentDay = calendar.component(.weekday, from: now)
            let currentMins = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
            
            for schedule in store.schedules where schedule.isEnabled {
                if schedule.selectedDays.contains(currentDay) {
                    let startMins = schedule.startHour * 60 + schedule.startMinute
                    let endMins = schedule.endHour * 60 + schedule.endMinute
                    
                    let isActive = (startMins <= endMins)
                        ? (currentMins >= startMins && currentMins < endMins)
                        : (currentMins >= startMins || currentMins < endMins)
                    
                    if isActive { currentActiveGroups.insert(schedule.groupId) }
                }
            }
        }
        
        for groupId in currentActiveGroups {
            if let group = store.groups.first(where: { $0.id == groupId }) {
                domainsToBlock.formUnion(group.domains)
            }
        }
        
        DispatchQueue.main.async {
            self.activeGroupIDs = currentActiveGroups
        }
        
        if domainsToBlock != activeDomains {
            activeDomains = domainsToBlock
            HostManager.applyBlocklist(activeDomains)
            if activeDomains.isEmpty {
                BrowserMonitor.shared.stopMonitoring()
            } else {
                BrowserMonitor.shared.startMonitoring(activeDomains: activeDomains)
            }
        }
    }
}
