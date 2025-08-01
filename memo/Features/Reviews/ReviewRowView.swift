//
//  ReviewRowView.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 20/07/25.
//
import SwiftUI

struct ReviewRowView: View {
    let detail: ReviewsViewModel.ReviewDetail
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(detail.subjectData.name)
                        .font(.headline)
                        .foregroundColor(detail.subjectData.swiftUIColor)
                    
                    Text("Agendado para: \(detail.reviewData.reviewDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Mostra um indicador se houver anotações e permite expandir
                if let notes = detail.sessionNotes, !notes.isEmpty {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            
            // Mostra as anotações se a linha estiver expandida
            if isExpanded, let notes = detail.sessionNotes, !notes.isEmpty {
                VStack(alignment: .leading) {
                    Divider().padding(.vertical, 4)
                    Text("Anotações da Sessão Original:")
                        .font(.caption.bold())
                    Text(notes)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Garante que toda a área da célula seja tocável
        .onTapGesture {
            // Só permite expandir se houver anotações
            if let notes = detail.sessionNotes, !notes.isEmpty {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
        }
    }
}
