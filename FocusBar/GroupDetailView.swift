import SwiftUI
import UniformTypeIdentifiers

struct GroupDetailView: View {
    @Binding var group: BlockGroup
    @EnvironmentObject var store: Store
    @ObservedObject var engine = BlockEngine.shared
    @State private var newDomain: String = ""
    @State private var selectedTab = 0 // 0 = Sites, 1 = Agendamentos
    @State private var showCancelAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Cabeçalho
            HStack {
                TextField("Nome do Grupo", text: $group.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .onChange(of: group.name) { _, _ in store.saveData() }
                
                Spacer()
                
                // Botão "Cancelar foco" se estiver ativo
                if engine.temporaryBlocks[group.id] != nil {
                    Button(action: {
                        showCancelAlert = true
                    }) {
                        Label("Cancelar foco", systemImage: "xmark.circle")
                    }
                    .tint(.red)
                    .buttonStyle(.borderedProminent)
                    .alert(isPresented: $showCancelAlert) {
                        Alert(
                            title: Text("Cancelar Foco?"),
                            message: Text("Tem certeza que deseja interromper este foco antes dos 30 minutos?"),
                            primaryButton: .destructive(Text("Cancelar Foco")) {
                                engine.temporaryBlocks.removeValue(forKey: group.id)
                                engine.evaluate(store: store)
                            },
                            secondaryButton: .cancel(Text("Voltar"))
                        )
                    }
                } else {
                    // Botão Padrão
                    Button(action: {
                        engine.temporaryBlocks[group.id] = Date().addingTimeInterval(30 * 60)
                        engine.evaluate(store: store)
                    }) {
                        Label("Ativar por 30 min", systemImage: "timer")
                    }
                    .disabled(engine.isHyperfocusActive)
                }
            }
            .padding()
            
            Picker("", selection: $selectedTab) {
                Text("Sites").tag(0)
                Text("Agendamentos").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            if selectedTab == 0 {
                sitesTab
            } else {
                schedulesTab
            }
        }
    }
    
    // MARK: - Aba SITES
    var sitesTab: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Adicionar domínio...", text: $newDomain)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addManualDomain() }
                Button("Adicionar") { addManualDomain() }
                Button(action: importTxtFile) {
                    Label("Importar .txt", systemImage: "square.and.arrow.down")
                }
            }
            .padding(.horizontal).padding(.bottom)
            
            List {
                ForEach(group.domains, id: \.self) { domain in
                    HStack {
                        Text(domain)
                        Spacer()
                        Button(action: { removeDomain(domain) }) {
                            Image(systemName: "trash").foregroundColor(.red)
                        }.buttonStyle(.plain)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
    
    // MARK: - Aba AGENDAMENTOS
    var schedulesTab: some View {
        let groupSchedules = store.schedules.indices.filter { store.schedules[$0].groupId == group.id }
        
        return ZStack {
            // Garante que o fundo cinza ocupe 100% da tela, independente do conteúdo
            Color(NSColor.controlBackgroundColor)
            
            if groupSchedules.isEmpty {
                // Item 3: Layout centralizado e expandido quando vazio
                VStack {
                    Spacer()
                    Button(action: addSchedule) {
                        Label("Novo Agendamento", systemImage: "plus")
                    }
                    // Dá um destaque visual maior ao botão central
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                // Lista de agendamentos normal
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(groupSchedules, id: \.self) { index in
                            ScheduleRowView(schedule: $store.schedules[index])
                        }
                        
                        Button(action: addSchedule) {
                            Label("Novo Agendamento", systemImage: "plus")
                        }
                        .padding(.top)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Funções de Ação
    private func addManualDomain() {
        let parsed = DomainParser.parse(text: newDomain)
        for d in parsed { if !group.domains.contains(d) { group.domains.append(d) } }
        group.domains.sort()
        store.saveData()
        newDomain = ""
    }
    
    private func removeDomain(_ domain: String) {
        group.domains.removeAll(where: { $0 == domain })
        store.saveData()
    }
    
    private func importTxtFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.plainText]
        
        if panel.runModal() == .OK, let url = panel.url {
            let parsed = DomainParser.parse(fileURL: url)
            var currentSet = Set(group.domains)
            for d in parsed { currentSet.insert(d) }
            group.domains = Array(currentSet).sorted()
            store.saveData()
        }
    }
    
    private func addSchedule() {
        let newSch = Schedule(groupId: group.id)
        store.schedules.append(newSch)
        store.saveData()
    }
    
    private func activateQuickFocus() {
        // Adiciona 30 minutos (1800 segundos) à hora atual
        BlockEngine.shared.temporaryBlocks[group.id] = Date().addingTimeInterval(30 * 60)
        BlockEngine.shared.evaluate(store: store)
    }
}
