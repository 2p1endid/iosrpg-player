import SwiftUI

struct VirtualControllerEditorView: View {
    @Binding var profile: VirtualControllerProfile
    let onSave: () -> Void
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
                        Section("Button") {
                            TextField("Label", text: $profile.buttons[index].label)
                                .onChange(of: profile.buttons[index].label) { _, value in
                                    profile.buttons[index].label = String(value.prefix(4))
                                }
                            Picker("Mapping", selection: $profile.buttons[index].mapping) {
                                ForEach(VirtualInputMapping.Kind.allCases, id: \.self) { mapping in
                                    Text(mapping.rawValue).tag(mapping)
                                }
                            }
                            Slider(value: $profile.buttons[index].size, in: 36...120, step: 1) {
                                Text("Size")
                            }
                            ColorPicker("Color", selection: colorBinding(index: index), supportsOpacity: false)
                            if !profile.buttons[index].isBuiltIn {
                                Button("Delete Custom Button", role: .destructive) {
                                    profile.buttons.remove(at: index)
                                    selectedID = nil
                                }
                            }
                        }
                    }
                    .frame(height: 250)
                }
            }
            .navigationTitle("Controller")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu("Add") {
                        ForEach(VirtualInputMapping.Kind.allCases, id: \.self) { mapping in
                            Button(mapping.rawValue) {
                                let added = profile.addButton(mapping: mapping)
                                selectedID = added.id
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        profile = .defaultProfile
                        selectedID = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
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
            .position(x: value.x * size.width, y: value.y * size.height)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        selectedID = value.id
                        button.wrappedValue.x = min(max(gesture.location.x / max(size.width, 1), 0), 1)
                        button.wrappedValue.y = min(max(gesture.location.y / max(size.height, 1), 0), 1)
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
