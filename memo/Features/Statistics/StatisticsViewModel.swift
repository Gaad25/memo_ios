//
//  StatisticsViewModel.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 13/07/25.
//
// memo/Features/Statistics/StatisticsViewModel.swift

// memo/Features/Statistics/StatisticsViewModel.swift

import Foundation
import SwiftUI
import Combine

// Helper para "prender" um valor dentro de um intervalo.
private extension ClosedRange where Bound == Double {
    /// Clamps a value to be inside the closed range.
    func clamped(_ value: Double) -> Double {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}

// Estrutura de dados para o gráfico de desempenho por matéria
struct SubjectPerformance: Identifiable {
    let id: UUID
    let name: String
    let color: Color
    let totalMinutes: Int
    let accuracy: Double // Valor de 0.0 a 1.0
}

// Estrutura de dados para o gráfico de distribuição semanal
struct DailyStudy: Identifiable {
    let id: String // Nome do dia da semana (Ex: "Seg")
    var minutes: Int
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var subjectPerformances: [SubjectPerformance] = []
    @Published var weeklyDistribution: [DailyStudy] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    /// Referência para a tarefa de busca de dados em andamento.
    private var fetchTask: Task<Void, Never>?
    private let daySymbols = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]

    /// Garante que a tarefa seja cancelada se o ViewModel for destruído.
    deinit {
        fetchTask?.cancel()
    }

    /// Inicia a busca assíncrona. Qualquer tarefa anterior é cancelada.
    func startFetching() {
        fetchTask?.cancel()
        fetchTask = Task {
            await fetchData()
        }
    }

    /// Cancela a tarefa de busca atual.
    func cancelFetching() {
        fetchTask?.cancel()
    }

    private func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }

        do {
            async let subjectsTask: [Subject] = try SupabaseManager.shared.client.from("subjects").select().execute().value
            async let sessionsTask: [StudySession] = try SupabaseManager.shared.client.from("study_sessions").select().execute().value

            let (subjects, sessions) = try await (subjectsTask, sessionsTask)
            
            // Verifica se a tarefa foi cancelada antes de atualizar o estado
            guard !Task.isCancelled else { return }

            processData(subjects: subjects, sessions: sessions)

        } catch is CancellationError {
            // Se o erro for de cancelamento, é esperado. Apenas saia da função.
            print("Fetch task for Statistics was cancelled.")
            return
        } catch {
            errorMessage = "Não foi possível carregar as estatísticas."
            print("❌ Erro em fetchData (StatisticsViewModel): \(error.localizedDescription)")
        }
    }

    /// Retorna uma Color de uma string hexadecimal de forma segura.
    private func color(from hex: String) -> Color {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .secondary }
        return Color(hex: trimmed)
    }

    private func processData(subjects: [Subject], sessions: [StudySession]) {
        var performances: [SubjectPerformance] = []
        
        let validSessions = sessions.filter { session in
            session.durationMinutes > 0 && session.startTime <= session.endTime
        }

        for subject in subjects {
            let subjectSessions = validSessions.filter { $0.subjectId == subject.id }
            guard !subjectSessions.isEmpty else { continue }

            let totalMinutes = subjectSessions.reduce(0) { $0 + Swift.max(0, $1.durationMinutes) }
            let questionsAttempted = subjectSessions.compactMap { $0.questionsAttempted }.reduce(0, +)
            let questionsCorrect = subjectSessions.compactMap { $0.questionsCorrect }.reduce(0, +)

            let rawAccuracy = questionsAttempted > 0 ? Double(questionsCorrect) / Double(questionsAttempted) : 0.0
            let accuracy = (0.0...1.0).clamped(rawAccuracy)

            performances.append(SubjectPerformance(
                id: subject.id,
                name: subject.name,
                color: color(from: subject.color),
                totalMinutes: totalMinutes,
                accuracy: accuracy
            ))
        }
        self.subjectPerformances = performances.sorted { $0.totalMinutes > $1.totalMinutes }

        let calendar = Calendar.current
        var dailyTotals: [Int: Int] = [:]

        for session in validSessions {
            let weekday = calendar.component(.weekday, from: session.startTime)
            guard (1...7).contains(weekday) else { continue }
            dailyTotals[weekday, default: 0] += session.durationMinutes
        }
        
        let distribution = daySymbols.enumerated().map { index, symbol in
            DailyStudy(id: symbol, minutes: dailyTotals[index + 1] ?? 0)
        }
        
        self.weeklyDistribution = distribution
    }
}
