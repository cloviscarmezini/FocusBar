import SwiftUI

struct ScheduleRowView: View {
    @Binding var schedule: Schedule
    @EnvironmentObject var store: Store
    
    // Dicionário de dias (Swift usa 1 para Domingo, 2 para Segunda...)
    let days = [
        (1, "Dom"), (2, "Seg"), (3, "Ter"), (4, "Qua"),
        (5, "Qui"), (6, "Sex"), (7, "Sáb")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Ativo", isOn: $schedule.isEnabled)
                    .toggleStyle(.switch)
                
                Spacer()
                
                Button(action: deleteSchedule) {
                    Image(systemName: "trash").foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                DatePicker("Início", selection: $schedule.startTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Text("até")
                DatePicker("Fim", selection: $schedule.endTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            
            HStack {
                ForEach(days, id: \.0) { day in
                    let isSelected = schedule.selectedDays.contains(day.0)
                    Text(day.1)
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                        .foregroundColor(isSelected ? .white : .primary)
                        .cornerRadius(6)
                        .onTapGesture {
                            if isSelected {
                                schedule.selectedDays.remove(day.0)
                            } else {
                                schedule.selectedDays.insert(day.0)
                            }
                            store.saveData()
                        }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onChange(of: schedule) { _, _ in
            store.saveData()
        }
    }
    
    private func deleteSchedule() {
        store.schedules.removeAll(where: { $0.id == schedule.id })
        store.saveData()
    }
}
