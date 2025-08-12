// memo/Features/Sessions/StudySessionView.swift

import SwiftUI
import Combine

struct StudySessionView: View {
    @Environment(\.dismiss) var dismiss
    let subject: Subject
    
    // MARK: - State
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: AnyCancellable?
    @State private var isRunning = true
    @State private var isPresentingSummary = false
    
    // State para mensagens motivacionais
    private let motivationalMessages = [
        "Mantenha o foco!",
        "Você está a ir muito bem!",
        "Só mais um pouco!",
        "Respire e continue."
    ]
    @State private var currentMessageIndex = 0
    @State private var messageTimer: AnyCancellable?

    // Propriedades computadas para o anel de progresso e para o tempo
    private var progress: Double { (elapsedTime.truncatingRemainder(dividingBy: 60)) / 60 }
    private var hours: Int { Int(elapsedTime) / 3600 }
    private var minutes: Int { (Int(elapsedTime) % 3600) / 60 }
    private var seconds: Int { Int(elapsedTime) % 60 }
    private enum TimeUnit: TimeInterval { case hours = 3600, minutes = 60 }

    var body: some View {
        VStack(spacing: 32) {
            
            // MARK: - Cabeçalho
            headerView
            
            Spacer()

            // MARK: - Cronómetro Circular
            ZStack {
                // Círculo de fundo interno
                Circle()
                    .fill(Color.dsSecondaryBackground)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 5, y: 5)
                
                // Anel de "pista" estático
                Circle()
                    .stroke(lineWidth: 16)
                    .foregroundColor(subject.swiftUIColor.opacity(0.15))

                // Anel de progresso animado
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
                    .fill(AngularGradient(gradient: Gradient(colors: [.dsBlue, .dsGreen]), center: .center))
                    .rotationEffect(Angle(degrees: 270.0))
                
                // Visualizador de tempo com ajuste manual
                timeDisplayWithControls
            }
            .frame(width: 280, height: 280)
            .animation(.easeInOut, value: progress)
            
            Spacer()
            
            // MARK: - Botões de Ação
            actionButtons
        }
        .padding(.horizontal, 32)
        .background(Color.dsBackground.ignoresSafeArea())
        .onAppear(perform: startTimers)
        .onDisappear(perform: stopTimers)
        .sheet(isPresented: $isPresentingSummary) { dismiss() } content: {
            SessionSummaryView(subject: subject, elapsedTime: elapsedTime)
        }
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        VStack {
            Text("Matéria: \(subject.name)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.dsBlue)
            
            Text(motivationalMessages[currentMessageIndex])
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(.dsTextSecondary)
                .id("motivationalMessage_\(currentMessageIndex)") // ID para a transição funcionar
                .transition(.opacity.animation(.easeIn))
        }
        .padding(.top, 40)
    }
    
    private var timeDisplayWithControls: some View {
        HStack(spacing: 10) {
            timeComponentControl(unit: .hours, value: hours)
            Text(":").font(.system(size: 40, weight: .bold, design: .rounded)).padding(.bottom, 15)
            timeComponentControl(unit: .minutes, value: minutes)
            Text(":").font(.system(size: 40, weight: .bold, design: .rounded)).padding(.bottom, 15)
            
            // Segundos (sem botões de ajuste)
            VStack(spacing: 8) {
                Text(String(format: "%02d", seconds))
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("Seg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }.frame(width: 60)
        }
    }

    private func timeComponentControl(unit: TimeUnit, value: Int) -> some View {
        VStack(spacing: 8) {
            Button(action: { adjustTime(by: unit.rawValue) }) {
                Image(systemName: "chevron.up")
            }.disabled(isRunning)
            
            Text(String(format: "%02d", value))
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()
            
            Text(unit == .hours ? "Hrs" : "Min")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: { adjustTime(by: -unit.rawValue) }) {
                Image(systemName: "chevron.down")
            }.disabled(isRunning || elapsedTime < unit.rawValue)
        }
        .font(.title2)
        .foregroundColor(.primary)
        .opacity(isRunning ? 0.4 : 1.0)
        .frame(width: 60)
    }

    private var actionButtons: some View {
        HStack(spacing: 40) {
            Button(action: toggleTimer) {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
            }
            .buttonStyle(TimerControlButton(color: isRunning ? .dsYellow : .dsBlue))
            .sensoryFeedback(.impact(weight: .light), trigger: isRunning)
            
            Button(action: finishSession) {
                Image(systemName: "square.fill")
            }
            .buttonStyle(TimerControlButton(color: .dsRed))
            .sensoryFeedback(.impact(weight: .heavy), trigger: isPresentingSummary)
        }
        .padding(.bottom, 60)
    }
    
    // MARK: - Funções
    private func adjustTime(by amount: TimeInterval) {
        let newTime = elapsedTime + amount
        if newTime >= 0 { elapsedTime = newTime }
    }

    private func startTimers() {
        isRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { _ in if isRunning { elapsedTime += 1 } }
        
        messageTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
            .sink { _ in
                let nextIndex = (currentMessageIndex + 1) % motivationalMessages.count
                withAnimation { currentMessageIndex = nextIndex }
            }
    }
    
    private func stopTimers() {
        timer?.cancel(); messageTimer?.cancel()
        timer = nil; messageTimer = nil
    }
    
    private func toggleTimer() { isRunning.toggle() }
    
    private func finishSession() {
        isRunning = false
        stopTimers()
        isPresentingSummary = true
    }
}
