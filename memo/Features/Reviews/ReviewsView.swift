//
//  ReviewsView.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 20/07/25.
//
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
                        ForEach(viewModel.reviewDetails) { detail in
                            ReviewRowView(detail: detail)
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        viewModel.startCompletionFlow(for: detail)
                                    } label: {
                                        Label("Concluir", systemImage: "checkmark.circle.fill")
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Revisões Pendentes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.fetchData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchData()
                }
            }
            // Alerta que pergunta a dificuldade da revisão
            .confirmationDialog(
                "Como foi o seu desempenho nesta revisão?",
                isPresented: $viewModel.showingDifficultySelector,
                presenting: viewModel.reviewToComplete
            ) { _ in
                Button("✅ Fácil") { viewModel.completeReview(with: .facil) }
                Button("🤔 Médio") { viewModel.completeReview(with: .medio) }
                Button("🥵 Difícil") { viewModel.completeReview(with: .dificil) }
                Button("Cancelar", role: .cancel) {}
            } message: { detail in
                Text("Avaliar revisão de \"\(detail.subjectData.name)\"")
            }
        }
    }
}

struct ReviewsView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewsView()
    }
}
