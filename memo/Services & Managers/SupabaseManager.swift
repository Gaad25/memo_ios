//
//  SupabaseManager.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 16/04/25.
import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        guard let keysURL = Bundle.main.url(forResource: "Supabase-Keys", withExtension: "plist"),
              let keys = NSDictionary(contentsOf: keysURL),
              let supabaseURLString = keys["SUPABASE_URL"] as? String,
              let supabaseURL = URL(string: supabaseURLString),
              let supabaseKey = keys["SUPABASE_KEY"] as? String else {
            
            fatalError("ERRO CRÍTICO: Arquivo 'Supabase-Keys.plist' não encontrado ou chaves inválidas.")
        }
        
        // Inicialização padrão e limpa do cliente.
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}
