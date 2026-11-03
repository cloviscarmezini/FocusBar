import SwiftUI
import ServiceManagement

struct ContentView: View {
    @EnvironmentObject var store: Store
    // Estado para forçar a atualização visual da aba selecionada
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            GroupsSettingsView()
                .tabItem {
                    Label("Bloqueios", systemImage: "shield")
                }
                .tag(0) // Garante que a aba fique destacada
            
            GeneralSettingsView()
                .tabItem {
                    Label("Geral", systemImage: "gearshape")
                }
                .tag(1) // Garante que a aba fique destacada
        }
        .frame(width: 800, height: 450)
    }
}

struct GroupsSettingsView: View {
    @EnvironmentObject var store: Store
    @ObservedObject var engine = BlockEngine.shared
    
    @State private var selectedGroupId: UUID?
    
    // Controles do Alerta Dinâmico
    @State private var groupToDelete: BlockGroup?
    @State private var showDeleteAlert = false
    @State private var isActiveBlockAlert = false
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $selectedGroupId) {
                    ForEach(store.groups) { group in
                        HStack {
                            Text(group.name)
                            Spacer()
                            
                            // 1. Prioridade: Se tem timer rodando, mostra o relógio verde
                            if let expiration = engine.temporaryBlocks[group.id] {
                                Text(expiration, style: .timer)
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.green)
                            
                            // 2. Se está bloqueado por agenda ou Hiperfoco, mostra a bolinha verde
                            } else if engine.activeGroupIDs.contains(group.id) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .tag(group.id)
                        .contextMenu {
                            Button(role: .destructive) {
                                triggerDelete(for: group)
                            } label: {
                                Label("Apagar Grupo", systemImage: "trash")
                            }
                        }
                    }
                }
                .alert(isPresented: $showDeleteAlert) {
                    Alert(
                        title: Text(isActiveBlockAlert ? "Atenção: Bloqueio Ativo!" : "Apagar Grupo"),
                        message: Text(isActiveBlockAlert
                            ? "O grupo '\(groupToDelete?.name ?? "")' está com um bloqueio em andamento. Apagá-lo irá interromper o foco imediatamente. Deseja continuar?"
                            : "Tem certeza que deseja apagar o grupo '\(groupToDelete?.name ?? "")'? Os sites e agendamentos serão perdidos."),
                        primaryButton: .destructive(Text("Apagar")) {
                            if let group = groupToDelete { confirmDelete(group: group) }
                        },
                        secondaryButton: .cancel(Text("Cancelar"))
                    )
                }
                
                Divider()
                
                // Rodapé com os botões de + e - com área de clique expandida
                HStack(spacing: 8) {
                    Button(action: addGroup) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        if let id = selectedGroupId, let group = store.groups.first(where: { $0.id == id }) {
                            triggerDelete(for: group)
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedGroupId == nil)
                    
                    Spacer()
                }
                .padding(8)
                .background(Color(NSColor.windowBackgroundColor))
            }
            .toolbar(removing: .sidebarToggle)
            
        } detail: {
            if let selectedGroupId,
               let groupIndex = store.groups.firstIndex(where: { $0.id == selectedGroupId }) {
                GroupDetailView(group: $store.groups[groupIndex])
                    .id(selectedGroupId) // <-- Modificador que corrige o crash
            } else {
                Text("Selecione um grupo na barra lateral para editar.")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func addGroup() {
        let newGroup = BlockGroup(name: "Novo Grupo", domains: [])
        store.groups.append(newGroup)
        store.saveData()
        selectedGroupId = newGroup.id
    }
    
    private func triggerDelete(for group: BlockGroup) {
        groupToDelete = group
        // Verifica dinamicamente se o grupo está com foco ativo no motor
        isActiveBlockAlert = engine.activeGroupIDs.contains(group.id)
        showDeleteAlert = true
    }
    
    private func confirmDelete(group: BlockGroup) {
        store.groups.removeAll { $0.id == group.id }
        store.schedules.removeAll { $0.groupId == group.id }
        engine.temporaryBlocks.removeValue(forKey: group.id)
        store.saveData()
        
        if selectedGroupId == group.id { selectedGroupId = nil }
        
        // Força o motor a recalcular os bloqueios imediatamente
        engine.evaluate(store: store)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var store: Store
    @ObservedObject var engine = BlockEngine.shared
    @State private var isEnabled = SMAppService.mainApp.status == .enabled
    
    // Controle do alerta de confirmação
    @State private var showDisableAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Form {
                Section {
                    Toggle("Iniciar FocusBar ao ligar o Mac", isOn: $isEnabled)
                        .onChange(of: isEnabled) { _, newValue in
                            do {
                                if newValue { try SMAppService.mainApp.register() }
                                else { try SMAppService.mainApp.unregister() }
                            } catch {
                                print("Erro ao alterar inicialização: \(error)")
                            }
                        }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        showDisableAlert = true
                    }) {
                        Text("Desativar todos os focos")
                    }
                    .padding(.top, 10)
                    
                    Text("Isso desligará todas as agendas (Off) e cancelará qualquer foco de 30 minutos em andamento.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            Spacer()
        }
        .padding(20)
        // Alerta de confirmação
        .alert(isPresented: $showDisableAlert) {
            Alert(
                title: Text("Desativar todos os focos?"),
                message: Text("Tem certeza? Isso irá desligar as chaves de todas as suas agendas e cancelar bloqueios temporários."),
                primaryButton: .destructive(Text("Desativar")) {
                    disableAllFocuses()
                },
                secondaryButton: .cancel(Text("Cancelar"))
            )
        }
    }
    
    private func disableAllFocuses() {
        for i in store.schedules.indices {
            store.schedules[i].isEnabled = false
        }
        store.saveData() // O BlockEngine já será chamado automaticamente por causa do ajuste 1!
        
        engine.temporaryBlocks.removeAll()
        engine.isHyperfocusActive = false
        engine.evaluate(store: store)
    }
}
