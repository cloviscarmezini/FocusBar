import Foundation
import Network

class LocalServer {
    static let shared = LocalServer()
    private var listener: NWListener?
    
    func start() {
        do {
            let params = NWParameters.tcp
            // Restringe o servidor APENAS ao IP 127.0.0.2 para evitar conflito com a porta 80 global do Mac
            if let ip = IPv4Address("127.0.0.2") {
                params.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(ip), port: 80)
            }
            
            listener = try NWListener(using: params)
            
            listener?.newConnectionHandler = { connection in
                connection.start(queue: .global())
                self.receive(on: connection)
            }
            
            listener?.start(queue: .global())
            print("Servidor local rodando isolado em 127.0.0.2:80...")
        } catch {
            print("Erro ao subir servidor local: \(error)")
        }
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let _ = data {
                // Monta um HTML super simples
                let html = """
                <html>
                <head>
                    <title>Not Now</title>
                    <style>
                        body { font-family: -apple-system, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f5f5f7; color: #1d1d1f; }
                        .card { background: white; padding: 40px; border-radius: 20px; box-shadow: 0 4px 20px rgba(0,0,0,0.05); text-align: center; }
                        h1 { font-size: 24px; margin-bottom: 10px; }
                        p { color: #86868b; }
                    </style>
                </head>
                <body>
                    <div class="card">
                        <h1>Este site está pausado</h1>
                        <p>Foco! Um de seus agendamentos está ativo no momento.</p>
                    </div>
                </body>
                </html>
                """
                
                // Constrói o response HTTP padrão 200 OK
                let response = "HTTP/1.1 200 OK\r\nContent-Length: \(html.utf8.count)\r\nContent-Type: text/html; charset=utf-8\r\n\r\n\(html)"
                
                let responseData = Data(response.utf8)
                connection.send(content: responseData, completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            } else if isComplete || error != nil {
                connection.cancel()
            }
        }
    }
}
