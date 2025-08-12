// memo/Features/Reviews/ReviewsView.swift

import SwiftUI

struct ReviewsView: View {
    @StateObject private var viewModel = ReviewsViewModel()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                // A barra de filtros foi movida para dentro do 'header'
                content
            }
            .overlay(alignment: .top) {
                if viewModel.showSuccessBadge {
                    successBadge
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.fetchData()
                }
            }
            .sheet(isPresented: $viewModel.showingCustomDifficultySelector) {
                if let review = viewModel.reviewToComplete {
                    CustomReviewConfirmationDialogView(
                        viewModel: viewModel,
                        subjectName: review.subjectData.name
                    )
                    .presentationDetents([.fraction(0.50), .medium])
                }
            }
        }
    }

    // MARK: - Subviews
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Título e botão de recarregar
            HStack {
                Text("Revisões Pendentes")
                    .font(.largeTitle.bold())
                Spacer()
                Button(action: { Task { await viewModel.fetchData() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                }
                .tint(.dsPrimary)
            }
            Text("Reveja as matérias programadas e mantenha seu progresso em dia.")
                .font(.subheadline)
                .foregroundColor(.dsTextSecondary)

            // NOVO MENU DE FILTRO
            Menu {
                Picker("Filtrar por", selection: $viewModel.selectedFilter) {
                    ForEach(ReviewsViewModel.FilterType.allCases, id: \.self) { filter in
                        Label(filter.rawValue, systemImage: filter.systemImage)
                            .tag(filter)
                    }
                }
            } label: {
                // O "botão grande" que você pediu
                HStack {
                    Label(viewModel.selectedFilter.rawValue, systemImage: viewModel.selectedFilter.systemImage)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                }
                .font(.headline)
                .padding()
                .background(Color.dsSecondaryBackground)
                .foregroundColor(.dsTextPrimary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .sensoryFeedback(.selection, trigger: viewModel.selectedFilter)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Spacer()
        } else if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView("Erro ao Carregar", systemImage: "wifi.exclamationmark", description: Text(errorMessage))
        } else if viewModel.filteredReviews.isEmpty {
            // Usando o novo EmptyState
            EmptyState()
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.filteredReviews) { detail in
                        ReviewRowView(viewModel: viewModel, detail: detail)
                    }
                }
                .padding()
            }
        }
    }

    private var successBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Revisão concluída!")
                .fontWeight(.semibold)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(.thinMaterial, in: Capsule())
        .padding(.top, 8)
    }
}
