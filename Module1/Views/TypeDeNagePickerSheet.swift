//
//  TypeDeNagePickerSheet.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 30/12/2025.
//

import SwiftUI

struct TypeDeNagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedType: TypeDeNage?
    let onWobblingTapped: () -> Void
    let onJiggingTapped: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Option "Aucun"
                    Button {
                        selectedType = nil
                        dismiss()
                    } label: {
                        HStack {
                            Text("Aucun")
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedType == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "0277BD"))
                            }
                        }
                    }
                    
                    // ⭐ WOBBLING EN HAUT (après Aucun)
                    Button {
                        onWobblingTapped()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Wobbling")
                                    .foregroundColor(.primary)
                                Text("Large ou serré")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(hex: "0277BD"))
                                .font(.caption)
                        }
                    }
                    
                    // ⭐ JIGGING EN HAUT (après Wobbling)
                    Button {
                        onJiggingTapped()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Jigging")
                                    .foregroundColor(.primary)
                                Text("Slow ou fast")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(hex: "FFBC42"))
                                .font(.caption)
                        }
                    }
                    
                    // Types standards (filtrés : sans wobbling/jigging et leurs variantes)
                    ForEach(TypeDeNage.allCases.filter { type in
                        // Exclure les déclencheurs et leurs variantes
                        type != .wobbling &&
                        type != .wobblingLarge &&
                        type != .wobblingSerré &&
                        type != .jigging &&
                        type != .slowJigging &&
                        type != .fastJigging
                    }, id: \.self) { type in
                        Button {
                            selectedType = type
                            dismiss()
                        } label: {
                            HStack {
                                Text(type.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "0277BD"))
                                }
                            }
                        }
                    }
                } header: {
                    Text("Sélectionnez un type de nage")
                } footer: {
                    Text("Les types avec flèche proposent des variantes adaptées aux conditions")
                }
            }
            .navigationTitle("Type de nage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct TypeDeNagePickerSheet_Previews: PreviewProvider {
    static var previews: some View {
        TypeDeNagePickerSheet(
            selectedType: .constant(nil),
            onWobblingTapped: {},
            onJiggingTapped: {}
        )
    }
}
