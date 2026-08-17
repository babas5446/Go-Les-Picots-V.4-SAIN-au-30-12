//
//  LeurreDTO.swift
//  Go les Picots V.4 — Module 1
//
//  Data Transfer Object : struct Codable pour la sérialisation JSON.
//  Séparé de Leurre (@Model) pour respecter les contraintes SwiftData + Swift 6.
//
//  Utilisé par :
//  - LeurreMigrationService : LeurreDTO → Leurre (import JSON → SwiftData)
//  - LeurreExportService    : Leurre → LeurreDTO (SwiftData → export ZIP)
//
//  Ne jamais utiliser LeurreDTO dans les vues ou le moteur de suggestion.
//  Toute la logique métier reste dans Leurre.swift.
//
//  V4 — Modifications par rapport à la version précédente :
//  - Suppression de extension Leurre { toDTO() / toExportDict() }
//    → Ces méthodes causaient "Type 'Any' cannot conform to 'Encodable'"
//    → La conversion Leurre → LeurreDTO est désormais dans LeurreExportService
//  - Ajout de photoBase64: String? pour le nouveau format d'export
//    → Photos encodées en Base64 dans le JSON, plus de dossier photos/ séparé
//

import Foundation

// MARK: - LeurreDTO

struct LeurreDTO: Codable {

    // MARK: - Identification
    var id: Int

    // MARK: - Champs saisis
    var nom: String
    var marque: String
    var modele: String?

    var typeLeurre: TypeLeurre
    var typePeche: TypePeche
    var typesPecheCompatibles: [TypePeche]?

    var longueur: Double
    var poids: Double?

    var couleurPrincipale: Couleur
    var couleurPrincipaleCustom: CouleurCustom?
    var couleurSecondaire: Couleur?
    var couleurSecondaireCustom: CouleurCustom?
    var finition: Finition?
    var typesDeNage: [TypeDeNage]?

    var profondeurNageMin: Double?
    var profondeurNageMax: Double?
    var vitesseTraineMin: Double?
    var vitesseTraineMax: Double?

    var notes: String?

    /// Photo encodée en Base64 — présente uniquement dans les exports V4.
    /// Nil lors de l'import depuis l'ancien JSON (photos sur disque).
    /// Peuplé par LeurreExportService, lu par LeurreMigrationService.
    var photoBase64: String?

    // MARK: - Champs déduits
    var contraste: Contraste?
    var zonesAdaptees: [Zone]?
    var especesCibles: [String]?
    var positionsSpread: [PositionSpread]?
    var conditionsOptimales: ConditionsOptimales?
    var isComputed: Bool?

    // MARK: - Champs V4
    var notesMotsCles: [String]?
    var qualiteDataScore: Int?

    // MARK: - Gestion
    var quantite: Int?
    var dateAjout: Date?

    // MARK: - Init direct (utilisé par LeurreExportService : Leurre → LeurreDTO)

    init(
        id: Int,
        nom: String,
        marque: String,
        modele: String? = nil,
        typeLeurre: TypeLeurre,
        typePeche: TypePeche,
        typesPecheCompatibles: [TypePeche]? = nil,
        longueur: Double,
        poids: Double? = nil,
        couleurPrincipale: Couleur,
        couleurPrincipaleCustom: CouleurCustom? = nil,
        couleurSecondaire: Couleur? = nil,
        couleurSecondaireCustom: CouleurCustom? = nil,
        finition: Finition? = nil,
        typesDeNage: [TypeDeNage]? = nil,
        profondeurNageMin: Double? = nil,
        profondeurNageMax: Double? = nil,
        vitesseTraineMin: Double? = nil,
        vitesseTraineMax: Double? = nil,
        notes: String? = nil,
        photoBase64: String? = nil,
        contraste: Contraste? = nil,
        zonesAdaptees: [Zone]? = nil,
        especesCibles: [String]? = nil,
        positionsSpread: [PositionSpread]? = nil,
        conditionsOptimales: ConditionsOptimales? = nil,
        isComputed: Bool? = nil,
        notesMotsCles: [String]? = nil,
        qualiteDataScore: Int? = nil,
        quantite: Int? = nil,
        dateAjout: Date? = nil
    ) {
        self.id                      = id
        self.nom                     = nom
        self.marque                  = marque
        self.modele                  = modele
        self.typeLeurre              = typeLeurre
        self.typePeche               = typePeche
        self.typesPecheCompatibles   = typesPecheCompatibles
        self.longueur                = longueur
        self.poids                   = poids
        self.couleurPrincipale       = couleurPrincipale
        self.couleurPrincipaleCustom = couleurPrincipaleCustom
        self.couleurSecondaire       = couleurSecondaire
        self.couleurSecondaireCustom = couleurSecondaireCustom
        self.finition                = finition
        self.typesDeNage             = typesDeNage
        self.profondeurNageMin       = profondeurNageMin
        self.profondeurNageMax       = profondeurNageMax
        self.vitesseTraineMin        = vitesseTraineMin
        self.vitesseTraineMax        = vitesseTraineMax
        self.notes                   = notes
        self.photoBase64             = photoBase64
        self.contraste               = contraste
        self.zonesAdaptees           = zonesAdaptees
        self.especesCibles           = especesCibles
        self.positionsSpread         = positionsSpread
        self.conditionsOptimales     = conditionsOptimales
        self.isComputed              = isComputed
        self.notesMotsCles           = notesMotsCles
        self.qualiteDataScore        = qualiteDataScore
        self.quantite                = quantite
        self.dateAjout               = dateAjout
    }

    // MARK: - CodingKeys (compatibilité JSON existant)

    enum CodingKeys: String, CodingKey {
        case id
        case nom
        case marque
        case modele
        case reference                          // Ignoré
        case typeLeurre         = "type"
        case typePeche          = "categoriePeche"
        case typesPecheCompatibles = "techniquesPossibles"
        case longueur
        case poids
        case couleurPrincipale
        case couleurPrincipaleCustom
        case couleurSecondaire  = "couleursSecondaires"
        case couleurSecondaireCustom
        case finition
        case typesDeNage        = "types_de_nage"
        case typeDeNage         = "type_de_nage"    // Ancien champ — migration
        case profondeurNageMin  = "profondeurMin"
        case profondeurNageMax  = "profondeurMax"
        case vitesseTraineMin   = "vitesseMinimale"
        case vitesseTraineMax   = "vitesseMaximale"
        case notes
        case photoPath                              // Ignoré à l'import — ancien format
        case photoBase64                            // Nouveau format V4 — Base64
        case contraste
        case zonesAdaptees      = "zones"
        case especesCibles
        case positionsSpread
        case conditionsOptimales
        case isComputed
        case notesMotsCles
        case qualiteDataScore
        case quantite
        case dateAjout
        // Champs supplémentaires ignorés
        case typeTete
        case actionNage
        case vitesseOptimale
    }

    // MARK: - Decodable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id     = try container.decode(Int.self, forKey: .id)
        nom    = try container.decode(String.self, forKey: .nom)
        marque = try container.decode(String.self, forKey: .marque)
        modele = try container.decodeIfPresent(String.self, forKey: .modele)

        typeLeurre = try container.decode(TypeLeurre.self, forKey: .typeLeurre)

        // categoriePeche peut être String ou Array selon la version du JSON
        if let arr = try? container.decode([TypePeche].self, forKey: .typePeche),
           let first = arr.first {
            typePeche = first
            typesPecheCompatibles = arr
        } else {
            typePeche = try container.decode(TypePeche.self, forKey: .typePeche)
            typesPecheCompatibles = try container.decodeIfPresent([TypePeche].self, forKey: .typesPecheCompatibles)
        }

        longueur = try container.decode(Double.self, forKey: .longueur)
        poids    = try container.decodeIfPresent(Double.self, forKey: .poids)

        couleurPrincipale       = try container.decode(Couleur.self, forKey: .couleurPrincipale)
        couleurPrincipaleCustom = try container.decodeIfPresent(CouleurCustom.self, forKey: .couleurPrincipaleCustom)

        // couleursSecondaires est un array dans l'ancien JSON — on prend la première valeur
        if let arr = try? container.decode([Couleur].self, forKey: .couleurSecondaire),
           let first = arr.first {
            couleurSecondaire = first
        } else {
            couleurSecondaire = try? container.decode(Couleur.self, forKey: .couleurSecondaire)
        }

        couleurSecondaireCustom = try container.decodeIfPresent(CouleurCustom.self, forKey: .couleurSecondaireCustom)
        finition = try container.decodeIfPresent(Finition.self, forKey: .finition)

        // Migration typeDeNage (ancien, scalaire) → typesDeNage (nouveau, array)
        typesDeNage = try container.decodeIfPresent([TypeDeNage].self, forKey: .typesDeNage)
        if typesDeNage == nil,
           let old = try? container.decodeIfPresent(TypeDeNage.self, forKey: .typeDeNage) {
            typesDeNage = [old]
        }

        profondeurNageMin = try container.decodeIfPresent(Double.self, forKey: .profondeurNageMin)
        profondeurNageMax = try container.decodeIfPresent(Double.self, forKey: .profondeurNageMax)
        vitesseTraineMin  = try container.decodeIfPresent(Double.self, forKey: .vitesseTraineMin)
        vitesseTraineMax  = try container.decodeIfPresent(Double.self, forKey: .vitesseTraineMax)

        notes       = try container.decodeIfPresent(String.self, forKey: .notes)
        photoBase64 = try container.decodeIfPresent(String.self, forKey: .photoBase64)
        // photoPath est intentionnellement ignoré — les photos anciennes sont
        // chargées depuis le disque par LeurreMigrationService

        contraste        = try container.decodeIfPresent(Contraste.self, forKey: .contraste)
        zonesAdaptees    = try container.decodeIfPresent([Zone].self, forKey: .zonesAdaptees)
        especesCibles    = try container.decodeIfPresent([String].self, forKey: .especesCibles)
        positionsSpread  = try container.decodeIfPresent([PositionSpread].self, forKey: .positionsSpread)
        conditionsOptimales = try container.decodeIfPresent(ConditionsOptimales.self, forKey: .conditionsOptimales)

        isComputed       = try container.decodeIfPresent(Bool.self, forKey: .isComputed)
        notesMotsCles    = try container.decodeIfPresent([String].self, forKey: .notesMotsCles)
        qualiteDataScore = try container.decodeIfPresent(Int.self, forKey: .qualiteDataScore)
        quantite         = try container.decodeIfPresent(Int.self, forKey: .quantite)
        dateAjout        = try container.decodeIfPresent(Date.self, forKey: .dateAjout)
    }

    // MARK: - Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(nom, forKey: .nom)
        try container.encode(marque, forKey: .marque)
        try container.encodeIfPresent(modele, forKey: .modele)
        try container.encode(typeLeurre, forKey: .typeLeurre)
        try container.encode(typePeche, forKey: .typePeche)
        try container.encodeIfPresent(typesPecheCompatibles, forKey: .typesPecheCompatibles)
        try container.encode(longueur, forKey: .longueur)
        try container.encodeIfPresent(poids, forKey: .poids)
        try container.encode(couleurPrincipale, forKey: .couleurPrincipale)
        try container.encodeIfPresent(couleurPrincipaleCustom, forKey: .couleurPrincipaleCustom)
        try container.encodeIfPresent(couleurSecondaire, forKey: .couleurSecondaire)
        try container.encodeIfPresent(couleurSecondaireCustom, forKey: .couleurSecondaireCustom)
        try container.encodeIfPresent(finition, forKey: .finition)
        try container.encodeIfPresent(typesDeNage, forKey: .typesDeNage)
        // Rétro-compatibilité : on encode aussi le premier type dans l'ancien champ scalaire
        if let premier = typesDeNage?.first {
            try container.encode(premier, forKey: .typeDeNage)
        }
        try container.encodeIfPresent(profondeurNageMin, forKey: .profondeurNageMin)
        try container.encodeIfPresent(profondeurNageMax, forKey: .profondeurNageMax)
        try container.encodeIfPresent(vitesseTraineMin, forKey: .vitesseTraineMin)
        try container.encodeIfPresent(vitesseTraineMax, forKey: .vitesseTraineMax)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(photoBase64, forKey: .photoBase64)
        // photoPath n'est jamais encodé — format obsolète
        try container.encodeIfPresent(contraste, forKey: .contraste)
        try container.encodeIfPresent(zonesAdaptees, forKey: .zonesAdaptees)
        try container.encodeIfPresent(especesCibles, forKey: .especesCibles)
        try container.encodeIfPresent(positionsSpread, forKey: .positionsSpread)
        try container.encodeIfPresent(conditionsOptimales, forKey: .conditionsOptimales)
        try container.encodeIfPresent(isComputed, forKey: .isComputed)
        try container.encodeIfPresent(notesMotsCles, forKey: .notesMotsCles)
        try container.encodeIfPresent(qualiteDataScore, forKey: .qualiteDataScore)
        try container.encodeIfPresent(quantite, forKey: .quantite)
        try container.encodeIfPresent(dateAjout, forKey: .dateAjout)
    }

    // MARK: - Conversion LeurreDTO → Leurre (@Model)

    /// Crée un objet Leurre SwiftData depuis ce DTO.
    /// photoData est nil par défaut — peuplé séparément par LeurreMigrationService
    /// (depuis le disque pour l'ancien format, depuis photoBase64 pour le format V4).
    func toLeurre() -> Leurre {
        Leurre(
            id: id,
            nom: nom,
            marque: marque,
            modele: modele,
            typeLeurre: typeLeurre,
            typePeche: typePeche,
            typesPecheCompatibles: typesPecheCompatibles,
            longueur: longueur,
            poids: poids,
            couleurPrincipale: couleurPrincipale,
            couleurPrincipaleCustom: couleurPrincipaleCustom,
            couleurSecondaire: couleurSecondaire,
            couleurSecondaireCustom: couleurSecondaireCustom,
            finition: finition,
            typesDeNage: typesDeNage,
            profondeurNageMin: profondeurNageMin,
            profondeurNageMax: profondeurNageMax,
            vitesseTraineMin: vitesseTraineMin,
            vitesseTraineMax: vitesseTraineMax,
            notes: notes,
            photoData: nil,
            quantite: quantite ?? 1,
            notesMotsCles: notesMotsCles ?? [],
            qualiteDataScore: qualiteDataScore ?? 0
        )
    }
}

// MARK: - LeurreDatabase et DatabaseMetadata

/// Conteneur JSON racine — structure du fichier leurres.json dans le ZIP.
/// Utilisé par LeurreMigrationService (import) et LeurreExportService (export).
struct LeurreDatabase: Codable {
    var metadata: DatabaseMetadata
    var leurres: [LeurreDTO]
}

struct DatabaseMetadata: Codable {
    var version: String
    var dateCreation: String
    var derniereMiseAJour: String?
    var nombreTotal: Int
    var proprietaire: String
    var description: String?
    var source: String?
}
