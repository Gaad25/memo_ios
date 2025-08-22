import Foundation
import SwiftUI

@MainActor
final class RankingViewModel: ObservableObject {
    @Published var ranking: [RankedUser] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUserPosition: Int?
    @Published var currentUserId: UUID?
    @Published var currentUserProfile: UserProfile?
    @Published var currentUserWeeklyPoints: Int = 0
    @Published var hasLoadedData: Bool = false
    
    init() {}
    
    /// Busca o ranking semanal da view criada no Supabase
    func fetchRanking() async {
        // Previne múltiplas execuções simultâneas
        guard !isLoading else { return }
        
        isLoading = true
        // Usa defer para garantir que isLoading seja sempre definido como false no final
        defer { isLoading = false }
        
        do {
            // Busca dados para variáveis locais (busca atômica)
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            // Buscar perfil do usuário atual
            let userProfileResponse: [UserProfile] = try await SupabaseManager.shared.client
                .from("user_profiles")
                .select("*")
                .eq("id", value: userId)
                .execute()
                .value
            
            // Buscar dados do ranking da view weekly_ranking
            let fetchedRanking: [RankedUser] = try await SupabaseManager.shared.client
                .from("weekly_ranking")
                .select("*")
                .execute()
                .value
            
            // Preparar dados localmente antes de atualizar a UI
            let fetchedUserProfile = userProfileResponse.first
            let fetchedUserWeeklyPoints = fetchedUserProfile?.weeklyPoints ?? 0
            
            // Calcular posição do usuário atual
            let fetchedUserPosition: Int?
            if let userIndex = fetchedRanking.firstIndex(where: { $0.id == userId }) {
                fetchedUserPosition = userIndex + 1 // +1 porque arrays começam em 0
            } else {
                // Se não encontrou no ranking, calcular posição baseada nos pontos
                let usersWithMorePoints = fetchedRanking.filter { $0.weeklyPoints > fetchedUserWeeklyPoints }
                fetchedUserPosition = usersWithMorePoints.count + 1
            }
            
            // Atualização segura: apenas no final, atualize a UI de uma só vez no MainActor
            await MainActor.run {
                self.ranking = fetchedRanking
                self.currentUserId = userId
                self.currentUserProfile = fetchedUserProfile
                self.currentUserWeeklyPoints = fetchedUserWeeklyPoints
                self.currentUserPosition = fetchedUserPosition
                self.errorMessage = nil
                self.hasLoadedData = true
            }
            
        } catch {
            // Lidar com erro de forma segura no MainActor
            await MainActor.run {
                self.errorMessage = "Erro ao carregar ranking: \(error.localizedDescription)"
            }
            print("❌ Erro ao buscar ranking: \(error)")
        }
    }
    
    /// Atualiza o ranking (usado pelo pull-to-refresh)
    func refreshRanking() async {
        // Função simplificada: apenas chama a função de busca principal
        await fetchRanking()
    }
    
    /// Busca o ranking apenas se necessário (evita cancelamentos desnecessários)
    func fetchRankingIfNeeded() async {
        // Não busca se já estiver carregando ou se já tiver dados carregados
        guard !isLoading && !hasLoadedData else { return }
        
        await fetchRanking()
    }
    
    /// Verifica se o usuário está nos top 3
    func isUserInTop3() -> Bool {
        guard let position = currentUserPosition else { return false }
        return position <= 3
    }
    
    /// Retorna o emoji correspondente à posição
    func emojiForPosition(_ position: Int) -> String {
        switch position {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(position)º"
        }
    }
    
    /// Retorna a cor correspondente à posição
    func colorForPosition(_ position: Int) -> Color {
        switch position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .clear
        }
    }
    
    /// Formata os pontos com separador de milhares
    func formattedPoints(_ points: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: points)) ?? "\(points)"
    }
}
