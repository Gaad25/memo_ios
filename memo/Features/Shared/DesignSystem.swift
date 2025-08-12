// memo/Features/Shared/DesignSystem.swift

import SwiftUI

// MARK: - Color Palette
extension Color {
    // Cores base do sistema
    static let dsBackground = Color(.systemGroupedBackground)
    static let dsSecondaryBackground = Color(.secondarySystemGroupedBackground)
    
    // Cores de texto do sistema
    static let dsTextPrimary = Color(.label)
    static let dsTextSecondary = Color(.secondaryLabel)
    
    // Cores de feedback do sistema
    static let dsError = Color(.systemRed)
    static let dsSuccess = Color(.systemGreen)
    
    // --- CORES ADICIONADAS ---
    // Cores da nova identidade visual
    static let dsPrimary        = Color(hex: "#2563EB") // Azul principal
    static let dsAccent         = Color(hex: "#10B981") // Verde/Teal para gradientes
    static let dsBackgroundTop  = Color(hex: "#F8FAFF") // Topo claro do gradiente de fundo
    static let dsChipBackground = Color(hex: "#E9EDF6") // Fundo de "pílulas" e steppers
    static let dsTextTertiary   = Color(hex: "#8A93A4") // Texto terciário/labels
    
    // Cores personalizadas antigas (mantidas para consistência)
    static let dsBlue = Color(hex: "#2563EB")
    static let dsGreen = Color(hex: "#10B981")
    static let dsYellow = Color(hex: "#F59E0B")
    static let dsRed = Color(hex: "#DC2626")
    
    // Cores para ícones em seções de configurações
    static let dsIcon = Color("IconPrimary")
    static let dsIconDestructive = Color("IconDestructive")
    // -------------------------
    
    // Função auxiliar para criar cores a partir de códigos Hexadecimais
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.dsPrimary.opacity(isEnabled ? 1.0 : 0.5))
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}


struct SocialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.dsTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.dsSecondaryBackground)
            .cornerRadius(12)
            .overlay(
                 RoundedRectangle(cornerRadius: 12)
                     .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}


// MARK: - TextField Modifier
struct PrimaryTextFieldStyle: ViewModifier {
    var isInvalid: Bool = false

    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.dsSecondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isInvalid ? Color.dsError : Color.clear, lineWidth: 1)
            )
    }
}


// MARK: - Animation Effects
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakes: Int
    
    var animatableData: Int {
        get { shakes }
        set { shakes = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(CGFloat(shakes) * .pi * 2),
            y: 0))
    }
}

// MARK: - TextField (Totalmente redesenhado para incluir Ícone e Borda)
struct IconTextField<Field: Hashable>: View {
    let iconName: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    // Para validação
    var isInvalid: Bool = false
    
    // Para foco do teclado
    @FocusState.Binding var focusedField: Field? 
    let field: Field

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.dsTextSecondary)
                .frame(width: 20, alignment: .center)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($focusedField, equals: field)
            } else {
                TextField(placeholder, text: $text)
                    .focused($focusedField, equals: field)
            }
        }
        .padding()
        .background(Color.dsSecondaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isInvalid ? .dsError : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
// MARK: - Card View Modifier
// Estilo de card com profundidade (efeito Neumórfico Suave)
struct CardBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.dsBackground)
                    .shadow(color: .white.opacity(0.7), radius: 5, x: -5, y: -5)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 5, y: 5)
            )
    }
}

// MARK: - Section Header Style
struct SectionHeader: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Button(action: action) {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.dsPrimary)
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Empty State View
// Componente reutilizável para quando as listas estiverem vazias
struct EmptyStateView: View {
    let systemImageName: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImageName)
                .font(.system(size: 50))
                .foregroundColor(.dsPrimary)
                .opacity(0.6)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.dsTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .modifier(CardBackgroundModifier())
    }
}

struct TimerControlButton: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 40, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 80, height: 80)
            .background(color)
            .clipShape(Circle())
            .shadow(color: color.opacity(0.3), radius: 10, y: 10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// O CheckboxToggleStyle foi movido para cá para ficar centralizado
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }, label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                configuration.label
            }
        })
        .buttonStyle(.plain)
    }
}

// MARK: - Stepper Style
struct CustomStepperStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.dsSecondaryBackground)
            .cornerRadius(12)
    }
}

// MARK: - Difficulty Picker
// Componente para a seleção de dificuldade
struct DifficultyPicker: View {
    let difficulties = ["Fácil", "Intermediário", "Difícil"]
    @Binding var selection: String

    var body: some View {
        Picker("Nível de Dificuldade", selection: $selection) {
            ForEach(difficulties, id: \.self) {
                Text($0)
            }
        }
        .pickerStyle(.segmented)
    }
}
// MARK: - Premium: Section Label (caps)
struct SectionLabelCaps: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.dsTextTertiary)
            .textCase(.uppercase)
            .kerning(0.5)
    }
}

// MARK: - Premium: Glass Card
// MARK: - Premium: Glass Card (fix de ShapeStyle)
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        // Material dentro de uma forma (não usa .fill)
        .background(.ultraThinMaterial, in: shape)
        // “vidro” branco por baixo
        .background(Color.white.opacity(0.45), in: shape)
        // borda suave
        .overlay(shape.strokeBorder(Color.black.opacity(0.06)))
        // sombra leve
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }
}

// MARK: - Premium: Pill Picker (genérico)
struct PillPicker<Value: Hashable & Equatable>: View {
    struct Item {
        let title: String
        let value: Value
        init(_ title: String, _ value: Value) { self.title = title; self.value = value }
    }

    @Binding var selection: Value
    let items: [Item]

    @ViewBuilder
    private func capsuleBackground(selected: Bool) -> some View {
        if selected {
            Capsule().fill(
                LinearGradient(colors: [Color.dsPrimary, Color.dsAccent],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        } else {
            Capsule().fill(Color.dsChipBackground)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.title) { item in
                let isSelected = (selection == item.value)

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selection = item.value
                    }
                } label: {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        // aplica a cápsula já preenchida (View), não um ShapeStyle
                        .background(capsuleBackground(selected: isSelected))
                        .foregroundStyle(isSelected ? .white : .dsTextPrimary)
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
        }
    }
}


// MARK: - Premium: Difficulty Pills (conveniência com String)
struct DifficultyPills: View {
    @Binding var selection: String
    private let options = [
        PillPicker<String>.Item("Fácil", "Fácil"),
        PillPicker<String>.Item("Médio", "Médio"),
        PillPicker<String>.Item("Difícil", "Difícil")
    ]
    var body: some View {
        PillPicker(selection: $selection, items: options)
    }
}

// MARK: - Premium: Inline Stepper + Round Button
struct InlineStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...20

    init(value: Binding<Int>, in range: ClosedRange<Int>) {
        _value = value
        self.range = range
    }

    var body: some View {
        HStack(spacing: 10) {
            RoundIconButton(system: "minus") {
                if value > range.lowerBound { value -= 1 }
            }
            RoundIconButton(system: "plus") {
                if value < range.upperBound { value += 1 }
            }
        }
    }
}

struct RoundIconButton: View {
    let system: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.dsChipBackground))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Premium: Gradient Primary Button Style
struct GradientPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let c1 = Color.dsPrimary.opacity(isEnabled ? 1 : 0.5)
        let c2 = Color.dsAccent.opacity(isEnabled ? 1 : 0.5)
        let grad = LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
        let pressed = configuration.isPressed

        return configuration.label
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(grad)
            )
            .shadow(color: .black.opacity(pressed ? 0.06 : 0.12), radius: 14, y: 8)
            .scaleEffect(pressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: pressed)
    }
}

// MARK: - Premium: Header Block (ícone + textos)
struct HeaderBlock: View {
    let title: String
    let subtitle: String
    let systemIcon: String

    private var avatarGradient: LinearGradient {
        LinearGradient(colors: [Color.dsPrimary, Color.dsAccent],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(avatarGradient)
                    .frame(width: 52, height: 52)
                Image(systemName: systemIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.dsTextPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.dsTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

struct IconTextFieldPremium: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isInvalid: Bool = false
    
    // --- CORREÇÃO AQUI ---
    // Em vez de ter o seu próprio FocusState, ele agora recebe o
    // binding da view que o está a usar.
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                // Usa o .wrappedValue para ler o estado do binding
                .foregroundStyle(focused.wrappedValue ? Color.dsPrimary : Color.dsTextTertiary)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .font(.body)
                .foregroundStyle(Color.dsTextPrimary)
                // Usa o binding de foco que foi passado como parâmetro
                .focused(focused)

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isInvalid ? Color.dsError : (focused.wrappedValue ? Color.dsPrimary.opacity(0.35) : Color.gray.opacity(0.2)), lineWidth: 1.5)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
        .animation(.easeInOut(duration: 0.15), value: focused.wrappedValue)
    }
}

// MARK: - Filter Chip Style
struct FilterChipStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.dsPrimary : Color.dsSecondaryBackground)
            .foregroundColor(isSelected ? .white : Color.dsTextPrimary)
            .clipShape(Capsule())
            .animation(.easeInOut, value: isSelected)
    }
}

// MARK: - Empty State for Reviews
struct EmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .symbolRenderingMode(.hierarchical)

            Text("Nenhuma revisão pendente!")
                .font(.title2.bold())
                .foregroundColor(.dsTextPrimary)

            Text("Você está em dia com seus estudos.\nAproveite para relaxar ou iniciar um novo tópico!")
                .font(.subheadline)
                .foregroundColor(.dsTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Color.dsSecondaryBackground)
        .cornerRadius(20)
        .padding()
    }
}
