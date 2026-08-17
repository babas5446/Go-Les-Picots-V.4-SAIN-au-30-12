//
//  SuggestionInputView.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  VERSION FINALE avec NavigationCoordinator
//  Formulaire de saisie des conditions de pêche
//
//  Created: 2024-12-05
//  Fixed: Navigation avec coordinateur partagé
//

import SwiftUI

struct SuggestionInputView: View {
    @ObservedObject var suggestionEngine: SuggestionEngine
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @Environment(\.dismiss) var dismiss
    
    // Conditions de pêche
    @State private var conditions = ConditionsPeche(
        zone: .lagon,
        profondeurZone: 15.0,  // Profondeur du fond (lagon profond)
        vitesseBateau: 5.0,
        momentJournee: .matinee,
        luminosite: .forte,
        turbiditeEau: .claire,
        etatMer: .calme,
        typeMaree: .montante,
        phaseLunaire: .pleineLune,
        especePrioritaire: nil,
        nombreLignes: 3
    )
    
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var useSuggestedSpeed = true  // Utiliser la vitesse suggérée par défaut
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // En-tête
                    headerSection
                    
                    // Bouton test Scénario 1
                    boutonTestScenario1
                    
                    // Zone et profondeur
                    sectionZoneProfondeur
                    
                    // Vitesse
                    sectionVitesse
                    
                    // Moment et luminosité
                    sectionMomentLuminosite
                    
                    // Conditions marines
                    sectionConditionsMarines
                    
                    // Espèce prioritaire
                    sectionEspecePrioritaire
                    
                    // Nombre de lignes
                    sectionNombreLignes
                    
                    // Avertissements cohérence
                    if !conditions.avertissementsCoherence().isEmpty {
                        avertissementsSection
                    }
                    
                    // Bouton générer
                    boutonGenerer
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(hex: "F5F5F5"))
            
            // Loading overlay
            if suggestionEngine.isProcessing {
                loadingOverlay
            }
        }
        .navigationTitle("Suggestion IA")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Fermer") {
                    dismiss()
                }
            }
        }
        .alert("Validation", isPresented: $showingValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image("fishing-lures-banner")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            Text("Intelligence Artificielle")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "0277BD"))
            
            Text("Renseignez vos conditions de pêche pour obtenir des recommandations professionnelles personnalisées")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Bouton Test Scénario 1
    
    private var boutonTestScenario1: some View {
        Button(action: {
            withAnimation {
                conditions = ConditionsPeche.scenario1LagunAube
            }
        }) {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("Charger Scénario Test (Lagon Aube)")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "0277BD").opacity(0.1))
            .foregroundColor(Color(hex: "0277BD"))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Sections du formulaire
    
    private var sectionZoneProfondeur: some View {
        CarteFormulaire(titre: "Zone de pêche", icone: "map.fill") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Zone")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Picker("Zone", selection: $conditions.zone) {
                        ForEach(CategoriePeche.allCases, id: \.self) { zone in
                            Text(zone.displayName).tag(zone)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profondeur de la zone")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("(ce que vous voyez au sondeur)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(Int(conditions.profondeurZone))m")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "0277BD"))
                    }
                    
                    Slider(value: $conditions.profondeurZone, in: 0...150, step: 1)
                        .tint(Color(hex: "0277BD"))
                    
                    HStack {
                        Text("0m")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("150m")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // 💡 NOUVEAU : Affichage de la profondeur de nage déduite
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "FFBC42"))
                        Text("Profondeur de nage déduite : \(conditions.profondeurNageDeduiteDescription)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(hex: "FFBC42").opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var sectionVitesse: some View {
        CarteFormulaire(titre: "Vitesse du bateau", icone: "speedometer") {
            VStack(alignment: .leading, spacing: 12) {
                // Toggle pour suggestion intelligente
                Toggle(isOn: $useSuggestedSpeed) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color(hex: "FFBC42"))
                        Text("Suggestion intelligente")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                .tint(Color(hex: "FFBC42"))
                .onChange(of: useSuggestedSpeed) { newValue in
                    if newValue {
                        // Calculer la vitesse suggérée avec contexte complet
                        let vitesse = SuggestionEngine.calculerVitesseRecommandee(
                            especePrioritaire: conditions.especePrioritaire,
                            profilBateau: conditions.profilBateau,
                            zone: conditions.zone,
                            etatMer: conditions.etatMer,
                            turbidite: conditions.turbiditeEau,
                            momentJournee: conditions.momentJournee
                        )
                        conditions.vitesseBateau = vitesse.vitesseRecommandee
                    }
                }
                
                if useSuggestedSpeed {
                    // Affichage de la vitesse suggérée avec ajustements
                    let vitesse = SuggestionEngine.calculerVitesseRecommandee(
                        especePrioritaire: conditions.especePrioritaire,
                        profilBateau: conditions.profilBateau,
                        zone: conditions.zone,
                        etatMer: conditions.etatMer,
                        turbidite: conditions.turbiditeEau,
                        momentJournee: conditions.momentJournee
                    )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Badge principal
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Plage optimale calculée")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", vitesse.plageMin)) - \(String(format: "%.1f", vitesse.plageMax)) kts")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "0277BD"))
                                Text("Vitesse centrale : \(String(format: "%.1f", vitesse.vitesseRecommandee)) kts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Ajustements contextuels (si présents)
                        if !vitesse.ajustements.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "FFBC42"))
                                    Text("Ajustements appliqués")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: "FFBC42"))
                                }
                                
                                ForEach(vitesse.ajustements, id: \.self) { ajustement in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(ajustement)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color(hex: "FFBC42").opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                } else {
                    // Contrôle manuel avec aide discrète
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Vitesse")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(String(format: "%.1f", conditions.vitesseBateau) + " kts")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "FFBC42"))
                        }
                        
                        Slider(value: $conditions.vitesseBateau, in: 3...16, step: 0.5)
                            .tint(Color(hex: "FFBC42"))
                        
                        HStack {
                            Text("3 kts")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("16 kts")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // Aide discrète basée sur conditions
                        let vitesse = SuggestionEngine.calculerVitesseRecommandee(
                            especePrioritaire: conditions.especePrioritaire,
                            profilBateau: conditions.profilBateau,
                            zone: conditions.zone,
                            etatMer: conditions.etatMer,
                            turbidite: conditions.turbiditeEau,
                            momentJournee: conditions.momentJournee
                        )
                        
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("Suggéré : \(String(format: "%.1f", vitesse.plageMin))-\(String(format: "%.1f", vitesse.plageMax)) kts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                
                if conditions.vitesseBateau > 12 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Haute vitesse : peu de leurres compatibles")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
    
    private var sectionMomentLuminosite: some View {
        CarteFormulaire(titre: "Moment et luminosité", icone: "sun.max.fill") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Moment de la journée")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Picker("Moment", selection: $conditions.momentJournee) {
                        ForEach(MomentJournee.allCases, id: \.self) { moment in
                            Text(moment.displayName).tag(moment)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: conditions.momentJournee) { _ in
                        conditions.luminosite = ConditionsPeche.luminositeAutoDepuisMoment(conditions.momentJournee)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: conditions.luminosite.icon)
                            .foregroundColor(Color(hex: "FFBC42"))
                        Text("Luminosité")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    // ✅ ICÔNES SEULES sur une ligne
                    HStack(spacing: 12) {
                        ForEach(Luminosite.allCases, id: \.self) { lum in
                            let isSelected = conditions.luminosite == lum
                            Button(action: {
                                conditions.luminosite = lum
                            }) {
                                Image(systemName: lum.icon)
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? Color(hex: "FFBC42") : Color(hex: "F5F5F5"))
                                    )
                                    .foregroundColor(isSelected ? .white : .gray)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                isSelected ? Color(hex: "FFBC42") : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                            }
                        }
                    }
                    
                    // ✅ Légende sous les boutons (optionnel)
                    if conditions.luminosite != .forte {
                        Text(conditions.luminosite.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }
    
    private var sectionConditionsMarines: some View {
        CarteFormulaire(titre: "Conditions marines", icone: "water.waves") {
            VStack(spacing: 16) {
                PickerRow(label: "Turbidité eau", selection: $conditions.turbiditeEau, cases: Turbidite.allCases)
                PickerRow(label: "État de la mer", selection: $conditions.etatMer, cases: EtatMer.allCases)
                PickerRow(label: "Type de marée", selection: $conditions.typeMaree, cases: TypeMaree.allCases)
                PickerRow(label: "Phase lunaire", selection: $conditions.phaseLunaire, cases: PhaseLunaire.allCases)
            }
        }
    }
    
    private var sectionEspecePrioritaire: some View {
        CarteFormulaire(titre: "Espèce prioritaire (optionnel)", icone: "fish.fill") {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Espèce", selection: $conditions.especePrioritaire) {
                    Text("Toutes espèces").tag(nil as Espece?)
                    ForEach(Espece.allCases, id: \.self) { espece in
                        Text(espece.displayName).tag(espece as Espece?)
                    }
                }
                .pickerStyle(.menu)
                
                if conditions.especePrioritaire != nil {
                    Text("L'algorithme privilégiera les leurres adaptés à cette espèce")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    private var sectionNombreLignes: some View {
        CarteFormulaire(titre: "Configuration spread", icone: "arrow.triangle.branch") {
            VStack(alignment: .leading, spacing: 16) {
                // Nombre de lignes
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Nombre de lignes")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(conditions.nombreLignes)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "0277BD"))
                    }
                    
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { nb in
                            Button(action: {
                                withAnimation {
                                    conditions.nombreLignes = nb
                                }
                            }) {
                                Text("\(nb)")
                                    .font(.headline)
                                    .frame(width: 50, height: 50)
                                    .background(conditions.nombreLignes == nb ?
                                              Color(hex: "0277BD") :
                                              Color(hex: "0277BD").opacity(0.1))
                                    .foregroundColor(conditions.nombreLignes == nb ?
                                                   .white :
                                                   Color(hex: "0277BD"))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    
                    Text(strategieDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                // Profil bateau
                VStack(alignment: .leading, spacing: 12) {
                    Text("Profil bateau")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        ForEach(ProfilBateau.allCases, id: \.self) { profil in
                            Button(action: {
                                withAnimation {
                                    conditions.profilBateau = profil
                                    // Ajustement automatique si Clark et trop de lignes
                                    if profil == .clark429 && conditions.nombreLignes > 4 {
                                        conditions.nombreLignes = 4
                                    }
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Text(profil.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                    
                                    if profil == .clark429 {
                                        Text("Max 4 lignes")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(conditions.profilBateau == profil ?
                                          Color(hex: "0277BD") :
                                          Color(hex: "0277BD").opacity(0.1))
                                .foregroundColor(conditions.profilBateau == profil ?
                                               .white :
                                               Color(hex: "0277BD"))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    Text(conditions.profilBateau.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    private var strategieDescription: String {
        switch conditions.nombreLignes {
        case 1: return "Meilleur leurre polyvalent"
        case 2: return "Meilleur + Contraste opposé"
        case 3: return "Meilleur + Contraste + Shotgun"
        case 4: return "2 Corners + 2 Riggers (équilibré)"
        case 5: return "Spread complet avec couverture maximale"
        default: return ""
        }
    }
    
    private var avertissementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Avertissements de cohérence")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            ForEach(conditions.avertissementsCoherence(), id: \.self) { warning in
                Text(warning)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.leading, 24)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Bouton Générer
    
    private var boutonGenerer: some View {
        Button(action: genererSuggestions) {
            HStack {
                Image(systemName: "sparkles")
                Text("Générer les suggestions")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "0277BD"), Color(hex: "FFBC42")]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color(hex: "0277BD").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(suggestionEngine.isProcessing)
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(suggestionEngine.progressMessage)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Analyse en cours...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(30)
            .background(Color(hex: "0277BD"))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
    }
    
    // MARK: - Actions
    
    private func genererSuggestions() {
        let (valide, erreur) = conditions.estValide()
        guard valide else {
            validationMessage = erreur ?? "Erreur de validation"
            showingValidationAlert = true
            return
        }
        
        // ← AJOUTER CES DEUX LIGNES :
            if let data = try? JSONEncoder().encode(conditions) {
                UserDefaults.standard.set(data, forKey: "dernieresConditionsPeche")
            }
            
            print("🚀 Lancement de la génération...")
            suggestionEngine.genererSuggestions(conditions: conditions)
        print("🚀 Lancement de la génération...")
        suggestionEngine.genererSuggestions(conditions: conditions)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.verifierResultats()
        }
    }
    
    private func verifierResultats() {
        print("🔍 Vérification résultats - isProcessing: \(suggestionEngine.isProcessing)")
        
        if suggestionEngine.isProcessing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.verifierResultats()
            }
            return
        }
        
        if let erreur = suggestionEngine.errorMessage {
            print("❌ Erreur : \(erreur)")
            validationMessage = erreur
            showingValidationAlert = true
            return
        }
        
        if !suggestionEngine.suggestions.isEmpty {
            print("✅ Affichage des résultats : \(suggestionEngine.suggestions.count) suggestions")
            print("📱 Appel du NavigationCoordinator...")
            
            navigationCoordinator.presentResults(
                suggestions: suggestionEngine.suggestions,
                configuration: suggestionEngine.configurationSpread
            )
        } else {
            print("⚠️ Aucune suggestion générée")
            validationMessage = "Aucune suggestion générée."
            showingValidationAlert = true
        }
    }
}

// MARK: - Composants réutilisables

struct CarteFormulaire<Content: View>: View {
    let titre: String
    let icone: String
    let content: Content
    
    init(titre: String, icone: String, @ViewBuilder content: () -> Content) {
        self.titre = titre
        self.icone = icone
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icone)
                    .foregroundColor(Color(hex: "0277BD"))
                Text(titre)
                    .font(.headline)
                    .foregroundColor(Color(hex: "0277BD"))
            }
            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct PickerRow<T: CaseIterable & Hashable & Identifiable>: View where T: RawRepresentable, T.RawValue == String {
    let label: String
    @Binding var selection: T
    let cases: [T]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
            Picker(label, selection: $selection) {
                ForEach(cases, id: \.self) { item in
                    // Utiliser le displayName si disponible, sinon description
                    Text(displayNameFor(item)).tag(item)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    // Helper pour obtenir le displayName
    private func displayNameFor(_ item: T) -> String {
        if let named = item as? any DisplayNamed {
            return named.displayName
        }
        return String(describing: item)
    }
}

// Protocole helper pour types avec displayName
protocol DisplayNamed {
    var displayName: String { get }
}

extension Turbidite: Identifiable, DisplayNamed { 
    public var id: String { rawValue }
}
extension EtatMer: Identifiable, DisplayNamed { 
    public var id: String { rawValue }
}
extension TypeMaree: Identifiable, DisplayNamed { 
    public var id: String { rawValue }
}
extension PhaseLunaire: Identifiable, DisplayNamed { 
    public var id: String { rawValue }
}






















