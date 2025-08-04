//
//  PrimaryButtonStyle.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 04/08/25.
//
import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .font(.headline)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0) // Efeito sutil ao pressionar
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
