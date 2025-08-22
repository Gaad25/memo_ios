import SwiftUI

struct ProfileAvatarView: View {
    @Binding var selectedAvatar: String
    @State private var showingAvatarPicker = false
    
    private let availableAvatars = [
        AvatarOption(id: "zoe_default", name: "Zoe Padrão", description: "O avatar clássico da Zoe"),
        AvatarOption(id: "zoe_studying", name: "Zoe Estudando", description: "Zoe com livros e caneta"),
        AvatarOption(id: "zoe_reading", name: "Zoe Lendo", description: "Zoe concentrada na leitura"),
        AvatarOption(id: "zoe_celebrating", name: "Zoe Comemorando", description: "Zoe feliz com conquistas"),
        AvatarOption(id: "zoe_thinking", name: "Zoe Pensando", description: "Zoe refletindo sobre problemas")
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Avatar atual
            Button(action: {
                showingAvatarPicker = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.dsPrimary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    avatarImage(for: selectedAvatar)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    
                    // Indicador de edição
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.dsPrimary)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .offset(x: -8, y: -8)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Botão de editar
            Button(action: {
                showingAvatarPicker = true
            }) {
                Text("Editar Avatar")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.dsPrimary)
            }
        }
        .sheet(isPresented: $showingAvatarPicker) {
            AvatarPickerView(selectedAvatar: $selectedAvatar, avatars: availableAvatars)
        }
    }
    
    private func avatarImage(for avatarId: String) -> some View {
        Group {
            if avatarId == "zoe_default" {
                Image("ZoeAvatar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Para outros avatares, usa SF Symbols como placeholder
                Image(systemName: symbolFor(avatarId: avatarId))
                    .font(.system(size: 50))
                    .foregroundColor(Color.dsPrimary)
            }
        }
    }
    
    private func symbolFor(avatarId: String) -> String {
        switch avatarId {
        case "zoe_studying":
            return "book.fill"
        case "zoe_reading":
            return "eyeglasses"
        case "zoe_celebrating":
            return "star.fill"
        case "zoe_thinking":
            return "brain.head.profile"
        default:
            return "person.fill"
        }
    }
}

struct AvatarOption: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
}

struct AvatarPickerView: View {
    @Binding var selectedAvatar: String
    let avatars: [AvatarOption]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(avatars) { avatar in
                AvatarRow(
                    avatar: avatar,
                    isSelected: selectedAvatar == avatar.id
                ) {
                    selectedAvatar = avatar.id
                    dismiss()
                }
            }
            .navigationTitle("Escolher Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AvatarRow: View {
    let avatar: AvatarOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Preview do avatar
                ZStack {
                    Circle()
                        .fill(Color.dsPrimary.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    avatarImage(for: avatar.id)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(avatar.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(avatar.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.dsPrimary)
                        .font(.title2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func avatarImage(for avatarId: String) -> some View {
        Group {
            if avatarId == "zoe_default" {
                Image("ZoeAvatar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: symbolFor(avatarId: avatarId))
                    .font(.system(size: 20))
                    .foregroundColor(Color.dsPrimary)
            }
        }
    }
    
    private func symbolFor(avatarId: String) -> String {
        switch avatarId {
        case "zoe_studying":
            return "book.fill"
        case "zoe_reading":
            return "eyeglasses"
        case "zoe_celebrating":
            return "star.fill"
        case "zoe_thinking":
            return "brain.head.profile"
        default:
            return "person.fill"
        }
    }
}

#Preview {
    ProfileAvatarView(selectedAvatar: .constant("zoe_default"))
}
