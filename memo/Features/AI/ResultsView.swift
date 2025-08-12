// memo/Features/AI/ResultsView.swift

import SwiftUI

struct ResultsView: View {
    @ObservedObject var vm: AIGeneratorViewModel

    // MARK: - Propriedades Computadas para Feedback
    private var performancePercentage: Double {
        guard !vm.items.isEmpty else { return 0 }
        return Double(vm.correctAnswersCount) / Double(vm.items.count)
    }

    private var feedbackTitle: String {
        switch performancePercentage {
        case 0...0.4: return "Continue a Estudar!"
        case 0.4..<0.8: return "Bom Trabalho!"
        case 0.8...1.0: return "Excelente Desempenho!"
        default: return "Quiz Finalizado!"
        }
    }
    
    private var feedbackMessage: String {
        switch performancePercentage {
        case 0...0.4: return "Não desanime. A repetição é a chave para o aprendizado. Que tal rever este tópico e tentar de novo?"
        case 0.4..<0.8: return "Você está no caminho certo! Continue focado e você dominará este assunto em pouco tempo."
        case 0.8...1.0: return "Parabéns! Você demonstrou um ótimo conhecimento sobre o tema. Mantenha o ritmo!"
        default: return "Continue a praticar para fixar o conteúdo."
        }
    }

    private var iconName: String {
        switch performancePercentage {
        case 0...0.4: return "book.circle.fill"
        case 0.4..<0.8: return "flame.fill"
        case 0.8...1.0: return "trophy.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch performancePercentage {
        case 0...0.4: return .dsBlue
        case 0.4..<0.8: return .dsYellow
        case 0.8...1.0: return .dsSuccess
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: iconName)
                .font(.system(size: 80))
                .foregroundColor(iconColor)
            
            Text(feedbackTitle)
                .font(.largeTitle.bold())
            
            Text("Você acertou **\(vm.correctAnswersCount)** de **\(vm.items.count)** questões.")
                .font(.title3)
            
            Text(feedbackMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
            Spacer()
            
            Button("Gerar Novo Quiz", action: vm.resetQuiz)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(30)
        .background(Color.dsBackground.ignoresSafeArea())
    }
}
