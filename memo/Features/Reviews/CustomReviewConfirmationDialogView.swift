// memo/Features/Reviews/CustomReviewConfirmationDialogView.swift

import SwiftUI

struct CustomReviewConfirmationDialogView: View {
    @ObservedObject var viewModel: ReviewsViewModel
    let subjectName: String

    var body: some View {
        VStack(spacing: 24) {
            Text("Avalie a sua Revisão")
                .font(.title2.bold())
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("Como se sentiu ao rever \"\(subjectName)\"?")
                .font(.subheadline)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                Button("Fácil") {
                    viewModel.completeReview(with: .facil)
                    viewModel.showingCustomDifficultySelector = false
                }
                .buttonStyle(CustomDifficultyButtonStyle(backgroundColor: .green.opacity(0.15), textColor: .green))

                Button("Médio") {
                    viewModel.completeReview(with: .medio)
                    viewModel.showingCustomDifficultySelector = false
                }
                .buttonStyle(CustomDifficultyButtonStyle(backgroundColor: .orange.opacity(0.15), textColor: .orange))

                Button("Difícil") {
                    viewModel.completeReview(with: .dificil)
                    viewModel.showingCustomDifficultySelector = false
                }
                .buttonStyle(CustomDifficultyButtonStyle(backgroundColor: .red.opacity(0.15), textColor: .red))
            }

            Button(role: .cancel) {
                viewModel.showingCustomDifficultySelector = false
                viewModel.reviewToComplete = nil
            } label: {
                Text("Cancelar")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .tint(.secondary)
            .buttonStyle(.borderless)
        }
        .padding(32)
        .modifier(CardBackgroundModifier())
        .padding(.horizontal, 24)
    }
}

// --- CORREÇÃO AQUI ---
// Adicionamos a struct do estilo de botão que estava em falta.
struct CustomDifficultyButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let textColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
// --------------------

// Adicionamos novamente a PreviewProvider para que o arquivo fique completo e funcional.
struct CustomReviewConfirmationDialogView_Previews: PreviewProvider {
    static let mockViewModel: ReviewsViewModel = {
        let vm = ReviewsViewModel()
        
        // Dados mock para a preview
        let mockSubject = Subject(id: UUID(), name: "História", category: "Humanas", color: "#A020F0", userId: UUID())
        let mockReview = Review(id: UUID(), userId: UUID(), sessionId: UUID(), subjectId: mockSubject.id, reviewDate: Date(), status: "pending", reviewInterval: "3d")
        
        vm.reviewToComplete = ReviewsViewModel.ReviewDetail(reviewData: mockReview, subjectData: mockSubject, sessionNotes: "Revisar a Era Vargas.")
        return vm
    }()

    static var previews: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()
            CustomReviewConfirmationDialogView(viewModel: mockViewModel, subjectName: "História")
        }
    }
}
