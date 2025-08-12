// memo/Features/Sessions/SessionRowView.swift

import SwiftUI

struct SessionRowView: View {
    let session: StudySession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Cabeçalho com Data
            HStack {
                Image(systemName: "calendar")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Text(session.startTime, style: .date)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: "timer")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Text("\(session.durationMinutes) min")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            // MARK: - Anotações (se existirem)
            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundColor(.dsTextSecondary)
            }
            
            // MARK: - Estatísticas de Questões (se existirem)
            if let attempted = session.questionsAttempted, let correct = session.questionsCorrect, attempted > 0 {
                Divider()
                HStack(spacing: 16) {
                    Spacer()
                    StatItem(value: "\(correct)", label: "Acertos")
                    Divider().frame(height: 30)
                    StatItem(value: "\(attempted)", label: "Tentativas")
                    Divider().frame(height: 30)
                    StatItem(value: "\(Int((Double(correct) / Double(attempted)) * 100))%", label: "Aproveitamento")
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .modifier(CardBackgroundModifier()) // <-- Usando o nosso estilo de card!
    }
}

// Subview para os itens de estatística
private struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.dsPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(.dsTextSecondary)
        }
    }
}
