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

    func fetchData() async {
        isLoading = true
        errorMessage = nil

        do {
            // CORREÇÃO: A forma correta de usar async let com Supabase é aguardar a propriedade .value.
            // A tipagem explícita [Subject] e [StudySession] também ajuda a evitar erros.
            async let subjectsTask: [Subject] = try SupabaseManager.shared.client.from("subjects").select().execute().value
            async let sessionsTask: [StudySession] = try SupabaseManager.shared.client.from("study_sessions").select().execute().value

            // Agora aguardamos as tarefas em paralelo.
            let (subjects, sessions) = try await (subjectsTask, sessionsTask)

            processData(subjects: subjects, sessions: sessions)

        } catch {
            errorMessage = "Erro ao buscar dados para estatísticas: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func processData(subjects: [Subject], sessions: [StudySession]) {
        // --- Processa o desempenho por matéria ---
        var performances: [SubjectPerformance] = []

        // Filtra sessões inválidas para evitar valores inesperados no gráfico
        let validSessions = sessions.filter { session in
            session.durationMinutes > 0 && session.startTime <= session.endTime
        }

        for subject in subjects {
            let subjectSessions = validSessions.filter { $0.subjectId == subject.id }
            guard !subjectSessions.isEmpty else { continue }

            let totalMinutes = subjectSessions.reduce(0) { $0 + $1.durationMinutes }
            let questionsAttempted = subjectSessions.compactMap { $0.questionsAttempted }.reduce(0, +)
            let questionsCorrect = subjectSessions.compactMap { $0.questionsCorrect }.reduce(0, +)

            let accuracy = questionsAttempted > 0 ? Double(questionsCorrect) / Double(questionsAttempted) : 0.0

            performances.append(SubjectPerformance(
                id: subject.id,
                name: subject.name,
                color: Color(hex: subject.color),
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
            dailyTotals[weekday, default: 0] += session.durationMinutes
        }

        // CORREÇÃO: A variável 'distribution' não era modificada, então foi alterada para 'let'.
        let distribution = [
            DailyStudy(id: "Dom", minutes: dailyTotals[1] ?? 0),
            DailyStudy(id: "Seg", minutes: dailyTotals[2] ?? 0),
            DailyStudy(id: "Ter", minutes: dailyTotals[3] ?? 0),
            DailyStudy(id: "Qua", minutes: dailyTotals[4] ?? 0),
            DailyStudy(id: "Qui", minutes: dailyTotals[5] ?? 0),
            DailyStudy(id: "Sex", minutes: dailyTotals[6] ?? 0),
            DailyStudy(id: "Sáb", minutes: dailyTotals[7] ?? 0)
        ]
        
        self.weeklyDistribution = distribution
    }
}
