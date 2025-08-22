import Foundation

actor RateLimiter {
    private let key: String
    private let dateKey: String
    private let maxDaily: Int

    // O inicializador permite configurar chaves diferentes no UserDefaults
    // e o limite máximo diário.
    init(key: String = "ai_daily_count", dateKey: String = "ai_daily_date", maxDaily: Int) {
        self.key = key
        self.dateKey = dateKey
        self.maxDaily = maxDaily
    }

    // A função principal que verifica e consome um uso.
    func consume() async -> Bool {
        
        // Pega a data de hoje no formato "AAAA-MM-DD".
        let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
        let defaults = UserDefaults.standard
        
        // Pega a data do último uso que foi salva.
        let storedDate = defaults.string(forKey: dateKey)
        
        // Se a data salva for diferente de hoje, reinicia a contagem.
        if storedDate != today {
            defaults.set(0, forKey: key)       // Zera a contagem de usos
            defaults.set(today, forKey: dateKey) // Salva a data de hoje
        }
        
        // Pega a contagem de usos atual.
        let count = defaults.integer(forKey: key)
        
        // Verifica se a contagem atual já atingiu o máximo.
        // Se sim, retorna 'false' (não pode usar).
        guard count < maxDaily else {
            return false
        }
        
        // Se ainda não atingiu o limite, incrementa a contagem e a salva.
        defaults.set(count + 1, forKey: key)
        
        // Retorna 'true' (pode usar).
        return true
    }
}
