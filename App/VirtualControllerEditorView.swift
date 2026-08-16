import SwiftUI

struct VirtualControllerEditorView: View {
    @AppLanguageStorage private var language
    @Binding var profile: VirtualControllerProfile
    let controllerOrientation: VirtualControllerOrientation
    let onSave: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: UUID?
    @State private var editorCanvasSize = CGSize(width: 375, height: 300)
    private let editorCanvasHeight: CGFloat = 300

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
                    .onAppear { editorCanvasSize = proxy.size }
                    .onChange(of: proxy.size) { _, newSize in
                        editorCanvasSize = newSize
                    }
                }
                .frame(height: editorCanvasHeight)

                Form {
                    if let index = selectedIndex {
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
                        }
                        Section(language.text(.buttonColor)) {
                            colorButton(.blue, index: index)
                            colorButton(.red, index: index)
                            colorButton(.green, index: index)
                            colorButton(.orange, index: index)
                            colorButton(.purple, index: index)
                            colorButton(.gray, index: index)
                        }
                        if !profile.buttons[index].isBuiltIn {
                            Section {
                                Button(language.text(.deleteCustomButton), role: .destructive) {
                                    profile.buttons.remove(at: index)
                                    selectedID = nil
                                }
                            }
                        }
                    } else {
                        Section { Text(language.text(.selectButton)) }
                    }
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
                        let defaultSize = controllerOrientation == .landscape
                            ? CGSize(width: max(editorCanvasSize.width, 640), height: min(editorCanvasSize.height, 393))
                            : CGSize(width: min(editorCanvasSize.width, 430), height: max(editorCanvasSize.height, 700))
                        profile = .adaptiveDefault(in: defaultSize)
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
        let radius = value.size / 2
        let x = min(max(value.x * size.width, radius), max(radius, size.width - radius))
        let y = min(max(value.y * size.height, radius), max(radius, size.height - radius))

        return Text(value.label)
            .font(.headline.bold())
            .frame(width: value.size, height: value.size)
            .background(Color(hex: value.colorHex).opacity(0.75), in: Circle())
            .overlay(Circle().stroke(selectedID == value.id ? .white : .white.opacity(0.3), lineWidth: selectedID == value.id ? 3 : 1))
            .position(x: x, y: y)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        selectedID = value.id
                        let currentRadius = button.wrappedValue.size / 2
                        let newX = min(max(gesture.location.x, currentRadius), max(currentRadius, size.width - currentRadius))
                        let newY = min(max(gesture.location.y, currentRadius), max(currentRadius, size.height - currentRadius))
                        button.wrappedValue.x = newX / max(size.width, 1)
                        button.wrappedValue.y = newY / max(size.height, 1)
                    }
            )
            .onTapGesture { selectedID = value.id }
    }

    private func colorButton(_ color: Color, index: Int) -> some View {
        Button {
            profile.buttons[index].colorHex = color.rrppgoHex
        } label: {
            HStack {
                Circle().fill(color).frame(width: 24, height: 24)
                Spacer()
                if profile.buttons[index].colorHex == color.rrppgoHex {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
