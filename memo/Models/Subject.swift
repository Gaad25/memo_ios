import Foundation
import SwiftUI

// Este é o nosso modelo de dados que corresponde à tabela no Supabase
struct Subject: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: String
    var color: String // Salvaremos a cor como um código hexadecimal (ex: "#FFFFFF")
    
    // Adicione o user_id para saber a qual usuário a matéria pertence
    // O Supabase preencherá isso automaticamente com base no usuário logado se a política de segurança estiver correta
    let userId: UUID
    
    // Propriedade para converter a string de cor em uma Color do SwiftUI
    var swiftUIColor: Color {
        Color(hex: self.color)
    }
    
    // Para o Supabase, precisamos mapear os nomes das colunas
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case color
        case userId = "user_id"
    }
}

