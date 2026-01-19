
//
//  LeurreWebScraperService.swift
//  Go les Picots - Module 1 Phase 2
//
//  Service d'extraction d'informations depuis les pages produits
//  - Extraction marque, modèle, description fabricant
//  - Téléchargement photo produit
//  - Extraction universelle de la description produit
//
//  Version 2.0 : Focus sur la description pour rubrique "Note"
//
//  Created: 2024-12-17
//  Updated: 2026-01-15
//

import Foundation
import UIKit

// MARK: - Modèle de données extraites

struct LeurreInfosExtraites {
    var marque: String?
    var nom: String?
    var modele: String?
    var typeLeurre: TypeLeurre?
    
    // Type de pêche (déduit du type de leurre)
    var typePeche: TypePeche?
    
    // Types de pêche compatibles (optionnel)
    var typesPecheCompatibles: [TypePeche]?
    
    // Paramètres de traîne (extraits de la description ou page)
    var profondeurMin: Double?
    var profondeurMax: Double?
    var vitesseTraineMin: Double?
    var vitesseTraineMax: Double?
    
    // Description fabricant pour la rubrique "Note"
    var descriptionFabricant: String?
    
    // URL de la photo principale
    var urlPhoto: String?
    
    // Infos brutes pour debugging
    var pageTitle: String?
    var pageURL: String
}

// MARK: - Erreurs

enum ScrapingError: LocalizedError {
    case urlInvalide
    case reseauIndisponible
    case pageInaccessible
    case extractionEchouee
    case aucuneInfoTrouvee
    
    var errorDescription: String? {
        switch self {
        case .urlInvalide:
            return "L'URL fournie n'est pas valide"
        case .reseauIndisponible:
            return "Impossible de se connecter au site"
        case .pageInaccessible:
            return "La page n'a pas pu être chargée"
        case .extractionEchouee:
            return "Erreur lors de l'extraction des données"
        case .aucuneInfoTrouvee:
            return "Aucune information de leurre trouvée sur cette page"
        }
    }
}

// MARK: - Service Principal

class LeurreWebScraperService {
    
    static let shared = LeurreWebScraperService()
    
    private init() {}
    
    // MARK: - Extraction principale
    
    /// Extrait les informations d'un leurre depuis une URL
    func extraireInfosDepuisURL(_ urlString: String) async throws -> LeurreInfosExtraites {
        // 1. Valider l'URL
        guard let url = URL(string: urlString) else {
            throw ScrapingError.urlInvalide
        }
        
        // 2. Télécharger le HTML
        let html = try await telechargerHTML(url: url)
        
        // 3. Extraire les informations selon le site
        let infos = try extraireInfos(html: html, url: urlString)
        
        return infos
    }
    
    // MARK: - Téléchargement HTML
    
    private func telechargerHTML(url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // User-Agent pour éviter les blocages
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ScrapingError.pageInaccessible
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                throw ScrapingError.extractionEchouee
            }
            
            print("✅ HTML téléchargé : \(html.count) caractères")
            return html
            
        } catch {
            print("❌ Erreur réseau : \(error)")
            throw ScrapingError.reseauIndisponible
        }
    }
    
    // MARK: - Extraction d'informations
    
    private func extraireInfos(html: String, url: String) throws -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Détecter le type de site
        if url.contains("rapala.fr") || url.contains("rapala.com") {
            infos = extraireRapala(html: html, url: url)
        } else if url.contains("pecheur.com") {
            infos = extrairePecheur(html: html, url: url)
        } else if url.contains("decathlon.fr") {
            infos = extraireDecathlon(html: html, url: url)
        } else if url.contains("nomadtackle.com") {
            infos = extraireNomadTackle(html: html, url: url)
        } else if url.contains("walmart.com") {
            infos = extraireWalmart(html: html, url: url)
        } else if url.contains("despoissonssigrands.com") {
            infos = extraireDesPoissonsSiGrands(html: html, url: url)
        } else if url.contains("pechextreme.com") {
            infos = extrairePechExtreme(html: html, url: url)
        } else if url.contains("flashmer.com") {
            infos = extraireFlashmer(html: html, url: url)
        } else {
            // Parser universel basique
            infos = extraireUniversel(html: html, url: url)
        }
        
        // Validation : au moins une info utile
        if infos.marque == nil && infos.nom == nil && infos.descriptionFabricant == nil {
            throw ScrapingError.aucuneInfoTrouvee
        }
        
        return infos
    }
    
    // MARK: - Parsers spécifiques
    
    /// Parser pour Rapala.fr
    private func extraireRapala(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Marque
        infos.marque = "Rapala"
        
        // Extraire le nom depuis l'URL
        if let nomProduit = extraireDepuisURL(url: url, pattern: "/([a-z0-9-]+)(?:\\?|$)") {
            let nomFormate = nomProduit
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
            infos.nom = nomFormate
        }
        
        // Extraire le titre de la page
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            
            if infos.nom == nil {
                infos.nom = titre.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Extraire la description
        infos.descriptionFabricant = extraireDescription(html: html)
        
        // Extraire l'URL de la première image produit
        infos.urlPhoto = extrairePremiereImage(html: html)
        
        // Détecter le type de leurre
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        // Déduire le type de pêche depuis le type de leurre
        if let typeLeurre = infos.typeLeurre {
            let typePechePrincipal = deduireTypePeche(depuis: typeLeurre)
            infos.typePeche = typePechePrincipal
            infos.typesPecheCompatibles = deduireTypesPecheCompatibles(depuis: typeLeurre, principal: typePechePrincipal)
        }
        
        
        // Extraire les paramètres de traîne
        let params = extraireParametresTraine(html: html, description: infos.descriptionFabricant)
        infos.profondeurMin = params.profMin
        infos.profondeurMax = params.profMax
        infos.vitesseTraineMin = params.vitMin
        infos.vitesseTraineMax = params.vitMax
        
        return infos
    }
    
    /// Parser pour Pêcheur.com
    private func extrairePecheur(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Extraire le titre
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            
            // Format typique : "MARQUE NOM - Longueur - Poids | Pêcheur.com"
            let composants = titre.components(separatedBy: "|")
            if let produit = composants.first?.trimmingCharacters(in: .whitespaces) {
                let parties = produit.components(separatedBy: " - ")
                if let premierePart = parties.first?.trimmingCharacters(in: .whitespaces) {
                    // Extraire marque et nom
                    let mots = premierePart.components(separatedBy: " ")
                    if mots.count > 1 {
                        infos.marque = mots.first
                        infos.nom = mots.dropFirst().joined(separator: " ")
                    } else {
                        infos.nom = premierePart
                    }
                }
            }
        }
        
        // Extraire la description
        infos.descriptionFabricant = extraireDescription(html: html)
        
        // Extraire l'URL photo
        infos.urlPhoto = extrairePremiereImage(html: html)
        
        // Détecter type de leurre
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        // Déduire le type de pêche depuis le type de leurre
        if let typeLeurre = infos.typeLeurre {
            let typePechePrincipal = deduireTypePeche(depuis: typeLeurre)
            infos.typePeche = typePechePrincipal
            infos.typesPecheCompatibles = deduireTypesPecheCompatibles(depuis: typeLeurre, principal: typePechePrincipal)
        }
        
        
        // Extraire les paramètres de traîne
        let params = extraireParametresTraine(html: html, description: infos.descriptionFabricant)
        infos.profondeurMin = params.profMin
        infos.profondeurMax = params.profMax
        infos.vitesseTraineMin = params.vitMin
        infos.vitesseTraineMax = params.vitMax
        
        return infos
    }
    
    /// Parser pour Decathlon.fr
    private func extraireDecathlon(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Marque
        infos.marque = "Decathlon"
        
        // Extraire titre
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            infos.nom = titre.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces)
        }
        
        // Extraire la description
        infos.descriptionFabricant = extraireDescription(html: html)
        
        // Extraire photo
        infos.urlPhoto = extrairePremiereImage(html: html)
        
        // Détecter type
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        // Déduire le type de pêche depuis le type de leurre
        if let typeLeurre = infos.typeLeurre {
            let typePechePrincipal = deduireTypePeche(depuis: typeLeurre)
            infos.typePeche = typePechePrincipal
            infos.typesPecheCompatibles = deduireTypesPecheCompatibles(depuis: typeLeurre, principal: typePechePrincipal)
        }
        
        
        // Extraire les paramètres de traîne
        let params = extraireParametresTraine(html: html, description: infos.descriptionFabricant)
        infos.profondeurMin = params.profMin
        infos.profondeurMax = params.profMax
        infos.vitesseTraineMin = params.vitMin
        infos.vitesseTraineMax = params.vitMax
        
        return infos
    }
    
    /// Parser pour NomadTackle.com
    private func extraireNomadTackle(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Marque
        infos.marque = "Nomad Design"
        
        // Extraire titre
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            infos.nom = titre.components(separatedBy: "–").first?.trimmingCharacters(in: .whitespaces)
        }
        
        // Extraire la description
        infos.descriptionFabricant = extraireDescription(html: html)
        
        // Extraire photo
        infos.urlPhoto = extrairePremiereImage(html: html)
        
        // Détecter type
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        // Déduire le type de pêche depuis le type de leurre
        if let typeLeurre = infos.typeLeurre {
            let typePechePrincipal = deduireTypePeche(depuis: typeLeurre)
            infos.typePeche = typePechePrincipal
            infos.typesPecheCompatibles = deduireTypesPecheCompatibles(depuis: typeLeurre, principal: typePechePrincipal)
        }
        
        
        // Extraire les paramètres de traîne
        let params = extraireParametresTraine(html: html, description: infos.descriptionFabricant)
        infos.profondeurMin = params.profMin
        infos.profondeurMax = params.profMax
        infos.vitesseTraineMin = params.vitMin
        infos.vitesseTraineMax = params.vitMax
        
        return infos
    }
    
    /// Parser pour Walmart.com
    private func extraireWalmart(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Extraire titre
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            infos.nom = titre.components(separatedBy: "-").first?.trimmingCharacters(in: .whitespaces)
        }
        
        // Extraire la description
        infos.descriptionFabricant = extraireDescription(html: html)
        
        // Extraire photo
        infos.urlPhoto = extrairePremiereImage(html: html)
        
        // Détecter type
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        // Déduire le type de pêche depuis le type de leurre
        if let typeLeurre = infos.typeLeurre {
            let typePechePrincipal = deduireTypePeche(depuis: typeLeurre)
            infos.typePeche = typePechePrincipal
            infos.typesPecheCompatibles = deduireTypesPecheCompatibles(depuis: typeLeurre, principal: typePechePrincipal)
        }
        
        
        // Extraire les paramètres de traîne
        let params = extraireParametresTraine(html: html, description: infos.descriptionFabricant)
        infos.profondeurMin = params.profMin
        infos.profondeurMax = params.profMax
        infos.vitesseTraineMin = params.vitMin
        infos.vitesseTraineMax = params.vitMax
        
        return infos
    }
    
    /// Parser pour DesPoissonsGrands.com
    private func extraireDesPoissonsSiGrands(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Extraction depuis Open Graph
        if let titre = extraireMetaProperty(html: html, property: "og:title") {
            infos.pageTitle = titre
            let composants = titre.components(separatedBy: "-")
            if composants.count >= 2 {
                infos.marque = composants[0].trimmingCharacters(in: .whitespaces)
                infos.nom = composants[1].trimmingCharacters(in: .whitespaces)
            } else {
                infos.nom = titre
            }
        }
        
        // Extraire la description
        infos.descriptionFabricant = extraireDescription(html: html)
        
        // Extraire photo
        if let ogImage = extraireMetaProperty(html: html, property: "og:image") {
            infos.urlPhoto = ogImage
        } else {
            infos.urlPhoto = extrairePremiereImage(html: html)
        }
        
        // Détecter type
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        // Déduire le type de pêche depuis le type de leurre
        if let typeLeurre = infos.typeLeurre {
            let typePechePrincipal = deduireTypePeche(depuis: typeLeurre)
            infos.typePeche = typePechePrincipal
            infos.typesPecheCompatibles = deduireTypesPecheCompatibles(depuis: typeLeurre, principal: typePechePrincipal)
        }
        
        
        // Extraire les paramètres de traîne
        let params = extraireParametresTraine(html: html, description: infos.descriptionFabricant)
        infos.profondeurMin = params.profMin
        infos.profondeurMax = params.profMax
        infos.vitesseTraineMin = params.vitMin
        infos.vitesseTraineMax = params.vitMax
        
        return infos
    }
    
    /// Parser pour PechExtreme.com
    private func extrairePechExtreme(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Extraction depuis balise title
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            infos.nom = titre.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces)
        }
        
        // Extraire la description
        infos.descriptionFabricant = extraireDescription(html: html)
        
        // Extraire photo
        infos.urlPhoto = extrairePremiereImage(html: html)
        
        // Détecter type
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        // Déduire le type de pêche depuis le type de leurre
        if let typeLeurre = infos.typeLeurre {
            let typePechePrincipal = deduireTypePeche(depuis: typeLeurre)
            infos.typePeche = typePechePrincipal
            infos.typesPecheCompatibles = deduireTypesPecheCompatibles(depuis: typeLeurre, principal: typePechePrincipal)
        }
        
        
        // Extraire les paramètres de traîne
        let params = extraireParametresTraine(html: html, description: infos.descriptionFabricant)
        infos.profondeurMin = params.profMin
        infos.profondeurMax = params.profMax
        infos.vitesseTraineMin = params.vitMin
        infos.vitesseTraineMax = params.vitMax
        
        return infos
    }
    
    /// Parser pour Flashmer.com
    private func extraireFlashmer(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Extraction depuis Open Graph ou META
        if let titre = extraireMetaProperty(html: html, property: "og:title") {
            infos.pageTitle = titre
            infos.nom = titre
        } else if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            infos.nom = titre.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces)
        }
        
        // Extraire marque (souvent "Flashmer" ou depuis la page)
        if let marque = extraireContenuClass(html: html, className: "product-manufacturer") {
            infos.marque = marque
        } else {
            infos.marque = "Flashmer"
        }
        
        // Extraire la description (prioritaire pour Flashmer)
        infos.descriptionFabricant = extraireDescription(html: html)
        
        // Extraire photo
        if let ogImage = extraireMetaProperty(html: html, property: "og:image") {
            infos.urlPhoto = ogImage
        } else {
            infos.urlPhoto = extraireImageProduit(html: html, patterns: ["product-cover", "product-image"])
        }
        
        // Détecter type
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        // Déduire le type de pêche depuis le type de leurre
        if let typeLeurre = infos.typeLeurre {
            let typePechePrincipal = deduireTypePeche(depuis: typeLeurre)
            infos.typePeche = typePechePrincipal
            infos.typesPecheCompatibles = deduireTypesPecheCompatibles(depuis: typeLeurre, principal: typePechePrincipal)
        }
        
        
        // Extraire les paramètres de traîne
        let params = extraireParametresTraine(html: html, description: infos.descriptionFabricant)
        infos.profondeurMin = params.profMin
        infos.profondeurMax = params.profMax
        infos.vitesseTraineMin = params.vitMin
        infos.vitesseTraineMax = params.vitMax
        
        return infos
    }
    
    /// Parser universel (fallback)
    private func extraireUniversel(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Titre
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            infos.nom = titre.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces)
        }
        
        // Extraire la description (universelle)
        infos.descriptionFabricant = extraireDescription(html: html)
        
        // Photo
        infos.urlPhoto = extrairePremiereImage(html: html)
        
        // Type
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        return infos
    }
    
    // MARK: - Extraction de la description (NOUVELLE FONCTIONNALITÉ)
    
    /// Extrait la description produit selon plusieurs stratégies
    private func extraireDescription(html: String) -> String? {
        // 1. Tenter extraction META (rapide et fiable)
        if let description = extraireMetaDescription(html: html) {
            return nettoyerDescription(description)
        }
        
        // 2. Tenter extraction JSON-LD
        if let description = extraireDescriptionJSONLD(html: html) {
            return nettoyerDescription(description)
        }
        
        // 3. Tenter extraction depuis classes communes
        if let description = extraireDescriptionDepuisClasses(html: html) {
            return nettoyerDescription(description)
        }
        
        // 4. Fallback : heuristique
        if let description = extraireDescriptionHeuristique(html: html) {
            return nettoyerDescription(description)
        }
        
        return nil
    }
    
    /// Extrait la description depuis les balises META
    private func extraireMetaDescription(html: String) -> String? {
        // Ordre de priorité des META tags
        let metaTags = [
            "og:description",      // Open Graph (prioritaire)
            "description",          // META standard
            "twitter:description",  // Twitter Card
            "product:description"   // Product schema
        ]
        
        for tag in metaTags {
            if let description = extraireMetaProperty(html: html, property: tag) {
                if !description.isEmpty && description.count > 20 {
                    print("📝 Description trouvée (META \(tag))")
                    return description
                }
            }
        }
        
        return nil
    }
    
    /// Extrait la description depuis JSON-LD structuré
    private func extraireDescriptionJSONLD(html: String) -> String? {
        let pattern = "<script[^>]*type=[\"']application/ld\\+json[\"'][^>]*>([\\s\\S]*?)</script>"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)
        
        for match in matches {
            guard let jsonRange = Range(match.range(at: 1), in: html) else { continue }
            let jsonString = String(html[jsonRange])
            
            // Parser le JSON
            guard let jsonData = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                continue
            }
            
            // Chercher "description" dans le JSON
            if let description = json["description"] as? String {
                if description.count > 20 {
                    print("📝 Description trouvée (JSON-LD)")
                    return description
                }
            }
        }
        
        return nil
    }
    
    /// Extrait la description depuis les classes HTML communes
    private func extraireDescriptionDepuisClasses(html: String) -> String? {
        // Liste des classes communes pour les descriptions produit
        let classesCommunes = [
            "product-description",
            "product-details",
            "product-info",
            "description",
            "designation",
            "product-desc",
            "prod-description",
            "item-description",
            "fiche-produit",
            "detail-produit"
        ]
        
        for className in classesCommunes {
            if let contenu = extraireContenuClass(html: html, className: className) {
                if contenu.count > 20 {
                    print("📝 Description trouvée (classe .\(className))")
                    return contenu
                }
            }
        }
        
        return nil
    }
    
    /// Extraction heuristique (fallback intelligent)
    private func extraireDescriptionHeuristique(html: String) -> String? {
        // Chercher des blocs <p> ou <div> avec beaucoup de texte après le titre
        let patterns = [
            "<div[^>]*itemprop=[\"']description[\"'][^>]*>([\\s\\S]*?)</div>",
            "<section[^>]*class=[\"'][^\"']*description[^\"']*[\"'][^>]*>([\\s\\S]*?)</section>",
            "<article[^>]*>([\\s\\S]*?)</article>"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..., in: html)
                if let match = regex.firstMatch(in: html, range: range),
                   let contentRange = Range(match.range(at: 1), in: html) {
                    let contenu = String(html[contentRange])
                    
                    // Nettoyer et vérifier longueur
                    let texte = contenu
                        .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if texte.count > 50 {
                        print("📝 Description trouvée (heuristique)")
                        return texte
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Nettoie une description extraite
    private func nettoyerDescription(_ description: String) -> String {
        var texte = description
        
        // 1. Supprimer balises HTML résiduelles
        texte = texte.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        
        // 2. Décoder entités HTML
        let entites: [String: String] = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&eacute;": "é",
            "&egrave;": "è",
            "&ecirc;": "ê",
            "&agrave;": "à",
            "&ccedil;": "ç",
            "&euro;": "€"
        ]
        
        for (entite, remplacement) in entites {
            texte = texte.replacingOccurrences(of: entite, with: remplacement)
        }
        
        // 3. Supprimer phrases commerciales parasites
        let parasites = [
            "Livraison gratuite",
            "Ajouter au panier",
            "En stock",
            "Disponible",
            "Rupture de stock",
            "Ajouter à la liste",
            "Comparer",
            "Prix :",
            "€",
            "CHF",
            "USD",
            "$"
        ]
        
        for parasite in parasites {
            texte = texte.replacingOccurrences(of: parasite, with: "", options: .caseInsensitive)
        }
        
        // 4. Normaliser espaces multiples
        texte = texte.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        texte = texte.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 5. Limiter longueur à 500 caractères
        if texte.count > 500 {
            let index = texte.index(texte.startIndex, offsetBy: 497)
            texte = String(texte[..<index]) + "..."
        }
        
        return texte
    }
    
    // MARK: - Utilitaires d'extraction
    
    /// Extrait une balise HTML simple (ex: <title>)
    private func extraireBalise(html: String, tag: String) -> String? {
        let pattern = "<\(tag)[^>]*>([\\s\\S]*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let contentRange = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        return String(html[contentRange])
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extrait un pattern depuis l'URL
    private func extraireDepuisURL(url: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(url.startIndex..., in: url)
        guard let match = regex.firstMatch(in: url, range: range),
              let matchRange = Range(match.range(at: 1), in: url) else {
            return nil
        }
        
        return String(url[matchRange])
    }
    
    /// Extrait la première image produit
    private func extrairePremiereImage(html: String) -> String? {
        let patterns = [
            "<img[^>]*src=[\"']([^\"']+product[^\"']+)[\"']",
            "<img[^>]*src=[\"']([^\"']+\\.jpg)[\"']",
            "<img[^>]*src=[\"']([^\"']+\\.jpeg)[\"']",
            "<img[^>]*src=[\"']([^\"']+\\.png)[\"']"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..., in: html)
                if let match = regex.firstMatch(in: html, range: range),
                   let urlRange = Range(match.range(at: 1), in: html) {
                    var url = String(html[urlRange])
                    
                    // Nettoyer l'URL
                    url = url.replacingOccurrences(of: "&amp;", with: "&")
                    
                    // Compléter si URL relative
                    if url.hasPrefix("//") {
                        url = "https:" + url
                    } else if url.hasPrefix("/") {
                        if let baseURL = extraireDomaineBase(html: html) {
                            url = baseURL + url
                        }
                    }
                    
                    if URL(string: url) != nil {
                        print("📸 Photo trouvée : \(url)")
                        return url
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Extrait le domaine de base depuis le HTML
    private func extraireDomaineBase(html: String) -> String? {
        let pattern = "<base[^>]*href=[\"']([^\"']+)[\"']"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let urlRange = Range(match.range(at: 1), in: html) {
            return String(html[urlRange])
        }
        return nil
    }
    
    /// Détecte le type de leurre depuis un texte
    private func detecterTypeLeurre(texte: String) -> TypeLeurre? {
        let texteNormalise = texte.lowercased()
        
        let correspondances: [(mots: [String], type: TypeLeurre)] = [
            (["poisson nageur", "crankbait", "crank"], .poissonNageur),
            (["popper"], .popper),
            (["stickbait", "stick bait"], .stickbait),
            (["jig métallique", "jig metal", "jigging"], .jigMetallique),
            (["jupe", "octopus"], .leurreAJupe),
            (["cuiller", "spoon"], .cuiller),
            (["souple", "soft"], .leurreSouple),
            (["squid"], .squid),
            (["madai"], .madai),
            (["inchiku"], .inchiku)
        ]
        
        for (mots, type) in correspondances {
            if mots.contains(where: { texteNormalise.contains($0) }) {
                return type
            }
        }
        
        return nil
    }
    
    /// Déduit le type de pêche principal depuis le type de leurre
    private func deduireTypePeche(depuis typeLeurre: TypeLeurre) -> TypePeche {
        // Types exclusivement lancer
        let typesLancerSeuls: [TypeLeurre] = [
            .popper,
            .stickbait,
            .stickbaitFlottant,
            .stickbaitCoulant,
            .jigMetallique,
            .jigStickbait,
            .jigStickbaitCoulant,
            .jigVibrant
        ]
        
        if typesLancerSeuls.contains(typeLeurre) {
            return .lancer
        }
        
        // Types principalement traîne
        let typesTrainePreferentiel: [TypeLeurre] = [
            .poissonNageur,
            .poissonNageurPlongeant,
            .leurreAJupe,
            .cuiller,
            .squid
        ]
        
        if typesTrainePreferentiel.contains(typeLeurre) {
            return .traine
        }
        
        // Par défaut : traîne
        return .traine
    }
    
    /// Déduit les types de pêche compatibles depuis le type de leurre
    private func deduireTypesPecheCompatibles(depuis typeLeurre: TypeLeurre, principal: TypePeche) -> [TypePeche] {
        var compatibles: [TypePeche] = [principal]
        
        // Types polyvalents (traîne + lancer)
        let typesPolyvalents: [TypeLeurre] = [
            .poissonNageur,
            .poissonNageurPlongeant,
            .cuiller,
            .leurreSouple
        ]
        
        if typesPolyvalents.contains(typeLeurre) {
            // Ajouter l'autre technique
            if principal == .traine {
                compatibles.append(.lancer)
            } else {
                compatibles.append(.traine)
            }
        }
        
        // Types exclusivement lancer (ne jamais ajouter traîne)
        let typesLancerSeuls: [TypeLeurre] = [
            .popper,
            .stickbait,
            .stickbaitFlottant,
            .stickbaitCoulant,
            .jigMetallique,
            .jigStickbait,
            .jigStickbaitCoulant,
            .jigVibrant
        ]
        
        if typesLancerSeuls.contains(typeLeurre) {
            compatibles = [.lancer]
        }
        
        return compatibles
    }
    
    /// Extrait les paramètres de traîne depuis le HTML ou la description
    private func extraireParametresTraine(html: String, description: String?) -> (profMin: Double?, profMax: Double?, vitMin: Double?, vitMax: Double?) {
        var profMin: Double? = nil
        var profMax: Double? = nil
        var vitMin: Double? = nil
        var vitMax: Double? = nil
        
        // Texte à analyser (description + HTML)
        let texteComplet = [description, html].compactMap { $0 }.joined(separator: " ")
        let texte = texteComplet.lowercased()
        
        // Patterns pour la profondeur (en mètres)
        // Ex: "2-6m", "plonge à 3m", "nage entre 1 et 4m", "diving depth: 2-5m"
        let patternsProfondeur = [
            "(\\d+(?:[.,]\\d+)?)\\s*(?:-|à|to)\\s*(\\d+(?:[.,]\\d+)?)\\s*(?:m|mètres?|meters?)",
            "(?:profondeur|depth|plonge|dive|diving).*?(\\d+(?:[.,]\\d+)?)\\s*(?:-|à|to)\\s*(\\d+(?:[.,]\\d+)?)\\s*(?:m|mètres?|meters?)",
            "(\\d+(?:[.,]\\d+)?)\\s*(?:-|/)\\s*(\\d+(?:[.,]\\d+)?)\\s*(?:m|mètres?|meters?)"
        ]
        
        for pattern in patternsProfondeur {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(texte.startIndex..., in: texte)
                if let match = regex.firstMatch(in: texte, range: range),
                   let range1 = Range(match.range(at: 1), in: texte),
                   let range2 = Range(match.range(at: 2), in: texte) {
                    let val1 = String(texte[range1]).replacingOccurrences(of: ",", with: ".")
                    let val2 = String(texte[range2]).replacingOccurrences(of: ",", with: ".")
                    profMin = Double(val1)
                    profMax = Double(val2)
                    break
                }
            }
        }
        
        // Patterns pour la vitesse (en nœuds)
        // Ex: "4-8 knots", "vitesse 2 à 6 nœuds", "troll speed: 3-7kn"
        let patternsVitesse = [
            "(\\d+(?:[.,]\\d+)?)\\s*(?:-|à|to)\\s*(\\d+(?:[.,]\\d+)?)\\s*(?:kn|knots?|nœuds?|noeuds?)",
            "(?:vitesse|speed|troll).*?(\\d+(?:[.,]\\d+)?)\\s*(?:-|à|to)\\s*(\\d+(?:[.,]\\d+)?)\\s*(?:kn|knots?|nœuds?|noeuds?)",
            "(\\d+(?:[.,]\\d+)?)\\s*(?:-|/)\\s*(\\d+(?:[.,]\\d+)?)\\s*(?:kn|knots?|nœuds?|noeuds?)"
        ]
        
        for pattern in patternsVitesse {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(texte.startIndex..., in: texte)
                if let match = regex.firstMatch(in: texte, range: range),
                   let range1 = Range(match.range(at: 1), in: texte),
                   let range2 = Range(match.range(at: 2), in: texte) {
                    let val1 = String(texte[range1]).replacingOccurrences(of: ",", with: ".")
                    let val2 = String(texte[range2]).replacingOccurrences(of: ",", with: ".")
                    vitMin = Double(val1)
                    vitMax = Double(val2)
                    break
                }
            }
        }
        
        return (profMin, profMax, vitMin, vitMax)
    }
    
    // MARK: - Utilitaires PrestaShop
    
    /// Extrait les métadonnées Open Graph
    private func extraireMetaProperty(html: String, property: String) -> String? {
        let patterns = [
            "<meta[^>]*property=[\"']\(property)[\"'][^>]*content=[\"']([^\"']+)[\"']",
            "<meta[^>]*name=[\"']\(property)[\"'][^>]*content=[\"']([^\"']+)[\"']",
            "<meta[^>]*content=[\"']([^\"']+)[\"'][^>]*property=[\"']\(property)[\"']",
            "<meta[^>]*content=[\"']([^\"']+)[\"'][^>]*name=[\"']\(property)[\"']"
        ]
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            
            let range = NSRange(html.startIndex..., in: html)
            if let match = regex.firstMatch(in: html, range: range),
               let contentRange = Range(match.range(at: 1), in: html) {
                return String(html[contentRange])
                    .replacingOccurrences(of: "&nbsp;", with: " ")
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
    
    /// Extrait le contenu d'un élément avec une classe spécifique
    private func extraireContenuClass(html: String, className: String) -> String? {
        let patterns = [
            "<div[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*>([\\s\\S]*?)</div>",
            "<span[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*>([\\s\\S]*?)</span>",
            "<h1[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*>([\\s\\S]*?)</h1>",
            "<a[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*>([\\s\\S]*?)</a>",
            "<p[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*>([\\s\\S]*?)</p>",
            "<section[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*>([\\s\\S]*?)</section>"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) {
                let range = NSRange(html.startIndex..., in: html)
                if let match = regex.firstMatch(in: html, range: range),
                   let contentRange = Range(match.range(at: 1), in: html) {
                    let contenu = String(html[contentRange])
                        .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                        .replacingOccurrences(of: "&nbsp;", with: " ")
                        .replacingOccurrences(of: "&amp;", with: "&")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !contenu.isEmpty {
                        return contenu
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Extrait une image produit avec priorité aux classes spécifiques
    private func extraireImageProduit(html: String, patterns: [String]) -> String? {
        for className in patterns {
            let pattern = "<img[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*src=[\"']([^\"']+)[\"']"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..., in: html)
                if let match = regex.firstMatch(in: html, range: range),
                   let urlRange = Range(match.range(at: 1), in: html) {
                    var url = String(html[urlRange])
                    url = nettoyerURLImage(url, html: html)
                    if URL(string: url) != nil {
                        print("📸 Photo trouvée (classe \(className)) : \(url)")
                        return url
                    }
                }
            }
        }
        
        return extrairePremiereImage(html: html)
    }
    
    /// Nettoie une URL d'image
    private func nettoyerURLImage(_ url: String, html: String) -> String {
        var urlNettoyee = url
        
        urlNettoyee = urlNettoyee.replacingOccurrences(of: "&amp;", with: "&")
        
        if urlNettoyee.hasPrefix("//") {
            urlNettoyee = "https:" + urlNettoyee
        } else if urlNettoyee.hasPrefix("/") {
            if let baseURL = extraireDomaineBase(html: html) {
                urlNettoyee = baseURL + urlNettoyee
            }
        }
        
        return urlNettoyee
    }
    
    // MARK: - Téléchargement d'image
    
    /// Télécharge une image depuis une URL
    func telechargerImage(urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw ScrapingError.urlInvalide
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw ScrapingError.extractionEchouee
        }
        
        return image
    }
}
