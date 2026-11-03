import Foundation

struct DomainParser {
    static func parse(fileURL: URL) -> [String] {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return []
        }
        return parse(text: content)
    }
    
    static func parse(text: String) -> [String] {
        var result = Set<String>()
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            if let domain = extractDomain(from: trimmed) {
                // Item 2: Adiciona estritamente a URL fornecida, sem "www" automático
                result.insert(domain)
                
                // Mantivemos apenas a regra do YouTube curto, pois é um fallback essencial
                if domain == "youtube.com" { result.insert("youtu.be") }
            }
        }
        
        return Array(result).sorted()
    }
    
    private static func extractDomain(from urlString: String) -> String? {
        var text = urlString.lowercased()
        if text.hasPrefix("http://") { text.removeFirst(7) }
        if text.hasPrefix("https://") { text.removeFirst(8) }
        if let slashIndex = text.firstIndex(of: "/") {
            text = String(text[..<slashIndex])
        }
        return text.isEmpty ? nil : text
    }
}
