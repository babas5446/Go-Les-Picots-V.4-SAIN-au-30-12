//
//  SuggestionInputView.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  Formulaire de saisie des conditions de pêche
//  Interface avancée avec validation temps réel
//
//  Created: 2024-12-05
//

import SwiftUI

struct SuggestionInputView: View {
    @ObservedObject var suggestionEngine: SuggestionEngine
    @Environment(\.dismiss) var dismiss
    
    // Conditions de pêche
    @State private var conditions = ConditionsPeche(
        zone: .lagon,
        profondeurCible: 3.0,
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
    
    @State private var showingResults = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var showingWarnings = false
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("🎣 Suggestion IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingResults) {
                SuggestionResultView(
                    suggestions: suggestionEngine.suggestions,
                    configuration: suggestionEngine.configurationSpread
                )
            }
            .alert("Validation", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "FFBC42"))
            
            Text("Intelligence Artificielle")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "0277BD"))
            
            Text("Renseignez vos conditions de pêche pour obtenir des recommandations personnalisées basées sur les techniques professionnelles CPS")
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
                // Zone
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
                
                // Profondeur
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Profondeur cible")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(Int(conditions.profondeurCible))m")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "0277BD"))
                    }
                    
                    Slider(value: $conditions.profondeurCible, in: 0...150, step: 1)
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
                }
            }
        }
    }
    
    private var sectionVitesse: some View {
        CarteFormulaire(titre: "Vitesse du bateau", icone: "speedometer") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Vitesse")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(Int(conditions.vitesseBateau)) nœuds")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "FFBC42"))
                }
                
                Slider(value: $conditions.vitesseBateau, in: 3...16, step: 0.5)
                    .tint(Color(hex: "FFBC42"))
                
                HStack {
                    Text("3 nœuds")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("16 nœuds")
                        .font(.caption)
                        .foregroundColor(.gray)
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
                // Moment
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
                        // Suggestion auto luminosité
                        conditions.luminosite = ConditionsPeche.luminositeAutoDepuisMoment(conditions.momentJournee)
                    }
                }
                
                // Luminosité
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: conditions.luminosite.icon)
                            .foregroundColor(Color(hex: "FFBC42"))
                        Text("Luminosité")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Picker("Luminosité", selection: $conditions.luminosite) {
                        ForEach(Luminosite.allCases, id: \.self) { lum in
                            HStack {
                                Image(systemName: lum.icon)
                                Text(lum.displayName)
                            }
                            .tag(lum)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
    
    private var sectionConditionsMarines: some View {
        CarteFormulaire(titre: "Conditions marines", icone: "water.waves") {
            VStack(spacing: 16) {
                // Turbidité
                PickerRow(
                    label: "Turbidité eau",
                    selection: $conditions.turbiditeEau,
                    cases: Turbidite.allCases
                )
                
                // État mer
                PickerRow(
                    label: "État de la mer",
                    selection: $conditions.etatMer,
                    cases: EtatMer.allCases
                )
                
                // Marée
                PickerRow(
                    label: "Type de marée",
                    selection: $conditions.typeMaree,
                    cases: TypeMaree.allCases
                )
                
                // Phase lunaire
                PickerRow(
                    label: "Phase lunaire",
                    selection: $conditions.phaseLunaire,
                    cases: PhaseLunaire.allCases
                )
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
                
                Text("Analyse de \(suggestionEngine.leureViewModel.leurres.count) leurres...")
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
        
        if !valide {
            validationMessage = erreur ?? "Erreur de validation"
            showingValidationAlert = true
            return
        }
        
        suggestionEngine.genererSuggestions(conditions: conditions)
        
        // Attendre la fin du traitement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !suggestionEngine.isProcessing && suggestionEngine.errorMessage == nil {
                showingResults = true
            }
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

struct PickerRow<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String, T: Identifiable {
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
                    if let displayable = item as? any RawRepresentable & CaseIterable & Hashable {
                        Text(String(describing: displayable))
                    }
                }
            }
            .pickerStyle(.menu)
        }
    }
}

// Extension pour conformité
extension Turbidite: Identifiable {
    public var id: String { rawValue }
}

extension EtatMer: Identifiable {
    public var id: String { rawValue }
}

extension TypeMaree: Identifiable {
    public var id: String { rawValue }
}

extension PhaseLunaire: Identifiable {
    public var id: String { rawValue }
}
