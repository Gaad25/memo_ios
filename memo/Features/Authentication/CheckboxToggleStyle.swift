//
//  CheckboxToggleStyle.swift
//  memo
//
//  Created by Gabriel Gad Costa Weyers on 04/08/25.
//
import SwiftUI
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }, label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                configuration.label
            }
        })
        .buttonStyle(.plain)
    }
}
