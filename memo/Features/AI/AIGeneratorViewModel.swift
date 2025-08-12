// memo/Features/AI/AIGeneratorViewModel.swift

import Foundation

@MainActor
final class AIGeneratorViewModel: ObservableObject {
    
    // MARK: - Estado do Formulário de Geração
    @Published var subject = ""
    @Published var level = "Intermediário"
    @Published var count = 5
    @Published var loading = false
    @Published var error: AppError?
    
    // MARK: - Estado do Quiz
    @Published var items: [AIQuestion] = []
    @Published var isQuizActive = false // Esta propriedade vai controlar o fluxo
    @Published var currentQuestionIndex = 0
    @Published var selectedOptionID: UUID?
    @Published var isAnswerSubmitted = false
    @Published var correctAnswersCount = 0

    private let ai: AIService

    init(ai: AIService = OpenAIService()) {
        self.ai = ai
    }
    
    var currentQuestion: AIQuestion? {
        guard items.indices.contains(currentQuestionIndex) else { return nil }
        return items[currentQuestionIndex]
    }
    
    // --- CORREÇÃO NA LÓGICA (1/2) ---
    // isQuizFinished só deve ser verdadeiro se houver itens e o índice estiver no final.
    var isQuizFinished: Bool {
        !items.isEmpty && currentQuestionIndex >= items.count
    }

    // MARK: - Funções de Geração
    
    func generate() {
        loading = true
        error = nil
        Task { [subject, level, count] in
            defer { loading = false }
            do {
                let generatedItems = try await ai.generateQuestions(subject: subject, level: level, count: count)
                
                // --- CORREÇÃO NA LÓGICA (2/2) ---
                // Após gerar, ativamos o estado de quiz.
                resetQuizStateForNewGame()
                self.items = generatedItems
                self.isQuizActive = true // <-- LIGA O MODO QUIZ
                
            } catch {
                self.error = (error as? AppError) ?? .unknown
            }
        }
    }
    
    // --- ADICIONE ESTA FUNÇÃO DE VOLTA ---
    // Função chamada quando o usuário seleciona uma opção.
    func selectOption(_ option: AIOption) {
        // Permite selecionar uma opção apenas se a resposta ainda não foi submetida.
        if !isAnswerSubmitted {
            selectedOptionID = option.id
        }
    }
    
    // Funções de Controle do Quiz...
    func submitAnswer() {
        guard let question = currentQuestion, let selectedID = selectedOptionID else { return }
        isAnswerSubmitted = true
        let selectedIndex = question.options.firstIndex { $0.id == selectedID }
        if selectedIndex == question.correctAnswerIndex {
            correctAnswersCount += 1
        }
    }
    
    func nextQuestion() {
        if currentQuestionIndex < items.count - 1 {
            currentQuestionIndex += 1
            selectedOptionID = nil
            isAnswerSubmitted = false
        } else {
            currentQuestionIndex += 1
        }
    }
    
    // Função que reinicia o quiz para voltar ao formulário
    func resetQuiz() {
        items = []
        isQuizActive = false // <-- DESLIGA O MODO QUIZ, VOLTANDO AO FORMULÁRIO
        resetQuizStateForNewGame()
    }
    
    // Função auxiliar para limpar apenas o estado do jogo
    private func resetQuizStateForNewGame() {
        currentQuestionIndex = 0
        selectedOptionID = nil
        isAnswerSubmitted = false
        correctAnswersCount = 0
    }
}
