// memo/Features/AI/AIGeneratorViewModel.swift

import Foundation
import SwiftUI

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
    @Published var fakeProgress: Double = 0.0 // Progresso simulado para melhor UX

    private let ai: AIService

    init(ai: AIService = OpenAIService()) {
        self.ai = ai
    }

    /// Normaliza prompt removendo pontuação, múltiplos espaços e caixa para deduplicação robusta
    private static func normalizePrompt(_ text: String) -> String {
        let lowered = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let stripped = lowered.replacingOccurrences(of: #"[^a-z0-9 ]+"#, with: " ", options: .regularExpression)
        let collapsed = stripped.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    var currentQuestion: AIQuestion? {
        guard items.indices.contains(currentQuestionIndex) else { return nil }
        return items[currentQuestionIndex]
    }
    
    // --- CORREÇÃO NA LÓGICA (1/2) ---
    // isQuizFinished só deve ser verdadeiro se houver itens e o índice estiver no final.
    var isQuizFinished: Bool {
        // Considera concluído quando o usuário respondeu a última questão disponível
        return !items.isEmpty && currentQuestionIndex >= items.count
    }

    var displayTotalCount: Int { items.count }
    var isNextAvailable: Bool { (currentQuestionIndex + 1) < items.count }

    // MARK: - Funções de Geração
    
    func generate() {
        loading = true
        error = nil
        items = []
        resetQuizStateForNewGame()
        
        // Reset e inicia a animação de progresso simulado
        fakeProgress = 0.0
        withAnimation(.linear(duration: 8.0)) {
            fakeProgress = 0.9 // Anima até 90% ao longo de 8 segundos
        }

        currentStreamTask = Task { [subject, level, count] in
            defer { loading = false }
            do {
                // Chamada ÚNICA para gerar o quiz completo
                let generatedItems = try await ai.generateFullQuiz(
                    subject: subject,
                    level: level,
                    count: count
                )
                
                await MainActor.run {
                    self.items = generatedItems
                    
                    // Completa rapidamente a animação para 100%
                    withAnimation(.easeIn(duration: 0.5)) {
                        self.fakeProgress = 1.0
                    }
                    
                    // Pequena pausa para o usuário ver a barra completa antes de navegar
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self.isQuizActive = true
                    }
                    
                    print("✅ Quiz completo gerado: \(generatedItems.count) perguntas")
                }
            } catch {
                await MainActor.run {
                    self.error = (error as? AppError) ?? .unknown
                }
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
        guard isNextAvailable else { 
            // Se não há próxima pergunta disponível mas ainda estamos dentro do total planejado,
            // ativa o estado de carregamento
                    if currentQuestionIndex + 1 < items.count {
            // Não há mais necessidade de estado de loading individual
            }
            return 
        }
        
        if currentQuestionIndex < items.count - 1 {
            currentQuestionIndex += 1
            selectedOptionID = nil
            isAnswerSubmitted = false
        } else {
            currentQuestionIndex += 1
        }
    }

    // MARK: - Report
    func reportCurrentQuestion(reason: String = "Conteúdo inadequado/errado") {
        guard items.indices.contains(currentQuestionIndex) else { return }
        let q = items[currentQuestionIndex]
        // Por simplicidade, apenas log local. Opcional: enviar ao backend (Supabase) via RPC.
        print("[REPORT] Question \(q.id) reported. Reason: \(reason)")
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

    // MARK: - Cancelar streaming
    private var currentStreamTask: Task<Void, Never>? = nil
    func cancelStreaming() {
        currentStreamTask?.cancel()
        // Não há mais streaming individual
        loading = false
    }
}
