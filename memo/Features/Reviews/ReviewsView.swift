import SwiftUI

struct ReviewsView: View {
    @StateObject private var viewModel = ReviewsViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.reviewDetails.isEmpty {
                    // ... (código para a tela vazia, sem alterações)
                    VStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                            .padding(.bottom, 8)
                        Text("Nenhuma revisão pendente!")
                            .font(.headline)
                        Text("Você está em dia com seus estudos.")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        // --- MUDANÇA PRINCIPAL AQUI ---
                        // O ForEach agora é extremamente simples.
                        // Ele apenas cria nossa nova ReviewListRow.
                        ForEach(viewModel.reviewDetails) { detail in
                            ReviewListRow(detail: detail, onComplete: {
                                // A ação de 'onComplete' simplesmente chama o ViewModel.
                                viewModel.startCompletionFlow(for: detail)
                            })
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Revisões Pendentes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await viewModel.fetchData() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchData()
                }
            }
            // O confirmationDialog, que depende do estado do ViewModel,
            // agora funciona de forma confiável pois a View está mais simples.
            .confirmationDialog(
                "Como foi seu desempenho nesta revisão?",
                isPresented: $viewModel.showingDifficultySelector
            ) {
                Button("✅ Fácil") { viewModel.completeReview(with: .facil) }
                Button("🤔 Médio") { viewModel.completeReview(with: .medio) }
                Button("🥵 Difícil") { viewModel.completeReview(with: .dificil) }
                Button("Cancelar", role: .cancel) {
                    viewModel.reviewToComplete = nil
                }
            } message: {
                if let review = viewModel.reviewToComplete {
                    Text("Avaliar revisão de \"\(review.subjectData.name)\"")
                }
            }
        }
    }
}

struct ReviewsView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewsView()
    }
}
