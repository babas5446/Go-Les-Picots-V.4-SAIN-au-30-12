//
//  ProfilMoteurView.swift
//  Go les Picots V.4 — Module 1
//
//  « Ce que voit le moteur » : profil visuel d'un leurre calculé par les
//  mêmes règles que le moteur de suggestion (ReglesCouleur, modèle de
//  contraste validé le 4 octobre 2026). Affiché sous la section Couleurs du
//  formulaire et dans la fiche du leurre, pour que la saisie et le calcul
//  ne divergent plus.
//

import SwiftUI

struct ProfilMoteurView: View {
    let fiche: FicheDeduction

    private var famille: Contraste { ReglesCouleur.famille(fiche) }
    private var profondeurMax: Double { ReglesDeduction.profondeurMax(fiche) }
    private var familleEnProfondeur: Contraste {
        ReglesCouleur.familleCorrigee(fiche, profondeur: profondeurMax)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Ce que voit le moteur", systemImage: "eye")
                .font(.caption.weight(.semibold))
            ligne("Famille", famille.displayName)
            ligne("Teinte", ReglesCouleur.teinte(fiche).rawValue)
            ligne("Éclat", ReglesCouleur.eclats(fiche).map(\.rawValue).joined(separator: ", "))
            ligne("Ventre", texteVentre)
            if familleEnProfondeur != famille {
                Text("En nageant vers \(ProfilMoteurView.nb(profondeurMax)) m : vu « \(familleEnProfondeur.displayName) » (le rouge s'éteint vers 4 à 5 m, l'orange vers 6 m).")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var texteVentre: String {
        guard let v = ReglesCouleur.ventre(fiche) else { return "non renseigné" }
        var t: String
        switch v.ton {
        case .chaud?: t = "chaud"
        case .clair?: t = "clair"
        case .vif?:   t = "vif"
        case nil:     t = "couleur non classée"
        }
        if let e = v.eclat { t += ", " + e.displayName.lowercased() }
        return t
    }

    private func ligne(_ libelle: String, _ valeur: String) -> some View {
        HStack {
            Text(libelle).foregroundStyle(.secondary)
            Spacer()
            Text(valeur)
        }
        .font(.caption)
    }

    static func nb(_ x: Double) -> String {
        x.rounded() == x ? String(Int(x)) : String(format: "%.1f", x).replacingOccurrences(of: ".", with: ",")
    }
}
