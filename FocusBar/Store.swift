import Foundation
import Combine
import AppKit

class Store: ObservableObject {
    @Published var groups: [BlockGroup] = []
    @Published var schedules: [Schedule] = []
    
    // Diretório base para salvar o arquivo de configuração do app
    private var saveURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0].appendingPathComponent("FocusBar") // Nome da pasta
        
        // Cria a pasta se ela não existir
        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }
        
        return appSupport.appendingPathComponent("data.json")
    }
    
    init() {
        loadData()
        
        if groups.isEmpty {
            let defaultGroup = BlockGroup(name: "Distrações", domains: ["youtube.com", "www.youtube.com", "youtu.be"])
            groups.append(defaultGroup)
            saveData()
        }
        
        // Failsafe: Limpa resíduos de sessões anteriores
        HostManager.applyBlocklist([])
        
        // Inicia o motor
        BlockEngine.shared.start(store: self)
        
        // 1. CONFERÊNCIA DE INICIALIZAÇÃO:
        // Aguarda o app terminar de carregar totalmente para aplicar bloqueios pendentes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            BlockEngine.shared.evaluate(store: self)
        }
        
        // 2. CONFERÊNCIA DE WAKE (Quando o Mac acorda do modo repouso)
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            BlockEngine.shared.evaluate(store: self) // Agora usa o Store verdadeiro, não um vazio
        }
    }
    
    func saveData() {
        let dataToSave = AppData(groups: groups, schedules: schedules)
        do {
            let encoded = try JSONEncoder().encode(dataToSave)
            try encoded.write(to: saveURL)
        } catch {
            print("Erro ao salvar dados: \(error)")
        }
        
        BlockEngine.shared.evaluate(store: self)
    }
    
    func loadData() {
        do {
            let data = try Data(contentsOf: saveURL)
            let decoded = try JSONDecoder().decode(AppData.self, from: data)
            self.groups = decoded.groups
            self.schedules = decoded.schedules
        } catch {
            print("Nenhum dado salvo encontrado ou erro ao ler: \(error)")
        }
    }
    
    // Estrutura interna apenas para encapsular o salvamento no JSON
    private struct AppData: Codable {
        let groups: [BlockGroup]
        let schedules: [Schedule]
    }
}
