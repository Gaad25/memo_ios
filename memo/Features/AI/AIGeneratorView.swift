// memo/Features/AI/AIGeneratorView.swift
import SwiftUI

// MARK: - Router
struct AIGeneratorView: View {
    @StateObject private var vm = AIGeneratorViewModel()

    var body: some View {
        NavigationStack {
            if vm.isQuizActive {
                if vm.isQuizFinished {
                    ResultsView(vm: vm)
                } else {
                    QuizView(vm: vm)
                }
            } else {
                ZoeGeneratorView(vm: vm)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.isQuizActive)
        .animation(.easeInOut(duration: 0.25), value: vm.isQuizFinished)
    }
}

// MARK: - Tela “Zoe”
struct ZoeGeneratorView: View {
    @ObservedObject var vm: AIGeneratorViewModel

    // foco para o campo de tema
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case subject }

    // frases simpáticas da Zoe
    private var greeting: String {
        if vm.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Olá! Sou a Zoe. Sobre qual matéria vamos criar um quiz hoje?"
        } else {
            return "Perfeito! Vamos treinar \(vm.subject)?"
        }
    }

    var body: some View {
        ScrollView {
            ZStack {
                PawBackground() // patinhas sutis
                VStack(spacing: 18) {

                    // Header com a Zoe + balão
                    HStack(alignment: .top, spacing: 12) {
                        ZoeAvatar(size: 64)
                        SpeechBubble(text: greeting)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // CARD: Tema
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                IconCircle(system: "magnifyingglass")
                                SectionLabelCaps("Tema")
                            }
                            IconTextField(
                                iconName: "magnifyingglass",
                                placeholder: "Ex.: História do Brasil",
                                text: $vm.subject,
                                isInvalid: vm.error != nil,
                                focusedField: $focusedField,
                                field: .subject
                            )
                            if let error = vm.error {
                                Text(error.localizedDescription)
                                    .font(.footnote)
                                    .foregroundStyle(Color.dsError)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // CARD: Nível de dificuldade (pills com gradiente)
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                IconCircle(system: "bolt.badge.a")
                                SectionLabelCaps("Nível de Dificuldade")
                            }
                            DifficultyPills(selection: $vm.level) // "Fácil" | "Intermediário" | "Difícil"
                        }
                    }
                    .padding(.horizontal, 16)
                    .sensoryFeedback(.selection, trigger: vm.level)

                    // CARD: Quantidade
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                IconCircle(system: "number.circle")
                                SectionLabelCaps("Quantidade")
                            }
                            HStack {
                                Text("\(vm.count) \(vm.count == 1 ? "Questão" : "Questões")")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color.dsTextPrimary)
                                Spacer()
                                InlineStepper(value: $vm.count, in: 1...20)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .sensoryFeedback(.impact(weight: .light), trigger: vm.count)

                    // Botão principal
                    Button {
                        focusedField = nil
                        vm.generate()
                    } label: {
                        HStack(spacing: 10) {
                            if vm.loading {
                                ProgressView(value: vm.fakeProgress)
                                    .tint(.white)
                                    .frame(width: 56)
                                    .animation(.linear, value: vm.fakeProgress)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text(vm.loading ? "A Zoe está a preparar suas perguntas... \(Int(vm.fakeProgress * 100))%" : "Criar Quiz com a Zoe")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(GradientPrimaryButtonStyle())
                    .disabled(vm.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.loading)
                    .sensoryFeedback(.impact(weight: .light), trigger: vm.loading)
                    .contextMenu {
                        if vm.loading {
                            Button(role: .destructive) { vm.cancelStreaming() } label: {
                                Label("Cancelar", systemImage: "xmark.circle")
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
                .padding(.bottom, 24)
            }
        }
        .background(
            LinearGradient(colors: [Color.dsBackgroundTop, Color.dsBackground],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
        .navigationTitle("Quiz com a Zoe")
        .navigationBarTitleDisplayMode(.inline)
        .scrollIndicators(.hidden)
    }
}

//
// MARK: - Pequenos componentes da “marca Zoe”
//

/// Avatar com aro em gradiente. Usa `Image("ZoeAvatar")` se existir; senão, fallback para SF Symbol.
struct ZoeAvatar: View {
    var size: CGFloat = 56

    private var ring: some View {
        Circle().strokeBorder(
            LinearGradient(colors: [.dsPrimary, .dsAccent],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            lineWidth: max(3, size * 0.06)
        )
    }

    var body: some View {
        ZStack {
            if let _ = UIImage(named: "ZoeAvatar") {
                Image("ZoeAvatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(ring)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            } else {
                Image(systemName: "pawprint.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundStyle(
                        .white,
                        LinearGradient(colors: [.dsPrimary, .dsAccent],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(ring)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            }
        }
        .accessibilityLabel("Zoe, sua assistente de estudos")
    }
}

/// Balão de fala simples (auto-layout com texto).
struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Color.dsTextPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
            .overlay(alignment: .leading) {
                // rabinho do balão
                Triangle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .rotationEffect(.degrees(45))
                    .offset(x: -8, y: 8)
                    .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 1)
            }
    }
}

/// Triângulo básico para o “rabinho” do balão
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Fundo com patinhas muito sutis
struct PawBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.dsTextTertiary.opacity(0.08))
                        .rotationEffect(.degrees(Double(i * 12)))
                        .position(x: CGFloat.random(in: 0.1...0.9) * w,
                                  y: CGFloat.random(in: 0.1...0.9) * h)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Ícone pequeno em círculo com cor da marca
struct IconCircle: View {
    let system: String
    var body: some View {
        Image(systemName: system)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(
                Circle().fill(
                    LinearGradient(colors: [.dsPrimary, .dsAccent],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            )
    }
}
