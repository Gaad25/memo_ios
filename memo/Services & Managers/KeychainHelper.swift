//
//  KeychainHelper.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 04/08/25.
//
// memo/Services & Managers/KeychainHelper.swift

import Foundation
import Security

// Classe para simplificar a interação com o Keychain do iOS
final class KeychainHelper {
    
    // Identificador único para o serviço, geralmente o bundle ID do app.
    // Isso garante que os dados do seu app não se misturem com os de outros.
    private static let service = "weyers.memo"

    // Salva a senha no Keychain, associada a um e-mail (conta).
    static func save(password: String, forEmail email: String) throws {
        // A senha precisa ser convertida para o formato Data.
        guard let passwordData = password.data(using: .utf8) else {
            // Se a conversão falhar, lança um erro.
            throw KeychainError.stringToDataConversionError
        }

        // Dicionário que descreve o que queremos salvar.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, // Queremos salvar uma senha genérica.
            kSecAttrService as String: service,            // O serviço/app ao qual pertence.
            kSecAttrAccount as String: email,              // A conta/usuário (usamos o e-mail).
            kSecValueData as String: passwordData          // O dado sensível a ser salvo.
        ]

        // Primeiro, tentamos atualizar um item existente.
        let statusUpdate = SecItemUpdate(query as CFDictionary, [kSecValueData as String: passwordData] as CFDictionary)

        // Se o item não existir (errSecItemNotFound), nós o adicionamos.
        if statusUpdate == errSecItemNotFound {
            let statusAdd = SecItemAdd(query as CFDictionary, nil)
            // Se a adição falhar, lançamos um erro.
            if statusAdd != errSecSuccess {
                throw KeychainError.unhandledError(status: statusAdd)
            }
        }
        // Se a atualização falhar por qualquer outro motivo, lançamos um erro.
        else if statusUpdate != errSecSuccess {
            throw KeychainError.unhandledError(status: statusUpdate)
        }
    }

    // Carrega a senha do Keychain para um e-mail (conta) específico.
    static func load(forEmail email: String) throws -> String? {
        // Dicionário que descreve o que queremos buscar.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true, // Queremos que a função retorne os dados.
            kSecMatchLimit as String: kSecMatchLimitOne // Queremos apenas um resultado.
        ]

        var dataTypeRef: AnyObject?
        // Executa a busca no Keychain.
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            // Se a busca for bem-sucedida, converte os dados de volta para String.
            guard let retrievedData = dataTypeRef as? Data,
                  let password = String(data: retrievedData, encoding: .utf8)
            else {
                // Se a conversão falhar, o dado está corrompido.
                throw KeychainError.dataToStringConversionError
            }
            return password
        }
        // Se o item não for encontrado, isso não é um erro, apenas retornamos nil.
        else if status == errSecItemNotFound {
            return nil
        }
        // Para qualquer outro status, lançamos um erro.
        else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // Apaga a senha do Keychain para um e-mail (conta) específico.
    static func delete(forEmail email: String) throws {
        // Dicionário que descreve o que queremos apagar.
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email
        ]

        // Executa a operação de exclusão.
        let status = SecItemDelete(query as CFDictionary)
        // Se falhar por um motivo diferente de "não encontrado", lança um erro.
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandledError(status: status)
        }
    }
}


// Enum para representar erros específicos do Keychain.
enum KeychainError: Error {
    case stringToDataConversionError
    case dataToStringConversionError
    case unhandledError(status: OSStatus)
}
