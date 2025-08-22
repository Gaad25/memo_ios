//
//  MemoTimerWidgetLiveActivity.swift
//  MemoTimerWidget
//
//  Created by Gabriel Gad Costa Weyers on 18/08/25.
//

import ActivityKit
import WidgetKit
import SwiftUI



struct MemoTimerWidgetLiveActivity: Widget {
    
    // Função para calcular e formatar o tempo decorrido
    private func formatElapsedTime(from timerRange: ClosedRange<Date>) -> String {
        let now = Date()
        let startTime = timerRange.lowerBound
        let elapsedSeconds = max(0, now.timeIntervalSince(startTime))
        
        let hours = Int(elapsedSeconds) / 3600
        let minutes = (Int(elapsedSeconds) % 3600) / 60
        let seconds = Int(elapsedSeconds) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudyTimerAttributes.self) { context in
            // UI da Tela de Bloqueio - Apenas Display
            VStack(spacing: 16) {
                // Cabeçalho
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.blue)
                        .font(.title2)
                    Text("Estudando: \(context.attributes.subjectName)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(context.state.isRunning ? "Em Foco" : "Pausado")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(context.state.isRunning ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundColor(context.state.isRunning ? .green : .orange)
                        .clipShape(Capsule())
                }

                // Timer Grande - Calculado manualmente
                Text(formatElapsedTime(from: context.state.timerRange))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                
                // Texto informativo
                Text("Abra o app para controlar o timer")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .activityBackgroundTint(Color(.systemBackground))
            .activitySystemActionForegroundColor(Color(.label))
        } dynamicIsland: { context in
            DynamicIsland {
                // Empty - we only want lock screen
                DynamicIslandExpandedRegion(.leading) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    EmptyView()
                }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
    }
}

extension StudyTimerAttributes {
    fileprivate static var preview: StudyTimerAttributes {
        StudyTimerAttributes(subjectName: "Matemática")
    }
}

extension StudyTimerAttributes.ContentState {
    fileprivate static var running: StudyTimerAttributes.ContentState {
        let startDate = Date().addingTimeInterval(-300) // 5 minutes ago
        let endDate = Date().addingTimeInterval(3600) // 1 hour from start
        return StudyTimerAttributes.ContentState(
            timerRange: startDate...endDate,
            isRunning: true,
            pauseDate: nil
        )
    }
     
     fileprivate static var paused: StudyTimerAttributes.ContentState {
         let startDate = Date().addingTimeInterval(-600) // 10 minutes ago
         let endDate = Date().addingTimeInterval(3600) // 1 hour from start
         return StudyTimerAttributes.ContentState(
             timerRange: startDate...endDate,
             isRunning: false,
             pauseDate: Date().addingTimeInterval(-60) // paused 1 minute ago
         )
     }
}

#Preview("Notification", as: .content, using: StudyTimerAttributes.preview) {
   MemoTimerWidgetLiveActivity()
} contentStates: {
    StudyTimerAttributes.ContentState.running
    StudyTimerAttributes.ContentState.paused
}
