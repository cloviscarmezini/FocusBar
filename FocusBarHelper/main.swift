import Foundation

// 1. A classe que atende o telefone quando o App liga
class HelperDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: FocusBarXPCProtocol.self)
        newConnection.exportedObject = HelperObject()
        newConnection.resume()
        return true
    }
}

// 2. A classe que faz o trabalho sujo como Root (Antigo HostManager)
class HelperObject: NSObject, FocusBarXPCProtocol {
    func applyBlocklist(domains: [String], withReply reply: @escaping (Bool) -> Void) {
        let hostsPath = "/private/etc/hosts"
        let markerStart = "# >>> FocusBar Blocklist >>>"
        let markerEnd   = "# <<< FocusBar Blocklist <<<"
        
        do {
            let originalContent = try String(contentsOfFile: hostsPath, encoding: .utf8)
            let lines = originalContent.components(separatedBy: .newlines)
            var cleanLines: [String] = []
            var isInsideBlock = false
            
            for line in lines {
                if line == markerStart { isInsideBlock = true; continue }
                if line == markerEnd { isInsideBlock = false; continue }
                if !isInsideBlock { cleanLines.append(line) }
            }
            
            while cleanLines.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
                cleanLines.removeLast()
            }
            
            if !domains.isEmpty {
                cleanLines.append("\n" + markerStart)
                for domain in domains.sorted() {
                    if domain.hasSuffix("apple.com") || domain.hasSuffix("icloud.com") { continue }
                    cleanLines.append("0.0.0.0\t\(domain)")
                    cleanLines.append("::\t\(domain)")
                }
                cleanLines.append(markerEnd)
            }
            
            let newContent = cleanLines.joined(separator: "\n") + "\n"
            try newContent.write(toFile: hostsPath, atomically: false, encoding: .utf8)
            
            // Limpa o cache DNS
            let task = Process()
            task.launchPath = "/usr/bin/dscacheutil"
            task.arguments = ["-flushcache"]
            task.launch()
            
            reply(true) // Avisa o App que deu tudo certo
        } catch {
            reply(false) // Falhou
        }
    }
}

// 3. Inicia o servidor invisível do Daemon
let delegate = HelperDelegate()
let listener = NSXPCListener(machServiceName: "com.focusbar.helper")
listener.delegate = delegate
listener.resume()

RunLoop.main.run() // Mantém o processo vivo esperando conexões
