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
        min(max(value, lowerBound), upperBound)
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
    
    private let daySymbols = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]

    /// Retorna uma Color de uma string hexadecimal. Se a string for inválida ou vazia,
    /// uma cor padrão é usada em vez de causar um crash.
    private func color(from hex: String) -> Color {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        // Se a cor no banco de dados estiver vazia, usa uma cor padrão segura.
        guard !trimmed.isEmpty else { return .secondary }
        return Color(hex: trimmed)
    }

    func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        // Garante que o loading seja desativado, não importa como a função termine.
        defer { isLoading = false }

        do {
            async let subjectsTask: [Subject] = try SupabaseManager.shared.client
                .from("subjects").select().execute().value
            async let sessionsTask: [StudySession] = try SupabaseManager.shared.client
                .from("study_sessions").select().execute().value

            let (subjects, sessions) = try await (subjectsTask, sessionsTask)
            
            // Garante que a tarefa não foi cancelada (pelo usuário saindo da tela)
            // antes de tentarmos atualizar o estado.
            guard !Task.isCancelled else { return }

            processData(subjects: subjects, sessions: sessions)

        } catch {
            errorMessage = "Erro ao buscar dados para estatísticas: \(error.localizedDescription)"
            // Em caso de erro, zera os dados para não mostrar informações antigas.
            subjectPerformances = []
            weeklyDistribution = daySymbols.map { DailyStudy(id: $0, minutes: 0) }
        }
    }

    private func processData(subjects: [Subject], sessions: [StudySession]) {
        // --- Processa o desempenho por matéria ---
        var performances: [SubjectPerformance] = []
        
        // Filtra e sanitiza os dados de entrada para evitar cálculos com valores inesperados.
        let validSessions = sessions.filter { session in
            session.durationMinutes > 0 && session.startTime <= session.endTime
        }

        for subject in subjects {
            let subjectSessions = validSessions.filter { $0.subjectId == subject.id }
            guard !subjectSessions.isEmpty else { continue }

            let totalMinutes = subjectSessions.reduce(0) { $0 + max(0, $1.durationMinutes) }
            let questionsAttempted = subjectSessions.compactMap { $0.questionsAttempted }.reduce(0, +)
            let questionsCorrect = subjectSessions.compactMap { $0.questionsCorrect }.reduce(0, +)

            // Lógica de cálculo de 'accuracy' mais segura.
            let rawAccuracy = questionsAttempted > 0 ? Double(questionsCorrect) / Double(questionsAttempted) : 0.0
            // Garante que o valor de 'accuracy' esteja sempre entre 0.0 e 1.0.
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

        // --- Processa a distribuição de estudo por dia da semana ---
        let calendar = Calendar.current
        var dailyTotals: [Int: Int] = [:]

        for session in validSessions {
            let weekday = calendar.component(.weekday, from: session.startTime)
            guard (1...7).contains(weekday) else { continue }
            dailyTotals[weekday, default: 0] += session.durationMinutes
        }
        
        // Lógica de mapeamento mais limpa e segura.
        let distribution = daySymbols.enumerated().map { index, symbol in
            DailyStudy(id: symbol, minutes: dailyTotals[index + 1] ?? 0)
        }
        
        self.weeklyDistribution = distribution
    }
}
