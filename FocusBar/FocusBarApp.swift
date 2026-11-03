import SwiftUI
import ServiceManagement

@main
struct FocusBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = Store()
    @StateObject private var engine = BlockEngine.shared
    
    var body: some Scene {
        MenuBarExtra {
            
            if engine.isHyperfocusActive {
                Button("Desativar hiperfoco") {
                    engine.isHyperfocusActive = false
                    engine.evaluate(store: store)
                }
            } else {
                Button("Ativar hiperfoco") {
                    engine.isHyperfocusActive = true
                    engine.evaluate(store: store)
                }
            }
            
            if !engine.temporaryBlocks.isEmpty {
                Divider()
                ForEach(Array(engine.temporaryBlocks.keys), id: \.self) { groupId in
                    if let group = store.groups.first(where: { $0.id == groupId }) {
                        Button("Desativar foco (\(group.name))") {
                            engine.temporaryBlocks.removeValue(forKey: groupId)
                            engine.evaluate(store: store)
                        }
                    }
                }
            }
            
            Divider()
            
            SettingsLink {
                Text("Configurações...")
            }
            .keyboardShortcut(",", modifiers: .command)
            .simultaneousGesture(TapGesture().onEnded {
                NSApp.activate(ignoringOtherApps: true)
            })
            
            Button("Encerrar") {
                HostManager.applyBlocklist([])
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
            
        } label: {
            HStack(spacing: 4) {
                Image(systemName: engine.activeDomains.isEmpty ? "balloon" : "balloon.fill")
                
                if !engine.shortestTimerString.isEmpty {
                    ZStack(alignment: .leading) {
                        // O "fantasma" invisível que trava a largura física exata na barra de menus
                        Text("00:00")
                            .hidden()
                        
                        // O contador real que muda a cada segundo
                        Text(engine.shortestTimerString)
                    }
                    // A fonte design: .monospaced garante que todos os números e o ":" tenham a mesma exata largura
                    .font(.system(.body, design: .monospaced))
                }
            }
        }
        
        Settings {
            ContentView()
                .environmentObject(store)
                .frame(width: 800, height: 450)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        HostManager.applyBlocklist([])
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification, object: nil, queue: .main
        ) { _ in HostManager.applyBlocklist([]) }
    }
}
