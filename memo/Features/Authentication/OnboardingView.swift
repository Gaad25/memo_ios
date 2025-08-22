import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    
    @State private var currentPage = 0
    private let totalPages = 3
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            HStack {
                ForEach(0..<totalPages, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentPage ? Color.dsPrimary : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            TabView(selection: $currentPage) {
                // Página 1: Bem-vindo
                OnboardingPageView(
                    image: "onboarding_welcome",
                    title: "Bem-vindo ao Memo",
                    subtitle: "Organize seus estudos e maximize seu aprendizado",
                    description: "O Memo ajuda você a acompanhar seus estudos, criar sessões de estudo eficazes e competir com amigos."
                )
                .tag(0)
                
                // Página 2: Organização
                OnboardingPageView(
                    image: "onboarding_organize",
                    title: "Organize seus Estudos",
                    subtitle: "Crie matérias, defina metas e acompanhe seu progresso",
                    description: "Mantenha-se focado com sessões cronometradas, metas personalizadas e um sistema de pontuação motivador."
                )
                .tag(1)
                
                // Página 3: Progresso
                OnboardingPageView(
                    image: "onboarding_progress",
                    title: "Acompanhe seu Progresso",
                    subtitle: "Veja suas estatísticas e compete no ranking semanal",
                    description: "Monitore seu desempenho, ganhe pontos por cada sessão e suba no ranking com seus amigos."
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Botões de navegação
            HStack {
                if currentPage > 0 {
                    Button("Anterior") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage -= 1
                        }
                    }
                    .foregroundColor(.dsPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer()
                }
                
                Button(currentPage == totalPages - 1 ? "Começar a Usar" : "Próximo") {
                    if currentPage == totalPages - 1 {
                        onFinish()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.dsPrimary)
                .cornerRadius(25)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
}

struct OnboardingPageView: View {
    let image: String
    let title: String
    let subtitle: String
    let description: String
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Imagem principal
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280, maxHeight: 280)
                .padding(.horizontal, 20)
            
            // Conteúdo textual
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.dsPrimary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    OnboardingView(onFinish: {
        print("Onboarding concluído")
    })
}
