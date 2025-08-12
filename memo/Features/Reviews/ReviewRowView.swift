// memo/Features/Reviews/ReviewRowView.swift

import SwiftUI

struct ReviewRowView: View {
    @ObservedObject var viewModel: ReviewsViewModel
    let detail: ReviewsViewModel.ReviewDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cabeçalho do Card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(detail.subjectData.name)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    Text(detail.subjectData.category)
                        .font(.caption)
                        .foregroundColor(detail.subjectData.swiftUIColor)
                        .fontWeight(.semibold)
                }
                Spacer()
                Image(systemName: "text.book.closed.fill") // Ícone mais relevante
                    .font(.title)
                    .foregroundColor(detail.subjectData.swiftUIColor) // Define a cor primeiro
                    .opacity(0.8) // E depois a opacidade da View
            }

            Divider()

            // Informações de Data e Intervalo
            HStack(spacing: 24) {
                InfoItem(icon: "calendar", label: "Data", value: detail.reviewData.reviewDate.formatted(.compact(singleDay: true)))
                InfoItem(icon: "arrow.2.squarepath", label: "Intervalo", value: detail.reviewData.reviewInterval)
            }

            // Botão de Ação
            Button(action: {
                viewModel.startCompletionFlow(for: detail)
                // Feedback háptico leve
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }) {
                Label("Concluir Revisão", systemImage: "checkmark")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GradientPrimaryButtonStyle()) // Novo estilo de botão
            .padding(.top, 8)
        }
        .padding()
        .background(Color.dsSecondaryBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// Subview para os itens de informação (Data, Intervalo)
private struct InfoItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(.dsTextSecondary)
                .frame(width: 20)
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.dsTextSecondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
    }
}

extension Date {
    func formatted(_ format: CompactDateFormat) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Hoje" }
        if calendar.isDateInYesterday(self) { return "Ontem" }

        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }

    enum CompactDateFormat {
        case compact(singleDay: Bool)
    }
}
