//
//  Subject.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 26/05/25.
//

import Foundation
import SwiftUI

// Este é o nosso modelo de dados que corresponde à tabela no Supabase
struct Subject: Identifiable, Codable {
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


// Extensão para permitir que a cor seja inicializada a partir de um código hexadecimal
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
