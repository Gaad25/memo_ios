//
//  ReviewRowView.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 20/07/25.
//

import SwiftUI

struct ReviewRowView: View {
    // A view agora recebe o ViewModel e o detalhe da revisão
    @ObservedObject var viewModel: ReviewsViewModel
    let detail: ReviewsViewModel.ReviewDetail
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // --- CABEÇALHO DO CARD ---
            HStack(spacing: 16) {
                Capsule()
                    .fill(detail.subjectData.swiftUIColor)
                    .frame(width: 5)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(detail.subjectData.name)
                        .font(.headline)
                    
                    Text("Revisão de \(detail.reviewData.reviewInterval)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Agendada para: \(detail.reviewData.reviewDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Botão para expandir/recolher as anotações
                if let notes = detail.sessionNotes, !notes.isEmpty {
                    Button(action: {
                        withAnimation(.spring()) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "note.text")
                            .font(.title2)
                            .foregroundColor(isExpanded ? .blue : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()

            // --- SEÇÃO DE NOTAS (EXPANSÍVEL) ---
            if isExpanded, let notes = detail.sessionNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    Text("Anotações da Sessão Original:")
                        .font(.caption.bold())
                        .padding(.horizontal)
                    Text(notes)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            
            // --- BOTÃO DE AÇÃO ---
            Divider()
            Button(action: {
                viewModel.startCompletionFlow(for: detail)
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                    Text("Concluir Revisão")
                    Spacer()
                }
            }
            .padding()
            .background(Color.green.opacity(0.1)) // Fundo sutil para o botão
        }
        .background(CardBackground()) // Reutilizando nosso estilo de card
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
