// memo/Features/Reviews/ReviewsView.swift

import SwiftUI

struct ReviewsView: View {
    @StateObject private var viewModel = ReviewsViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 50)
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else if viewModel.reviewDetails.isEmpty {
                        // --- EMPTY STATE ESTILIZADO ---
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            Text("Nenhuma revisão pendente!")
                                .font(.headline)
                            Text("Você está em dia com seus estudos.")
                                .foregroundColor(.secondary)
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity)
                        .background(CardBackground())
                        .padding(.top, 30)
                        
                    } else {
                        // --- LISTA DE CARDS ---
                        ForEach(viewModel.reviewDetails) { detail in
                            ReviewRowView(viewModel: viewModel, detail: detail)
                        }
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
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
            // 👇 O .confirmationDialog antigo foi removido e substituído por este .sheet
            .sheet(isPresented: $viewModel.showingCustomDifficultySelector) {
                if let review = viewModel.reviewToComplete {
                    CustomReviewConfirmationDialogView(
                        viewModel: viewModel,
                        subjectName: review.subjectData.name
                    )
                    // Define uma altura que se ajusta ao conteúdo, ideal para diálogos
                    .presentationDetents([.fraction(0.50), .medium])
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
