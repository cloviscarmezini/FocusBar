import Foundation
import AppKit

class BrowserMonitor {
    static let shared = BrowserMonitor()
    private var timer: Timer?
    
    private var blockedPageURL: String {
        guard let path = Bundle.main.path(forResource: "blocked", ofType: "html") else { return "" }
        return "file://" + path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
    }
    
    func startMonitoring(activeDomains: Set<String>) {
        stopMonitoring()
        guard !activeDomains.isEmpty else { return }
        
        // Dispara a cada 1 segundo, mas executa em background
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.global(qos: .background).async {
                self?.checkAndRedirect(domains: activeDomains)
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkAndRedirect(domains: Set<String>) {
        // Adicionamos o Brave Browser na lista de verificação
        let browsers = ["Safari", "Google Chrome", "Brave Browser"]
        
        for browser in browsers {
            if let currentURL = runAppleScript(getURLScript(for: browser))?.lowercased() {
                
                if currentURL.contains("blocked.html") { continue }
                
                for domain in domains {
                    // Extrai a raiz da regra para agir como wildcard/domínio global
                    var cleanRule = domain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleanRule.hasPrefix("http://") { cleanRule.removeFirst(7) }
                    if cleanRule.hasPrefix("https://") { cleanRule.removeFirst(8) }
                    if cleanRule.hasPrefix("www.") { cleanRule.removeFirst(4) }
                    if let slashIndex = cleanRule.firstIndex(of: "/") {
                        cleanRule = String(cleanRule[..<slashIndex])
                    }
                    
                    // Se a URL do navegador contém a raiz da palavra ou domínio (ex: "google.com" ou "porn")
                    if !cleanRule.isEmpty && currentURL.contains(cleanRule) {
                        _ = runAppleScript(redirectScript(for: browser, to: blockedPageURL))
                        break
                    }
                }
            }
        }
    }
    
    private func getURLScript(for browser: String) -> String {
        if browser == "Safari" {
            return "tell application \"Safari\"\n if it is running then\n try\n return URL of front document\n end try\n end if\n end tell"
        } else {
            // Como Brave e Chrome usam a mesma estrutura (Chromium), injetamos o nome da variável
            return "tell application \"\(browser)\"\n if it is running then\n try\n return URL of active tab of front window\n end try\n end if\n end tell"
        }
    }
    
    private func redirectScript(for browser: String, to url: String) -> String {
        if browser == "Safari" {
            return "tell application \"Safari\"\n set URL of front document to \"\(url)\"\n end tell"
        } else {
            // Injeta dinamicamente para Chrome ou Brave
            return "tell application \"\(browser)\"\n set URL of active tab of front window to \"\(url)\"\n end tell"
        }
    }
    
    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        if let script = NSAppleScript(source: source) {
            let output = script.executeAndReturnError(&error)
            if error == nil {
                return output.stringValue
            }
        }
        return nil
    }
}
