// memo/Features/Subjects/SubjectDetailView.swift

import SwiftUI

struct SubjectDetailView: View {
    @State var subject: Subject
    
    @StateObject private var viewModel = SubjectDetailViewModel()
    @State private var isPresentingSessionView = false
    @State private var isEditingSubject = false
    
    var onSubjectUpdated: () -> Void

    var body: some View {
        // ZStack permite sobrepor a lista e o botão flutuante
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Card de Resumo da Matéria
                    summaryCard
                        .padding(.top)

                    // MARK: - Cabeçalho do Histórico
                    Text("Histórico de Sessões")
                        .font(.title2.bold())
                    
                    // MARK: - Histórico de Sessões
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 50)
                    } else if viewModel.sessions.isEmpty {
                        EmptyStateView(
                            systemImageName: "clock.arrow.circlepath",
                            message: "Nenhuma sessão de estudo registrada para esta matéria."
                        )
                        .padding(.top, 30)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(viewModel.sessions) { session in
                                SessionRowView(session: session)
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 100) // Espaço extra para não ser coberto pelo botão
            }
            
            // MARK: - Botão Flutuante
            Button {
                isPresentingSessionView = true
            } label: {
                Label("Iniciar Sessão de Estudo", systemImage: "play.fill")
                    .font(.headline.weight(.bold))
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .tint(subject.swiftUIColor) // Usa a cor da matéria
            .padding()
            .background(.thinMaterial) // Efeito de desfoque para se destacar
        }
        .background(Color.dsBackground.ignoresSafeArea())
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { isEditingSubject = true } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $isPresentingSessionView) {
            Task { await viewModel.fetchSessions(for: subject.id) }
        } content: {
            StudySessionView(subject: subject)
        }
        .sheet(isPresented: $isEditingSubject) {
            AddSubjectView(subjectToEdit: subject, onDone: {
                self.isEditingSubject = false
                self.onSubjectUpdated()
            })
        }
        .onAppear {
            Task { await viewModel.fetchSessions(for: subject.id) }
        }
    }
    
    // MARK: - Subviews
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StatItem(value: "\(viewModel.sessions.count)", label: "Sessões")
                Spacer()
                StatItem(value: totalStudyTime, label: "Tempo Total")
                Spacer()
                StatItem(value: averageScore, label: "Aproveitamento")
            }
        }
        .modifier(CardBackgroundModifier())
    }
    
    // Propriedades computadas para as estatísticas
    private var totalStudyTime: String {
        let totalMinutes = viewModel.sessions.reduce(0) { $0 + $1.durationMinutes }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
    
    private var averageScore: String {
        let sessionsWithQuestions = viewModel.sessions.filter { ($0.questionsAttempted ?? 0) > 0 }
        guard !sessionsWithQuestions.isEmpty else { return "--" }
        
        let totalCorrect = sessionsWithQuestions.reduce(0) { $0 + ($1.questionsCorrect ?? 0) }
        let totalAttempted = sessionsWithQuestions.reduce(0) { $0 + ($1.questionsAttempted ?? 0) }
        
        let percentage = (Double(totalCorrect) / Double(totalAttempted)) * 100
        return "\(Int(percentage))%"
    }
}


// Subview para os itens de estatística (pode ser movida para o DesignSystem se quiser reutilizar)
private struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title.bold())
                .foregroundColor(.dsPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(.dsTextSecondary)
        }
    }
}
