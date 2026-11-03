import Foundation
import ServiceManagement

struct HostManager {
    static func applyBlocklist(_ domains: Set<String>) {
        // 1. Registra o Daemon no macOS (Vai pedir sua senha na primeira vez!)
        let daemon = SMAppService.daemon(plistName: "com.focusbar.helper.plist")
        if daemon.status != .enabled {
            do {
                try daemon.register()
                print("Daemon XPC instalado com sucesso!")
            } catch {
                print("Falha ao registrar o Daemon: \(error)")
                return
            }
        }
        
        // 2. Cria o cabo de comunicação com o Daemon, usando privilégios de Root
        let connection = NSXPCConnection(machServiceName: "com.focusbar.helper", options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: FocusBarXPCProtocol.self)
        connection.resume()
        
        // 3. Pede para o Daemon executar o bloqueio
        guard let helper = connection.remoteObjectProxyWithErrorHandler({ error in
            print("Erro de conexão XPC: \(error)")
        }) as? FocusBarXPCProtocol else { return }
        
        let domainArray = Array(domains)
        helper.applyBlocklist(domains: domainArray) { success in
            if success {
                print("O Daemon atualizou o /etc/hosts como Root!")
            }
            connection.invalidate()
        }
    }
}
