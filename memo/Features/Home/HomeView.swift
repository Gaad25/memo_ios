import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel.shared
    @State private var isAddingSubject = false
    @State private var isAddingGoal = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    Text(viewModel.greeting)
                        .font(.largeTitle.bold())
                        .padding(.top)

                    SummaryCard(
                        data: SummaryCardData(
                            total: viewModel.formatted(hoursAndMinutes: viewModel.totalStudyMinutes),
                            activeGoals: viewModel.goals.count,
                            recent: viewModel.formatted(hoursAndMinutes: viewModel.recentStudyMinutes),
                            points: viewModel.userPoints,
                            streak: viewModel.userStreak
                        ),
                        onRefresh: {
                            Task { await viewModel.refreshAllDashboardData() }
                        }
                    )
                    .equatable()

                    SectionHeader(title: "Matérias") { isAddingSubject = true }

                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else if viewModel.subjects.isEmpty {
                        Text("Nenhuma matéria cadastrada.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(CardBackground())
                    } else {
                        List {
                            ForEach(viewModel.subjects) { subject in
                                NavigationLink {
                                    SubjectDetailView(subject: subject, onSubjectUpdated: {
                                        Task { await viewModel.refreshAllDashboardData() }
                                    })
                                } label: {
                                    SubjectRow(subject: subject)
                                        .equatable()
                                }
                            }
                            .onDelete(perform: viewModel.deleteSubject)
                        }
                        .listStyle(.plain)
                        .frame(height: CGFloat(viewModel.subjects.count) * 65)
                        .background(CardBackground())
                    }

                    SectionHeader(title: "Metas de Estudo") { isAddingGoal = true }

                    if viewModel.goals.isEmpty && !viewModel.isLoading {
                        Text("Nenhuma meta ativa.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(CardBackground())
                    } else {
                        List {
                            ForEach(viewModel.goals) { goal in
                                GoalCard(goal: goal)
                                    .equatable()
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: viewModel.deleteGoal)
                        }
                        .listStyle(.plain)
                        .frame(height: CGFloat(viewModel.goals.count) * 110)
                        .scrollDisabled(true)
                        .background(CardBackground())
                    }
                }
                .padding(.horizontal)
            }
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
}

struct SummaryCardData: Equatable {
    let total: String
    let activeGoals: Int
    let recent: String
    let points: Int
    let streak: Int
}

struct SummaryCard: View, Equatable {
    let data: SummaryCardData
    var onRefresh: () -> Void

    static func == (lhs: SummaryCard, rhs: SummaryCard) -> Bool {
        lhs.data == rhs.data
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").foregroundColor(.yellow)
                    Text("\(data.points)")
                        .font(.system(.headline, design: .rounded).bold())
                    Text("Pontos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").foregroundColor(.orange)
                    Text("\(data.streak)")
                        .font(.system(.headline, design: .rounded).bold())
                    Text(data.streak == 1 ? "Dia" : "Dias")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 8)
            Divider()
            VStack(spacing: 6) {
                Text(data.total)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Tempo Total de Estudo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Button(action: onRefresh) {
                Label("Atualizar Dados", systemImage: "arrow.clockwise")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(data.activeGoals) Metas Ativas")
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(data.recent)
                        .fontWeight(.semibold)
                    Text("Progresso Recente")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(CardBackground())
    }
}

struct GoalCard: View, Equatable {
    let goal: StudyGoalViewData

    static func == (lhs: GoalCard, rhs: GoalCard) -> Bool {
        lhs.goal == rhs.goal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(goal.title)
                .fontWeight(.semibold)
            if let subjectName = goal.subjectName {
                Text(subjectName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: goal.progress)
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
    }
}

struct SectionHeader: View {
    let title: String
    var action: () -> Void
    var body: some View {
        HStack {
            Text(title)
                .font(.title3.bold())
            Spacer()
            Button("+ NOVA \(title.uppercased().split(separator: " ").first ?? "")", action: action)
                .font(.callout.weight(.semibold))
        }
    }
}

struct SubjectRow: View, Equatable {
    let subject: Subject

    static func == (lhs: SubjectRow, rhs: SubjectRow) -> Bool {
        lhs.subject == rhs.subject
    }

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(subject.swiftUIColor)
                .frame(width: 16, height: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(subject.name)
                    .fontWeight(.semibold)
                Text(subject.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

struct CardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(uiColor: .systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.secondary.opacity(0.1))
            )
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(SessionManager())
    }
}


