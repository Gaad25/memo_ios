import SwiftUI

struct RankingRowView: View {
    let user: RankedUser
    let position: Int
    let isCurrentUser: Bool
    let viewModel: RankingViewModel

    // Larguras fixas para estabilizar o layout
    private let positionWidth: CGFloat = 40
    private let avatarOuter: CGFloat = 50
    private let avatarInner: CGFloat = 40
    private let trailingBlockWidth: CGFloat = 76 // ajuste fino se precisar (72–88)

    var body: some View {
        HStack(spacing: 16) {
            // Posição no ranking
            positionView
                .frame(width: positionWidth)

            // Avatar do usuário
            avatarView
                .frame(width: avatarOuter, height: avatarOuter)

            // Informações do usuário (damos prioridade ao nome)
            userInfoView
                .layoutPriority(1)

            Spacer(minLength: 8)

            // Pontos (largura fixa para não “empurrar” o nome)
            pointsView
                .frame(width: trailingBlockWidth, alignment: .trailing)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundView)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.dsPrimary : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - Components

    private var positionView: some View {
        VStack {
            if position <= 3 {
                Text(viewModel.emojiForPosition(position))
                    .font(.title2)
            } else {
                Text("\(position)º")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(viewModel.colorForPosition(position).opacity(0.1))

            avatarImage
                .frame(width: avatarInner, height: avatarInner)
                .clipShape(Circle())

            // Badge para top 3
            if position <= 3 {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(viewModel.colorForPosition(position))
                                .frame(width: 16, height: 16)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        }
                        .offset(x: 4, y: -4)
                    }
                    Spacer()
                }
            }
        }
    }

    private var avatarImage: some View {
        Group {
            if user.selectedAvatar == "zoe_default" {
                Image("ZoeAvatar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: symbolFor(avatarId: user.selectedAvatar))
                    .font(.system(size: 20))
                    .foregroundColor(Color.dsPrimary)
            }
        }
    }

    private var userInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(user.userName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)              // não quebra
                    .truncationMode(.tail)     // … no fim
                    .minimumScaleFactor(0.85)  // reduz levemente antes de cortar
                    .allowsTightening(true)    // ajusta tracking sutilmente

                if isCurrentUser {
                    Text("(Você)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.dsPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.dsPrimary.opacity(0.1))
                        .cornerRadius(8)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false) // evita quebra do chip
                }
            }

            if position <= 3 {
                Text(rankingDescription(for: position))
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    private var pointsView: some View {
        HStack(spacing: 8) {
            // Ícone de troféu apenas para o primeiro lugar
            if position == 1 {
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                    .fixedSize()
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text(viewModel.formattedPoints(user.weeklyPoints))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(position <= 3 ? viewModel.colorForPosition(position) : Color.dsPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("pontos")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var backgroundView: some View {
        Group {
            if position <= 3 {
                LinearGradient(
                    colors: [
                        viewModel.colorForPosition(position).opacity(0.1),
                        viewModel.colorForPosition(position).opacity(0.05)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if isCurrentUser {
                Color.dsPrimary.opacity(0.05)
            } else {
                Color(.systemBackground)
            }
        }
    }

    // MARK: - Helper Functions

    private func symbolFor(avatarId: String) -> String {
        switch avatarId {
        case "zoe_studying": return "book.fill"
        case "zoe_reading": return "eyeglasses"
        case "zoe_celebrating": return "star.fill"
        case "zoe_thinking": return "brain.head.profile"
        default: return "person.fill"
        }
    }

    private func rankingDescription(for position: Int) -> String {
        switch position {
        case 1: return "Campeão!"
        case 2: return "Vice-campeão"
        case 3: return "Terceiro lugar"
        default: return ""
        }
    }
}
