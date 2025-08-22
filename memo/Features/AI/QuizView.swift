// memo/Features/AI/QuizView.swift
import SwiftUI

struct QuizView: View {
    @ObservedObject var vm: AIGeneratorViewModel
    
    var body: some View {
        VStack {
            if let question = vm.currentQuestion {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Questão \(vm.currentQuestionIndex + 1) de \(vm.displayTotalCount)")
                            .font(.caption).foregroundColor(.secondary)
                        ProgressView(value: Double(vm.currentQuestionIndex + 1), total: Double(max(1, vm.displayTotalCount)))
                            .tint(.dsPrimary)
                    }
                    Text(question.prompt)
                        .font(.title2.bold())
                        .frame(minHeight: 80, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(Array(question.options.enumerated()), id: \.element.id) { (index, option) in
                        QuizOptionView(vm: vm, option: option, question: question, index: index)
                    }
                    Spacer()
                    if vm.isAnswerSubmitted {
                        VStack(spacing: 12) {
                            if let explanation = vm.currentQuestion?.explanation, !explanation.isEmpty {
                                Text(explanation)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, 4)
                            }
                            HStack(spacing: 12) {
                                Button("Reportar") { vm.reportCurrentQuestion() }
                                    .buttonStyle(SocialButtonStyle())
                                
                                // Lógica simplificada para controlar os botões
                                if vm.isNextAvailable {
                                    // Se a próxima pergunta já existe na lista
                                    Button("Próxima Questão", action: vm.nextQuestion)
                                        .buttonStyle(PrimaryButtonStyle())
                                } else if (vm.currentQuestionIndex + 1) >= vm.displayTotalCount {
                                    // Se não há mais perguntas
                                    Button("Finalizar Quiz") {
                                        // Avança o índice para acionar o estado de finalizado
                                        vm.currentQuestionIndex = vm.items.count
                                    }
                                    .buttonStyle(PrimaryButtonStyle())
                                }
                            }
                        }
                    } else {
                        Button("Confirmar", action: vm.submitAnswer)
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(vm.selectedOptionID == nil)
                    }
                }
                .padding(20)
            }
        }
        .background(Color.dsBackground.ignoresSafeArea())
        .onChange(of: vm.currentQuestionIndex) { _, newIndex in
            // Se o índice atingir o planejado e não houver mais itens, finaliza o quiz
            if newIndex >= vm.displayTotalCount {
                // Garante que o estado de finalização seja respeitado
            }
        }
    }
}

private struct QuizOptionView: View {
    @ObservedObject var vm: AIGeneratorViewModel
    let option: AIOption
    let question: AIQuestion
    let index: Int

    private var optionLetter: String { String(UnicodeScalar(UInt8(65 + index))) }
    
    private var isSelected: Bool { vm.selectedOptionID == option.id }
    private var isCorrect: Bool { question.options[question.correctAnswerIndex].id == option.id }

    private var borderColor: Color {
        if vm.isAnswerSubmitted {
            if isCorrect { return .dsSuccess }
            if isSelected { return .dsError }
            return Color.gray.opacity(0.25)
        } else {
            return isSelected ? .dsPrimary : Color.gray.opacity(0.25)
        }
    }

    private var rowBackground: Color {
        if vm.isAnswerSubmitted {
            if isCorrect { return Color.dsSuccess.opacity(0.14) }
            if isSelected { return Color.dsError.opacity(0.10) }
            return Color(uiColor: .secondarySystemBackground)
        } else {
            return isSelected ? Color.dsPrimary.opacity(0.10) : Color(uiColor: .secondarySystemBackground)
        }
    }

    var body: some View {
        Button(action: { vm.selectOption(option) }) {
            HStack(spacing: 16) {
                Text(optionLetter)
                    .font(.headline.bold())
                    .foregroundColor(isSelected && !vm.isAnswerSubmitted ? .white : .primary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(
                            vm.isAnswerSubmitted
                                ? (isCorrect ? Color.dsSuccess.opacity(0.9) : (isSelected ? Color.dsError.opacity(0.9) : Color.dsChipBackground))
                                : (isSelected ? Color.dsPrimary : Color.dsChipBackground)
                        )
                    )
                Text(option.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(rowBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: (isSelected || vm.isAnswerSubmitted) ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
