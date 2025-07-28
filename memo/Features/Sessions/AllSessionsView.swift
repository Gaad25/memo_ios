//
//  AllSessionsView.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 13/07/25.
//

import SwiftUI

struct AllSessionsView: View {
    @StateObject private var viewModel = AllSessionsViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.sessions.isEmpty {
                    Text("Nenhuma sessão de estudo encontrada.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.sessions) { session in
                            SessionRowView(session: session)
                        }
                        .onDelete(perform: viewModel.deleteSession)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Todas as Sessões")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Ordenar por", selection: $viewModel.sortOption) {
                            Text("Mais Recentes").tag(AllSessionsViewModel.SortOption.dateDescending)
                            Text("Mais Antigas").tag(AllSessionsViewModel.SortOption.dateAscending)
                            Text("Maior Duração").tag(AllSessionsViewModel.SortOption.durationDescending)
                            Text("Menor Duração").tag(AllSessionsViewModel.SortOption.durationAscending)
                        }
                        .pickerStyle(.inline)


                        Picker("Filtrar por Matéria", selection: $viewModel.selectedSubjectId) {
                           Text("Todas as Matérias").tag(UUID?.none)
                           ForEach(viewModel.subjects) { subject in
                               Text(subject.name).tag(UUID?.some(subject.id))
                           }
                       }
                       .pickerStyle(.inline)


                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchAllData()
                }
            }
        }
    }
}

struct AllSessionsView_Previews: PreviewProvider {
    static var previews: some View {
        AllSessionsView()
    }
}
