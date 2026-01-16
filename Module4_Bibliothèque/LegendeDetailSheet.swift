//
//  LegendeDetailSheet.swift
//  Go les Picots - Module 4
//
//  Sheet affichant la légende détaillée de l'infographie
//  15 pages de contenu structuré et scrollable
//
//  Created: 2026-01-15
//

import SwiftUI

struct LegendeDetailSheet: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Introduction
                    sectionIntroduction
                    
                    Divider()
                    
                    // Section 1 : Type de pêche
                    sectionTypePeche
                    
                    Divider()
                    
                    // Section 2 : Analyse conditions
                    sectionAnalyseConditions
                    
                    Divider()
                    
                    // Section 3 : Choix couleurs
                    sectionChoixCouleurs
                    
                    Divider()
                    
                    // Section 4 : Types de têtes
                    sectionTypesTetes
                    
                    Divider()
                    
                    // Exemples pratiques
                    sectionExemplesPratiques
                    
                    Divider()
                    
                    // Conseils pro
                    sectionConseilsPro
                    
                    Divider()
                    
                    // Crédits
                    sectionCredits
                }
                .padding(20)
            }
            .navigationTitle("Légende Détaillée")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var sectionIntroduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GUIDE VISUEL : Choisir le Bon Leurre de Traîne")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "0277BD"))
            
            Text("Introduction")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Ce guide vous aide à sélectionner le leurre optimal selon :")
                .font(.body)
            
            VStack(alignment: .leading, spacing: 6) {
                bulletPoint("Le type de pêche pratiqué")
                bulletPoint("Les conditions météorologiques")
                bulletPoint("L'état de la mer")
                bulletPoint("La turbidité de l'eau")
            }
            
            Text("Suivez les flèches de l'infographie pour affiner votre choix.")
                .font(.callout)
                .foregroundColor(.secondary)
                .italic()
        }
    }
    
    private var sectionTypePeche: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Section 1 : Type de Pêche")
            
            // Traîne lente
            VStack(alignment: .leading, spacing: 8) {
                Text("Traîne Lente (4-8 nœuds)")
                    .font(.headline)
                    .foregroundColor(Color(hex: "0277BD"))
                
                labelValuePair("Usage", "Pêche côtière, lagon, récifs peu profonds")
                labelValuePair("Leurres", "Poissons nageurs à bavette, cuillers, petits leurres à jupe")
                labelValuePair("Espèces", "Carangues, Thazards, Barracudas, Petits thons")
                
                Text("Caractéristiques :")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    bulletPoint("Vitesse réduite pour leurres rigides")
                    bulletPoint("Action naturelle essentielle")
                    bulletPoint("Profondeur : 1-5 mètres")
                }
            }
            .padding()
            .background(Color(hex: "E3F2FD"))
            .cornerRadius(12)
            
            // Traîne rapide
            VStack(alignment: .leading, spacing: 8) {
                Text("Traîne Rapide (10+ nœuds)")
                    .font(.headline)
                    .foregroundColor(Color(hex: "D32F2F"))
                
                labelValuePair("Usage", "Pêche hauturière, pélagiques")
                labelValuePair("Leurres", "Leurres à jupe hydrodynamiques, grands poppers")
                labelValuePair("Espèces", "Wahoo, Marlins, Gros thons, Mahi-mahi")
                
                Text("Caractéristiques :")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    bulletPoint("Vitesse élevée pour couvrir large zone")
                    bulletPoint("Leurres résistants haute vitesse")
                    bulletPoint("Profondeur : surface à 10 mètres")
                }
            }
            .padding()
            .background(Color(hex: "FFEBEE"))
            .cornerRadius(12)
        }
    }
    
    private var sectionAnalyseConditions: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Section 2 : Analyse des Conditions")
            
            // Luminosité
            VStack(alignment: .leading, spacing: 12) {
                Text("Luminosité")
                    .font(.headline)
                    .foregroundColor(Color(hex: "FFBC42"))
                
                conditionCard(
                    titre: "☀️ Soleil Fort / Eau Claire",
                    couleurs: "Naturel, bleu, sardine, argenté, transparent",
                    raison: "Poissons voient très bien, finesse privilégiée",
                    contraste: "Naturel (mimétisme)",
                    tetes: "Bullet (discrète)"
                )
                
                conditionCard(
                    titre: "🌅 Aube / Crépuscule / Temps Noir",
                    couleurs: "Sombre et contrasté (noir/pourpre, noir/bleu, orange)",
                    raison: "Carnassiers chassent par silhouette",
                    contraste: "Fort (contraste > couleur)",
                    tetes: "Toutes"
                )
                
                conditionCard(
                    titre: "☁️ Nuageux / Lumière Diffuse",
                    couleurs: "Contrastées (bleu/blanc, rose/blanc, violet, chartreuse)",
                    raison: "Augmenter visibilité",
                    contraste: "Moyen à fort",
                    tetes: "Plunger, Pusher (bulles)"
                )
            }
            
            // Turbidité
            VStack(alignment: .leading, spacing: 12) {
                Text("Turbidité de l'Eau")
                    .font(.headline)
                    .foregroundColor(Color(hex: "00ACC1"))
                
                turbiditeCard(
                    titre: "💧 Eau Très Claire",
                    couleurs: "Naturelles, transparentes, bleu clair",
                    flash: "Subtil (pas trop flashy)",
                    raison: "Poissons méfiants",
                    action: "Nage réaliste"
                )
                
                turbiditeCard(
                    titre: "🌊 Eau Légèrement Trouble",
                    couleurs: "Vives et flashy (chartreuse, rose, violet)",
                    flash: "Mylar recommandé",
                    raison: "Compenser visibilité réduite",
                    action: "Plus agressive"
                )
                
                turbiditeCard(
                    titre: "🟫 Eau Très Trouble (Pluie/Marée Sortante)",
                    couleurs: "Très contrastées (noir, violet, rouge)",
                    flash: "Maximum",
                    raison: "Manque total de visibilité",
                    action: "Cup face profond (bruyantes)"
                )
            }
            
            // État mer
            VStack(alignment: .leading, spacing: 12) {
                Text("État de la Mer")
                    .font(.headline)
                    .foregroundColor(Color(hex: "1976D2"))
                
                etatMerCard(
                    titre: "😊 Mer Calme (Huile)",
                    approche: "Discrète",
                    couleurs: "Naturelles",
                    tetes: "Bullet (stable, silencieuse)",
                    vitesse: "Réduite"
                )
                
                etatMerCard(
                    titre: "🌊 Mer Formée (Clapot)",
                    approche: "Agressive",
                    couleurs: "Contrastées, flashy",
                    tetes: "Plunger, Pusher (bulles)",
                    vitesse: "Normale à rapide"
                )
                
                etatMerCard(
                    titre: "🌪️ Mer Agitée",
                    approche: "Très agressive",
                    couleurs: "Très contrastées",
                    tetes: "Cup face (pop sonore)",
                    vitesse: "Adaptée (souvent rapide)"
                )
            }
        }
    }
    
    private var sectionChoixCouleurs: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Section 3 : Choix des Couleurs")
            
            couleurCard(
                titre: "Couleurs Naturelles",
                exemples: "Bleu/argent, maquereau, sardine",
                usage: "Eau claire, soleil fort",
                effet: "Mimétisme, discrétion",
                especes: "Thons, Wahoo (méfiants)",
                color: "0277BD"
            )
            
            couleurCard(
                titre: "Couleurs Sombres",
                exemples: "Noir/pourpre, noir/bleu, violet foncé",
                usage: "Faible luminosité, silhouette",
                effet: "Contraste par ombre",
                especes: "Tous pélagiques (aube/crépuscule)",
                color: "424242"
            )
            
            couleurCard(
                titre: "Couleurs Flashy",
                exemples: "Rose vif, chartreuse, jaune fluo",
                usage: "Eau trouble, mer formée",
                effet: "Visibilité maximale",
                especes: "Mahi-mahi, Thazards",
                color: "E91E63"
            )
            
            couleurCard(
                titre: "Couleurs Contrastées",
                exemples: "Bleu/blanc, rose/blanc, vert/chartreuse",
                usage: "Polyvalent, lumière diffuse",
                effet: "Équilibre visibilité/discrétion",
                especes: "Tous (conditions variables)",
                color: "FF9800"
            )
        }
    }
    
    private var sectionTypesTetes: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Section 4 : Types de Têtes de Leurre")
            
            teteCard(
                emoji: "🔸",
                titre: "Tête Bullet (Ogive/Conique)",
                action: "Stabilité maximale, nage droite",
                production: "Peu de bulles",
                bruit: "Faible",
                vitesse: "Idéale haute vitesse (10+ nœuds)",
                usage: "Mer calme, traîne rapide",
                especes: "Wahoo, Thons rapides",
                avantages: ["Très hydrodynamique", "Pas de décrochage", "Nage prévisible"]
            )
            
            teteCard(
                emoji: "🔸",
                titre: "Tête Plunger/Pusher (Tronquée/Concave)",
                action: "Agressive, turbulences",
                production: "Beaucoup de bulles",
                bruit: "Pop sonore régulier",
                vitesse: "Moyenne (6-10 nœuds)",
                usage: "Mer formée, poissons actifs",
                especes: "Mahi-mahi, Marlins",
                avantages: ["Attire de loin", "Provoque attaques réflexes", "Visible en conditions difficiles"],
                note: "Cycle : \"Respiration\" (air) + \"Fumée\" (bulles) = 4,5-5,5 secondes"
            )
            
            teteCard(
                emoji: "🔸",
                titre: "Tête Jet (Perforée)",
                action: "Traînée de bulles longue",
                production: "\"Fume\" continuellement",
                bruit: "Moyen",
                vitesse: "Moyenne à rapide",
                usage: "Recherche large zone",
                especes: "Marlins, Gros thons",
                avantages: ["Visible de très loin", "Simule fuite rapide"],
                inconvenient: "Peut alerter poissons méfiants (eau claire)"
            )
        }
    }
    
    private var sectionExemplesPratiques: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Exemples Pratiques")
            
            exempleCard(
                numero: 1,
                titre: "Journée Ensoleillée, Mer Calme, Eau Claire",
                conditions: ["☀️ Soleil fort", "😊 Mer d'huile", "💧 Eau limpide"],
                choix: [
                    "Type : Traîne rapide (10 nœuds)",
                    "Couleur : Bleu/argent (naturel)",
                    "Tête : Bullet (discrète)",
                    "Contraste : Faible"
                ],
                raison: "Poissons très méfiants, privilégier discrétion"
            )
            
            exempleCard(
                numero: 2,
                titre: "Aube, Mer Formée, Eau Légèrement Trouble",
                conditions: ["🌅 Lever du soleil", "🌊 Clapot", "🌊 Turbidité moyenne"],
                choix: [
                    "Type : Traîne normale (6-8 nœuds)",
                    "Couleur : Noir/pourpre (sombre) ou Rose vif (flashy)",
                    "Tête : Plunger (agressive)",
                    "Contraste : Fort"
                ],
                raison: "Faible lumière + mer agitée = besoin contraste fort"
            )
            
            exempleCard(
                numero: 3,
                titre: "Après Pluie, Eau Très Trouble",
                conditions: ["☁️ Temps couvert", "🌊 Mer agitée", "🟫 Eau chocolat (marée sortante)"],
                choix: [
                    "Type : Traîne lente à normale",
                    "Couleur : Noir ou Rouge/noir (très contrasté)",
                    "Tête : Pusher Cup Face (très bruyante)",
                    "Contraste : Maximum"
                ],
                raison: "Visibilité quasi-nulle = compenser par bruit/vibrations"
            )
        }
    }
    
    private var sectionConseilsPro: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Conseils de Pro")
            
            VStack(alignment: .leading, spacing: 12) {
                conseilProCard(
                    emoji: "✅",
                    titre: "Construire un Spread Équilibré",
                    contenu: "Toujours avoir dans votre sillage :\n• 1 leurre naturel\n• 1 leurre sombre\n• 1 leurre flashy\n• 1 leurre contrasté\n\nAinsi, quelles que soient les conditions, au moins un leurre sera optimal."
                )
                
                conseilProCard(
                    emoji: "✅",
                    titre: "Observer et Adapter",
                    contenu: "• Pas de touche après 30 min ? → Changer couleur/tête\n• Touche sur un leurre précis ? → Dupliquer ce modèle\n• Conditions changent ? → Réajuster spread"
                )
                
                conseilProCard(
                    emoji: "✅",
                    titre: "Vitesse = Clé",
                    contenu: "• Trop rapide : Leurres décrochent, peu naturels\n• Trop lente : Pas assez d'action, leurres coulent\n• Idéal : Leurre \"respire\" régulièrement (cycle 4-5 sec)"
                )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("⚠️ Erreurs à Éviter")
                    .font(.headline)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 8) {
                    erreurCard("❌ Leurre flashy en eau claire et calme (effraie poissons)")
                    erreurCard("❌ Leurre naturel en eau trouble (invisible)")
                    erreurCard("❌ Tête bullet en mer formée (pas assez attractive)")
                    erreurCard("❌ Cup face en mer calme (trop bruyant)")
                }
            }
        }
    }
    
    private var sectionCredits: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crédits")
                .font(.headline)
                .foregroundColor(Color(hex: "0277BD"))
            
            Text("Infographie adaptée de :")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 6) {
                bulletPoint("Guides techniques CPS (Pacific Community)")
                bulletPoint("Manuels de pêche professionnelle Nouvelle-Calédonie")
                bulletPoint("Retours d'expérience pêcheurs locaux")
            }
            
            Text("© 2024 Go Les Picots - Tous droits réservés")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
                .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(Color(hex: "0277BD"))
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .fontWeight(.bold)
            Text(text)
        }
        .font(.callout)
    }
    
    private func labelValuePair(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(label):")
                .fontWeight(.semibold)
            Text(value)
        }
        .font(.callout)
    }
    
    private func conditionCard(titre: String, couleurs: String, raison: String, contraste: String, tetes: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titre)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            labelValuePair("Couleurs", couleurs)
            labelValuePair("Raison", raison)
            labelValuePair("Contraste", contraste)
            labelValuePair("Têtes", tetes)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func turbiditeCard(titre: String, couleurs: String, flash: String, raison: String, action: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titre)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            labelValuePair("Couleurs", couleurs)
            labelValuePair("Flash", flash)
            labelValuePair("Raison", raison)
            labelValuePair("Action", action)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func etatMerCard(titre: String, approche: String, couleurs: String, tetes: String, vitesse: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titre)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            labelValuePair("Approche", approche)
            labelValuePair("Couleurs", couleurs)
            labelValuePair("Têtes", tetes)
            labelValuePair("Vitesse", vitesse)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func couleurCard(titre: String, exemples: String, usage: String, effet: String, especes: String, color: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: 12, height: 12)
                
                Text(titre)
                    .font(.headline)
                    .foregroundColor(Color(hex: color))
            }
            
            labelValuePair("Exemples", exemples)
            labelValuePair("Usage", usage)
            labelValuePair("Effet", effet)
            labelValuePair("Espèces", especes)
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: color), lineWidth: 2)
        )
    }
    
    private func teteCard(emoji: String, titre: String, action: String, production: String, bruit: String, vitesse: String, usage: String, especes: String, avantages: [String], note: String? = nil, inconvenient: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(emoji)
                    .font(.title2)
                
                Text(titre)
                    .font(.headline)
                    .foregroundColor(Color(hex: "0277BD"))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                labelValuePair("Action", action)
                labelValuePair("Production", production)
                labelValuePair("Bruit", bruit)
                labelValuePair("Vitesse", vitesse)
                labelValuePair("Usage", usage)
                labelValuePair("Espèces", especes)
            }
            
            if !avantages.isEmpty {
                Text("Avantages :")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.top, 4)
                
                ForEach(avantages, id: \.self) { avantage in
                    bulletPoint(avantage)
                }
            }
            
            if let note = note {
                Text(note)
                    .font(.caption)
                    .foregroundColor(Color(hex: "FFBC42"))
                    .italic()
                    .padding(.top, 4)
            }
            
            if let inconvenient = inconvenient {
                HStack(alignment: .top, spacing: 6) {
                    Text("⚠️")
                    Text("Inconvénient :")
                        .fontWeight(.semibold)
                    Text(inconvenient)
                }
                .font(.caption)
                .foregroundColor(.red)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(hex: "E3F2FD"))
        .cornerRadius(12)
    }
    
    private func exempleCard(numero: Int, titre: String, conditions: [String], choix: [String], raison: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Exemple \(numero)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "FFBC42"))
                    .cornerRadius(8)
                
                Spacer()
            }
            
            Text(titre)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Conditions :")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                ForEach(conditions, id: \.self) { condition in
                    Text("• \(condition)")
                        .font(.callout)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Choix recommandé :")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "0277BD"))
                
                ForEach(choix, id: \.self) { element in
                    Text("• \(element)")
                        .font(.callout)
                        .fontWeight(.medium)
                }
            }
            
            HStack(alignment: .top, spacing: 8) {
                Text("💡")
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Raison :")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(raison)
                        .font(.callout)
                        .italic()
                }
            }
            .padding(10)
            .background(Color(hex: "FFF9E6"))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func conseilProCard(emoji: String, titre: String, contenu: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(titre)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "43A047"))
                
                Text(contenu)
                    .font(.callout)
            }
        }
        .padding()
        .background(Color(hex: "E8F5E9"))
        .cornerRadius(10)
    }
    
    private func erreurCard(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "FFEBEE"))
            .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    LegendeDetailSheet()
}
