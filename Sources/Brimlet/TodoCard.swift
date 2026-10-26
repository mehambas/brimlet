import AppKit
import SwiftUI

struct TodoCard: View {
    @ObservedObject var module: TodoModule
    @State private var showingEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Tasks").font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 0)
                if module.recentlyCompleted != nil {
                    Button("Undo") { module.undoCompletion() }
                        .font(.system(size: 11, weight: .semibold)).buttonStyle(.plain).foregroundStyle(BrimletTheme.mint)
                }
                Button {
                    module.showCompleted.toggle()
                } label: {
                    Text(module.showCompleted ? "Open Tasks" : "Completed")
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(BrimletTheme.secondary)
                }.buttonStyle(.plain)
                if !module.showCompleted {
                    IconButton(symbol: "plus", help: "New Task", prominent: true) {
                        module.isEditorPresented = true
                        showingEditor = true
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    filterChip("All", selected: module.selectedCategory == nil) { module.selectedCategory = nil }
                    ForEach(TodoCategory.allCases) { category in
                        filterChip("\(category.title)", selected: module.selectedCategory == category) { module.selectedCategory = category }
                    }
                }
            }
            ScrollView {
                LazyVStack(spacing: 5) {
                    let items = module.showCompleted ? module.completedItems : module.activeItems
                    if items.isEmpty {
                        Text(module.showCompleted ? "Tasks completed in the last 30 days appear here." : "Nothing to do. Add a new task.")
                            .font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 13)
                    } else {
                        ForEach(items) { item in
                            HStack(spacing: 8) {
                                Button { module.complete(item.id) } label: {
                                    Image(systemName: item.completedAt == nil ? "circle" : "checkmark.circle.fill")
                                        .font(.system(size: 15)).foregroundStyle(item.completedAt == nil ? BrimletTheme.secondary : BrimletTheme.mint)
                                }.buttonStyle(.plain).frame(width: 28, height: 28).accessibilityLabel("Complete \(item.title)").disabled(item.completedAt != nil)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title).font(.system(size: 11, weight: .medium)).lineLimit(1)
                                        .strikethrough(item.completedAt != nil).foregroundStyle(item.completedAt == nil ? .white : BrimletTheme.secondary)
                                    HStack(spacing: 5) {
                                        Text(item.category.title)
                                        if let date = item.dueDate { Text("· \(date.formatted(.dateTime.day().month()))") }
                                        if item.reminderEnabled { Image(systemName: "bell.fill") }
                                        if !item.note.isEmpty { Text("· \(item.note)").lineLimit(1) }
                                    }.font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary)
                                }
                                Spacer(minLength: 2)
                                if item.completedAt != nil {
                                    Button { module.remove(item.id) } label: { Image(systemName: "trash").font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary) }
                                        .buttonStyle(.plain).frame(width: 28, height: 28).help("Delete").accessibilityLabel("Delete")
                                }
                            }
                            .padding(.horizontal, 9).padding(.vertical, 6)
                            .background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 9))
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 20).frame(height: 186, alignment: .top)
        .sheet(isPresented: $showingEditor, onDismiss: { module.isEditorPresented = false }) {
            TodoEditor(module: module)
                .environment(\.colorScheme, NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? .dark : .light)
                .preferredColorScheme(nil)
        }
    }

    private func filterChip(_ title: LocalizedStringKey, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 11, weight: .medium)).padding(.horizontal, 9).padding(.vertical, 5)
                .foregroundStyle(selected ? BrimletTheme.primary : BrimletTheme.secondary)
                .background(selected ? BrimletTheme.raised : BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain)
    }
}

struct TodoEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var module: TodoModule
    @State private var title = ""
    @State private var note = ""
    @State private var category: TodoCategory = .home
    @State private var hasDate = false
    @State private var dueDate = Date()
    @State private var reminder = false

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("New Task").font(.system(size: 15, weight: .semibold))
            TextField("What do you need to do?", text: $title).textFieldStyle(.roundedBorder)
            TextField("Note (optional)", text: $note).textFieldStyle(.roundedBorder)
            Picker("Category", selection: $category) {
                ForEach(TodoCategory.allCases) { Text($0.title).tag($0) }
            }
            Toggle("Add a Date", isOn: $hasDate).toggleStyle(.switch).controlSize(.small)
            if hasDate {
                DatePicker("Due", selection: $dueDate, in: Calendar.current.startOfDay(for: Date())..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                Toggle("Remind me at 9:00 that morning", isOn: $reminder).toggleStyle(.switch).controlSize(.small)
            }
            Spacer(minLength: 0)
            HStack {
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add") {
                    module.add(title: title, note: note, category: category, dueDate: hasDate ? dueDate : nil, reminder: reminder)
                    dismiss()
                }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction).disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20).frame(width: 360, height: hasDate ? 368 : 282)
        .background(Color(nsColor: .windowBackgroundColor)).foregroundStyle(.primary)
        .tint(BrimletTheme.jade)
    }
}
