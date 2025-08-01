//
//  ReviewListRow.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 31/07/25.
//

import SwiftUI

struct ReviewListRow: View {
    // A linha precisa dos detalhes da revisão para exibir
    let detail: ReviewsViewModel.ReviewDetail
    
    // E de uma "ação" para executar quando o botão "Concluir" for tocado
    let onComplete: () -> Void

    var body: some View {
        // A ReviewRowView agora é usada apenas para a parte visual
        ReviewRowView(detail: detail)
            // A lógica de swipe actions fica contida aqui,
            // junto com a view que ela modifica.
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                    // Quando o botão é tocado, ele executa a ação que foi passada.
                    onComplete()
                } label: {
                    Label("Concluir", systemImage: "checkmark.circle.fill")
                }
                .tint(.green)
            }
    }
}

// --- CORREÇÃO ADICIONADA AQUI ---
// Esta seção ensina o Xcode a desenhar uma pré-visualização da sua View.
struct ReviewListRow_Previews: PreviewProvider {
    static var previews: some View {
        // 1. Criamos dados de amostra (mocks)
        let mockSubject = Subject(id: UUID(), name: "Cálculo I", category: "Exatas", color: "#007AFF", userId: UUID())
        
        let mockReview = Review(
            id: UUID(),
            userId: UUID(),
            sessionId: UUID(),
            subjectId: mockSubject.id,
            reviewDate: Date(),
            status: "pending",
            reviewInterval: "1d"
        )
        
        let mockDetail = ReviewsViewModel.ReviewDetail(
            reviewId: mockReview.id,
            reviewData: mockReview,
            subjectData: mockSubject,
            sessionNotes: "Revisar integral dupla e tripla. Focar nos exercícios do capítulo 5."
        )
        
        // 2. Usamos os dados de amostra para criar a View na pré-visualização
        // Para a ação 'onComplete', passamos uma função vazia, pois na preview ela não precisa fazer nada.
        List {
            ReviewListRow(detail: mockDetail, onComplete: {})
        }
    }
}
