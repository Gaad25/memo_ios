// memo/Features/Home/HomeView.swift

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @State private var isAddingSubject = false
    @State private var isAddingGoal = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    headerView
                    
                    HStack(spacing: 16) {
                        MetricCard(title: "Pontos", value: "\(viewModel.userPoints)", iconName: "star.fill", iconColor: .yellow)
                        MetricCard(title: viewModel.userStreak == 1 ? "Dia de Foco" : "Dias de Foco", value: "\(viewModel.userStreak)", iconName: "flame.fill", iconColor: .orange)
                    }
                    
                    StudyTimeCard(
                        total: viewModel.formatted(hoursAndMinutes: viewModel.totalStudyMinutes),
                        recent: viewModel.formatted(hoursAndMinutes: viewModel.recentStudyMinutes)
                    )
                    
                    VStack(spacing: 16) {
                        SectionHeader(title: "Matérias") { isAddingSubject = true }
                        
                        if viewModel.isLoading {
                            ProgressView().frame(maxWidth: .infinity)
                        } else if viewModel.subjects.isEmpty {
                            EmptyStateView(systemImageName: "books.vertical.fill", message: "Nenhuma matéria registrada. Toque no '+' para começar.")
                        } else {
                            subjectsListView
                        }
                    }

                    VStack(spacing: 16) {
                        SectionHeader(title: "Metas de Estudo") { isAddingGoal = true }

                        if viewModel.isLoading {
                            ProgressView().frame(maxWidth: .infinity)
                        } else if viewModel.goals.isEmpty {
                            EmptyStateView(systemImageName: "target", message: "Nenhuma meta ativa. Defina um objetivo para se manter focado.")
                        } else {
                            goalsListView
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Color.dsBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .refreshable { await viewModel.refreshAllDashboardData() }
            .onAppear { Task { await viewModel.refreshAllDashboardData() } }
            // --- CORREÇÃO AQUI (1/3): AÇÕES DAS SHEETS RESTAURADAS ---
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
            VStack(alignment: .leading) {
                Text(viewModel.greeting)
                    .font(.largeTitle.bold())
                Text("Vamos rever o seu progresso.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.top)
    }

    private var subjectsListView: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.subjects) { subject in
                // --- CORREÇÃO AQUI (2/3): NAVEGAÇÃO E MENU DE CONTEXTO RESTAURADOS ---
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.dsBackground)
                .shadow(color: .white.opacity(0.7), radius: 5, x: -5, y: -5)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 5, y: 5)
        )
    }

    private var goalsListView: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.goals) { goal in
                // --- CORREÇÃO AQUI (3/3): MENU DE CONTEXTO RESTAURADO ---
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
}


// MARK: - Componentes da Home (MetricCard, StudyTimeCard, etc.)
// ... (O código destes componentes que já corrigimos permanece aqui, inalterado)

struct MetricCard: View {
    let title: String, value: String, iconName: String, iconColor: Color

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .padding(12)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(value).font(.title2.bold().monospacedDigit())
                Text(title).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .modifier(CardBackgroundModifier())
    }
}

struct StudyTimeCard: View {
    let total: String, recent: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(total).font(.system(size: 32, weight: .bold, design: .rounded))
            HStack {
                Text("Tempo Total de Estudo").font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("(\(recent) recentes)").font(.caption.bold()).foregroundColor(.secondary)
            }
        }
        .modifier(CardBackgroundModifier())
    }
}

struct GoalCard: View {
    let goal: StudyGoalViewData
    @State private var animatedProgress: Double = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(goal.title).fontWeight(.semibold)
            
            if let subjectName = goal.subjectName {
                Text(subjectName).font(.caption).foregroundColor(.secondary)
            }
            
            ProgressView(value: animatedProgress).progressViewStyle(.linear)
            
            HStack {
                Text("\(goal.completedMinutes / 60)h \(goal.completedMinutes % 60)m de \(goal.targetMinutes / 60)h")
                Spacer()
                Text("Prazo: \(goal.deadline.formatted(date: .abbreviated, time: .omitted))")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .modifier(CardBackgroundModifier())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = goal.progress
            }
        }
    }
}

struct SubjectRow: View {
    let subject: Subject
    
    var body: some View {
        HStack(spacing: 16) {
            Capsule()
                .fill(subject.swiftUIColor)
                .frame(width: 5, height: 35)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(subject.name).fontWeight(.semibold)
                Text(subject.category).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
