// memo/Features/AI/QuizView.swift
import SwiftUI

struct QuizView: View {
    @ObservedObject var vm: AIGeneratorViewModel
    
    var body: some View {
        VStack {
            if let question = vm.currentQuestion {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Questão \(vm.currentQuestionIndex + 1) de \(vm.items.count)")
                            .font(.caption).foregroundColor(.secondary)
                        ProgressView(value: Double(vm.currentQuestionIndex + 1), total: Double(vm.items.count))
                            .tint(.dsPrimary)
                    }
                    Text(question.prompt).font(.title2.bold()).frame(minHeight: 100, alignment: .leading)
                    ForEach(Array(question.options.enumerated()), id: \.element.id) { (index, option) in
                        QuizOptionView(vm: vm, option: option, question: question, index: index)
                    }
                    Spacer()
                    if vm.isAnswerSubmitted {
                        Button("Próxima Questão", action: vm.nextQuestion).buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("Confirmar", action: vm.submitAnswer).buttonStyle(PrimaryButtonStyle()).disabled(vm.selectedOptionID == nil)
                    }
                }
                .padding(20)
            }
        }
        .background(Color.dsBackground.ignoresSafeArea())
    }
}

private struct QuizOptionView: View {
    let vm: AIGeneratorViewModel
    let option: AIOption
    let question: AIQuestion
    let index: Int

    private var optionLetter: String { String(UnicodeScalar(UInt8(65 + index))) }
    
    var color: Color {
        guard vm.isAnswerSubmitted else { return vm.selectedOptionID == option.id ? .dsPrimary : Color(uiColor: .secondarySystemBackground) }
        let isCorrectAnswer = question.options[question.correctAnswerIndex].id == option.id
        if isCorrectAnswer { return .dsSuccess }
        else if vm.selectedOptionID == option.id { return .dsError }
        else { return Color(uiColor: .secondarySystemBackground) }
    }

    var body: some View {
        Button(action: { vm.selectOption(option) }) {
            HStack(spacing: 16) {
                Text(optionLetter).font(.headline.bold())
                    .foregroundColor(color == .dsPrimary ? .white : color)
                    .frame(width: 30, height: 30)
                    .background(color == .dsPrimary ? color : color.opacity(0.3))
                    .clipShape(Circle())
                Text(option.text).frame(maxWidth: .infinity, alignment: .leading).foregroundColor(.primary)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: vm.selectedOptionID == option.id || vm.isAnswerSubmitted ? 2 : 1))
        }
    }
}
