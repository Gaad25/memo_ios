import Foundation
import Supabase
// Não é necessário importar o ConfidentialKit aqui

class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient

    private init() {
        // A forma CORRETA de aceder ao valor é usando o '$'
        guard let supabaseURL = URL(string: Secrets.$supabaseURL) else {
            fatalError("URL do Supabase inválida.")
        }
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: Secrets.$supabaseKey // Usando o '$' aqui também
        )
    }
}
