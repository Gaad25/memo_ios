//
//  SessionRowView.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 26/05/25.
//

import SwiftUI

struct SessionRowView: View {
    let session: StudySession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Formata a data para ser mais amigável
                Text(session.startTime, style: .date)
                    .fontWeight(.bold)
                Text("Duração: \(session.durationMinutes) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
            
            // Mostra o desempenho em questões, se houver
            if let attempted = session.questionsAttempted, let correct = session.questionsCorrect, attempted > 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(correct)/\(attempted)")
                        .fontWeight(.semibold)
                    Text("Acertos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
    }
}
