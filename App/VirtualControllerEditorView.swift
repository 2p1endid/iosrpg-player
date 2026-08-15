import SwiftUI

struct VirtualControllerEditorView: View {
    @AppLanguageStorage private var language
    @Binding var profile: VirtualControllerProfile
    let onSave: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: UUID?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { proxy in
                    ZStack {
                        Color.black
                        ForEach($profile.buttons) { $button in
                            editorButton(button: $button, in: proxy.size)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding()
                }
                .frame(minHeight: 260)

                if let index = selectedIndex {
                    Form {
                        Section(language.text(.controllerButton)) {
                            TextField(language.text(.buttonLabel), text: $profile.buttons[index].label)
                                .onChange(of: profile.buttons[index].label) { _, value in
                                    profile.buttons[index].label = String(value.prefix(4))
                                }
                            if !profile.buttons[index].isBuiltIn {
                                Picker(language.text(.buttonMapping), selection: $profile.buttons[index].mapping) {
                                    ForEach(VirtualInputMapping.Kind.allCases, id: \.self) { mapping in
                                        Text(mapping.rawValue).tag(mapping)
                                    }
                                }
                            }
                            Slider(value: $profile.buttons[index].size, in: 36...120, step: 1) {
                                Text(language.text(.buttonSize))
                            }
                            ColorPicker(language.text(.buttonColor), selection: colorBinding(index: index), supportsOpacity: false)
                            if !profile.buttons[index].isBuiltIn {
                                Button(language.text(.deleteCustomButton), role: .destructive) {
                                    profile.buttons.remove(at: index)
                                    selectedID = nil
                                }
                            }
                        }
                    }
                    .frame(height: 250)
                }
            }
            .navigationTitle(language.text(.controllerSettings))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.text(.cancel)) {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu(language.text(.addButton)) {
                        ForEach(VirtualInputMapping.Kind.allCases, id: \.self) { mapping in
                            Button(mapping.rawValue) {
                                let added = profile.addButton(mapping: mapping)
                                selectedID = added.id
                            }
                        }
                    }
                    .disabled(profile.buttons.count >= 24)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(language.text(.resetDefaults)) {
                        profile = .defaultProfile
                        selectedID = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.text(.done)) {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }

    private var selectedIndex: Int? {
        guard let selectedID else { return nil }
        return profile.buttons.firstIndex { $0.id == selectedID }
    }

    private func editorButton(button: Binding<VirtualControllerButton>, in size: CGSize) -> some View {
        let value = button.wrappedValue
        return Text(value.label)
            .font(.headline.bold())
            .frame(width: value.size, height: value.size)
            .background(Color(hex: value.colorHex).opacity(0.75), in: Circle())
            .overlay(Circle().stroke(selectedID == value.id ? .white : .white.opacity(0.3), lineWidth: selectedID == value.id ? 3 : 1))
            .position(
                x: min(max(value.x * size.width, value.size / 2), max(value.size / 2, size.width - value.size / 2)),
                y: min(max(value.y * size.height, value.size / 2), max(value.size / 2, size.height - value.size / 2))
            )
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        selectedID = value.id
                        let radius = button.wrappedValue.size / 2
                        let x = min(max(gesture.location.x, radius), max(radius, size.width - radius))
                        let y = min(max(gesture.location.y, radius), max(radius, size.height - radius))
                        button.wrappedValue.x = x / max(size.width, 1)
                        button.wrappedValue.y = y / max(size.height, 1)
                    }
            )
            .onTapGesture { selectedID = value.id }
    }

    private func colorBinding(index: Int) -> Binding<Color> {
        Binding(
            get: { Color(hex: profile.buttons[index].colorHex) },
            set: { profile.buttons[index].colorHex = $0.rrppgoHex }
        )
    }
}
