import Foundation

enum AppError: LocalizedError, Equatable {
    // Casos de erro
    case network(String)
    case decoding
    case storeKit(String)      // Será usado no futuro com as assinaturas
    case entitlementMissing  // Será usado no futuro com as assinaturas
    case rateLimited
    case cancelled
    case unknown

    // Descrição amigável para cada erro, que pode ser mostrada ao usuário.
    var errorDescription: String? {
        switch self {
        case .network(let msg):
            return msg
        case .decoding:
            return "Falha ao interpretar a resposta do servidor."
        case .storeKit(let msg):
            return msg
        case .entitlementMissing:
            return "Assinatura premium não encontrada."
        case .rateLimited:
            return "Você atingiu o limite de uso diário. Tente novamente amanhã."
        case .cancelled:
            return "Operação cancelada."
        case .unknown:
            return "Ocorreu um erro desconhecido."
        }
    }
}
