import SwiftUI

struct SubjectDetailView: View {
    // @State para que a view possa atualizar se a matéria mudar
    @State var subject: Subject
    
    @StateObject private var viewModel = SubjectDetailViewModel()
    @State private var isPresentingSessionView = false
    @State private var isEditingSubject = false
    
    // Callback para notificar a HomeView que precisa recarregar
    var onSubjectUpdated: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                Button(action: {
                    isPresentingSessionView = true
                }) {
                    Label("Iniciar Sessão de Estudo", systemImage: "play.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(subject.swiftUIColor) // Use a cor do @State subject
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top)

                Text("Histórico de Sessões")
                    .font(.title2.bold())
                
                if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                } else if viewModel.sessions.isEmpty {
                    Text("Nenhuma sessão registrada.").foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemBackground)))
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.sessions) { session in
                            SessionRowView(session: session)
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle(subject.name) // O título usará o @State subject
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Editar") {
                    isEditingSubject = true
                }
            }
        }
        .sheet(isPresented: $isPresentingSessionView, onDismiss: {
            Task { await viewModel.fetchSessions(for: subject.id) }
        }) {
            StudySessionView(subject: subject)
        }
        .sheet(isPresented: $isEditingSubject) {
            // Apresenta AddSubjectView para edição
            AddSubjectView(subjectToEdit: subject, onDone: {
                // Este onDone será chamado pela AddSubjectView
                self.isEditingSubject = false // Fecha a sheet
                self.onSubjectUpdated()      // Chama o callback para HomeView
            })
        }
        .onAppear {
            Task { await viewModel.fetchSessions(for: subject.id) }
        }
    }
}

struct SubjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Crie uma instância mock do Subject para a preview
        let mockSubject = Subject(
            id: UUID(),
            name: "Matemática",
            category: "Exatas",
            color: "#007AFF", // Use um código hexadecimal para a cor
            userId: UUID()    // Forneça um UUID mock para o userId
        )
        
        // Envolve em uma NavigationStack para a preview do título
        NavigationStack {
            SubjectDetailView(
                subject: mockSubject,
                onSubjectUpdated: {
                    print("Preview: onSubjectUpdated foi chamado!")
                }
            )
        }
    }
}
