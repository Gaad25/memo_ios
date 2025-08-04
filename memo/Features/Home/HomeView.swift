// memo/Features/Home/HomeView.swift

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var isAddingSubject = false
    @State private var isAddingGoal = false
    
    var body: some View {
        NavigationStack {
            // 👇 --- MUDANÇA 2: REMOVEMOS O SCROLLVIEW DAQUI ---
            // O ScrollView será adicionado dentro do .background para que o .refreshable funcione corretamente
            VStack(alignment: .leading, spacing: 20) {
                headerView
                
                HStack(spacing: 16) {
                    MetricCard(
                        title: "Pontos",
                        value: "\(viewModel.userPoints)",
                        iconName: "star.fill",
                        iconColor: .yellow
                    )
                    MetricCard(
                        title: viewModel.userStreak == 1 ? "Dia de Foco" : "Dias de Foco",
                        value: "\(viewModel.userStreak)",
                        iconName: "flame.fill",
                        iconColor: .orange
                    )
                }
                
                StudyTimeCard(
                    total: viewModel.formatted(hoursAndMinutes: viewModel.totalStudyMinutes),
                    recent: viewModel.formatted(hoursAndMinutes: viewModel.recentStudyMinutes)
                )
                
                SectionHeader(title: "Matérias") { isAddingSubject = true }
                
                // O conteúdo que antes estava no ScrollView agora está aqui
                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else if viewModel.subjects.isEmpty {
                    emptyStateView(message: "Nenhuma matéria cadastrada.")
                } else {
                    subjectsListView
                }

                SectionHeader(title: "Metas de Estudo") { isAddingGoal = true }

                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else if viewModel.goals.isEmpty {
                    emptyStateView(message: "Nenhuma meta ativa.")
                } else {
                    goalsListView
                }
                
                Spacer() // Adiciona um spacer para empurrar o conteúdo para cima
            }
            .padding(.horizontal)
            .background(
                // Adicionamos um ScrollView "invisível" no fundo
                ScrollView {
                    Color.clear
                }
                // 👇 --- MUDANÇA 2: ADICIONAMOS O MODIFICADOR .refreshable ---
                .refreshable {
                    await viewModel.refreshAllDashboardData()
                }
            )
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarHidden(true)
            .onAppear { Task { await viewModel.refreshAllDashboardData() } }
            .sheet(isPresented: $isAddingSubject) {
                AddSubjectView(subjectToEdit: nil, onDone: {
                    Task { await viewModel.refreshAllDashboardData() }
                })
            }
            .sheet(isPresented: $isAddingGoal) {
                AddGoalView(subjects: viewModel.subjects) {
                    Task { await viewModel.refreshAllDashboardData() }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text(viewModel.greeting)
                .font(.largeTitle.bold())
            Spacer()
            // 👇 --- MUDANÇA 2: REMOVEMOS O BOTÃO DE ATUALIZAR ---
        }
        .padding(.top)
        .padding(.bottom, 8)
    }

    private var subjectsListView: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.subjects) { subject in
                NavigationLink {
                    SubjectDetailView(subject: subject, onSubjectUpdated: {
                        Task { await viewModel.refreshAllDashboardData() }
                    })
                } label: {
                    SubjectRow(subject: subject)
                }
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.deleteSubject(subject)
                    } label: {
                        Label("Apagar Matéria", systemImage: "trash.fill")
                    }
                }
                
                if subject.id != viewModel.subjects.last?.id {
                    Divider().padding(.leading, 20)
                }
            }
        }
        .background(CardBackground())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var goalsListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.goals) { goal in
                GoalCard(goal: goal)
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.deleteGoal(goal)
                    } label: {
                        Label("Apagar Meta", systemImage: "trash.fill")
                    }
                }
            }
        }
    }

    // ...
    
    private func emptyStateView(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(CardBackground())
    }
}

// MARK: - Novos Cards de Resumo
struct MetricCard: View {
    let title: String
    let value: String
    let iconName: String
    let iconColor: Color

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .padding(12)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(value)
                    .font(.title2.bold().monospacedDigit())
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(CardBackground())
    }
}

struct StudyTimeCard: View {
    let total: String
    let recent: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(total)
                .font(.system(size: 32, weight: .bold, design: .rounded))
            HStack {
                Text("Tempo Total de Estudo")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("(\(recent) recentes)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(CardBackground())
    }
}

// MARK: - Views de Linha e Seção
struct GoalCard: View {
    let goal: StudyGoalViewData
    @State private var animatedProgress: Double = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(goal.title)
                .fontWeight(.semibold)
            if let subjectName = goal.subjectName {
                Text(subjectName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: animatedProgress)
                .progressViewStyle(.linear)
            
            HStack {
                Text("\(goal.completedMinutes / 60)h \(goal.completedMinutes % 60)m de \(goal.targetMinutes / 60)h")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Prazo: \(goal.deadline.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(CardBackground())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = goal.progress
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    var action: () -> Void
    var body: some View {
        HStack {
            Text(title)
                .font(.title2.bold())
            Spacer()
            Button("+ Novo", action: action)
                .font(.callout.weight(.semibold))
                .buttonStyle(.bordered)
                .tint(.secondary)
        }
    }
}

struct SubjectRow: View {
    let subject: Subject
    
    var body: some View {
        HStack(spacing: 16) {
            Capsule()
                .fill(subject.swiftUIColor)
                .frame(width: 5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(subject.name)
                    .fontWeight(.semibold)
                Text(subject.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

// MARK: - Views de Suporte
struct CardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(uiColor: .systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(SessionManager())
            .environmentObject(HomeViewModel.shared)
    }
}
