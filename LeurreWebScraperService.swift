//
//  LeurreWebScraperService.swift
//  Go les Picots - Module 1 Phase 2
//
//  Service d'extraction d'informations depuis les pages produits
//  - Extraction marque, modèle, dimensions
//  - Téléchargement photo produit
//  - Détection des variantes (tailles multiples)
//
//  Phase 1 : Extraction basique + pré-remplissage manuel
//
//  Created: 2024-12-17
//

import Foundation
import UIKit

// MARK: - Modèle de données extraites

struct LeurreInfosExtraites {
    var marque: String?
    var nom: String?
    var modele: String?
    var typeLeurre: TypeLeurre?
    
    // Variantes disponibles (si la page présente plusieurs tailles)
    var variantes: [VarianteLeurre] = []
    
    // URL de la photo principale
    var urlPhoto: String?
    
    // Infos brutes pour debugging
    var pageTitle: String?
    var pageURL: String
}

struct VarianteLeurre: Identifiable {
    let id = UUID()
    var longueur: Double?       // cm
    var poids: Double?          // g
    var profondeurMin: Double?  // m
    var profondeurMax: Double?  // m
    var description: String     // Ex: "9 cm - 15g"
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
        } else {
            // Parser universel basique
            infos = extraireUniversel(html: html, url: url)
        }
        
        // Validation : au moins une info utile
        if infos.marque == nil && infos.nom == nil && infos.variantes.isEmpty {
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
        // Ex: "https://www.rapala.fr/eu_fr/countdown-magnum"
        if let nomProduit = extraireDepuisURL(url: url, pattern: "/([a-z0-9-]+)(?:\\?|$)") {
            let nomFormate = nomProduit
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
            infos.nom = nomFormate
        }
        
        // Extraire le titre de la page
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            
            // Le titre contient souvent le nom complet
            if infos.nom == nil {
                infos.nom = titre.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Extraire les variantes depuis le contenu
        // Rechercher des patterns comme "9 cm", "11 cm", "14g", "22g"
        infos.variantes = extraireVariantes(html: html)
        
        // Extraire l'URL de la première image produit
        infos.urlPhoto = extrairePremiereImage(html: html)
        
        // Détecter le type de leurre depuis le titre ou la description
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        return infos
    }
    
    /// Parser pour Pêcheur.com
    private func extrairePecheur(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Extraire le titre
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            
            // Format typique : "MARQUE NOM - Longueur - Poids | Pêcheur.com"
            let composants = titre.components(separatedBy: "|").first?
                .trimmingCharacters(in: .whitespaces)
                .components(separatedBy: "-")
            
            if let premier = composants?.first {
                let mots = premier.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
                if mots.count >= 2 {
                    infos.marque = mots[0]
                    infos.nom = mots.dropFirst().joined(separator: " ")
                }
            }
        }
        
        // Variantes
        infos.variantes = extraireVariantes(html: html)
        
        // Photo
        infos.urlPhoto = extrairePremiereImage(html: html)
        
        // Type
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        return infos
    }
    
    /// Parser pour Decathlon.fr
    private func extraireDecathlon(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        infos.marque = "Decathlon"
        
        // Extraire le titre
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            infos.nom = titre.components(separatedBy: "|").first?.trimmingCharacters(in: .whitespaces)
        }
        
        // Variantes
        infos.variantes = extraireVariantes(html: html)
        
        // Photo
        infos.urlPhoto = extrairePremiereImage(html: html)
        
        // Type
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        return infos
    }
    
    /// Parser pour Nomad Tackle (nomadtackle.com.au)
    private func extraireNomadTackle(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Marque
        infos.marque = "Nomad"
        
        // Vérifier si c'est une page de collection ou une page produit individuelle
        let estPageCollection = url.contains("/collections/")
        
        if estPageCollection {
            // Page de collection : extraire le nom depuis l'URL
            if let nomProduit = extraireDepuisURL(url: url, pattern: "/collections/([a-z0-9-]+)(?:#|\\?|$)") {
                let nomFormate = nomProduit
                    .replacingOccurrences(of: "-", with: " ")
                    .uppercased() // Nomad utilise souvent des acronymes en majuscules (DTX, etc.)
                infos.nom = nomFormate
            }
            
            // Sur les pages de collection, chercher le titre principal
            if let h1 = extraireBalise(html: html, tag: "h1") {
                infos.nom = h1.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            // Page produit individuelle : extraction standard
            if let titre = extraireBalise(html: html, tag: "title") {
                infos.pageTitle = titre
                
                // Format typique : "DTX Minnow - Nomad Tackle" ou "DTX Offshore Trolling Minnow"
                let composants = titre.components(separatedBy: "-")
                if let premier = composants.first {
                    infos.nom = premier.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        // Extraire les variantes depuis la table de specs (#spec-table) ou depuis le contenu
        // Nomad utilise souvent des tableaux HTML pour présenter les variantes
        var variantes = extraireVariantesNomad(html: html)
        
        // Si pas de variantes trouvées dans la table, chercher dans le contenu général
        if variantes.isEmpty {
            variantes = extraireVariantes(html: html)
        }
        
        // Pour les pages de collection Nomad, chercher aussi les variantes dans les divs de produits
        if variantes.isEmpty && estPageCollection {
            variantes = extraireVariantesNomadCollection(html: html)
        }
        
        infos.variantes = variantes
        
        // Extraire l'URL de la première image produit
        infos.urlPhoto = extraireImageProduit(html: html, patterns: [
            "product-featured-image",
            "product-image",
            "collection-image",
            "grid-product__image"
        ])
        
        // Détecter le type de leurre depuis le titre ou l'URL
        let texteAnalyse = (infos.pageTitle ?? "") + " " + (infos.nom ?? "") + " " + url
        infos.typeLeurre = detecterTypeLeurre(texte: texteAnalyse.lowercased())
        
        // Nomad fait principalement des leurres de traîne offshore
        // Si aucun type détecté et que "trolling" est dans l'URL/titre, c'est un poisson nageur
        if infos.typeLeurre == nil && texteAnalyse.lowercased().contains("trolling") {
            infos.typeLeurre = .poissonNageur
        }
        
        // Si "minnow" dans le texte, c'est probablement un poisson nageur
        if infos.typeLeurre == nil && texteAnalyse.lowercased().contains("minnow") {
            infos.typeLeurre = .poissonNageur
        }
        
        return infos
    }
    
    /// Parser pour Walmart (walmart.com)
    private func extraireWalmart(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Extraire le titre de la page
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            
            // Format typique Walmart : "Mann's Bait Company Magnum Stretch 30 Hard Bait, Pink - Walmart.com"
            // Extraire avant le " - Walmart"
            let titreProduit = titre.components(separatedBy: " - Walmart").first?
                .trimmingCharacters(in: .whitespaces) ?? titre
            
            // Décomposer pour extraire la marque et le nom
            let composants = titreProduit.components(separatedBy: " ")
            
            if composants.count >= 2 {
                // Essayer de détecter la marque (souvent les 2-3 premiers mots)
                // Ex: "Mann's Bait Company" ou "Rapala" ou "Berkley"
                
                // Si on trouve "Bait Company" ou "'s", c'est probablement la marque
                if composants.count >= 3 && 
                   (composants[1].lowercased() == "bait" || composants[0].contains("'s")) {
                    infos.marque = composants.prefix(3).joined(separator: " ")
                    infos.nom = composants.dropFirst(3).joined(separator: " ")
                } else if composants.count >= 2 && composants[1].contains("'s") {
                    infos.marque = composants.prefix(2).joined(separator: " ")
                    infos.nom = composants.dropFirst(2).joined(separator: " ")
                } else {
                    // Par défaut : premier mot = marque
                    infos.marque = composants[0]
                    infos.nom = composants.dropFirst().joined(separator: " ")
                }
            }
        }
        
        // Extraire les variantes
        // Walmart peut avoir des informations dans le titre (ex: "30 Hard Bait" = 30cm)
        infos.variantes = extraireVariantes(html: html)
        
        // Si pas de variantes trouvées, essayer d'extraire depuis le titre
        if infos.variantes.isEmpty {
            if let titre = infos.pageTitle?.lowercased() {
                // Chercher des patterns comme "stretch 30" ou "magnum 22"
                let patternTaille = "([0-9]{1,3})\\s*(?:hard bait|lure|minnow|cm)"
                if let regex = try? NSRegularExpression(pattern: patternTaille, options: .caseInsensitive),
                   let match = regex.firstMatch(in: titre, range: NSRange(titre.startIndex..., in: titre)),
                   let tailleRange = Range(match.range(at: 1), in: titre),
                   let taille = Double(titre[tailleRange]) {
                    
                    let variante = VarianteLeurre(
                        longueur: taille,
                        description: "\(Int(taille)) cm"
                    )
                    infos.variantes.append(variante)
                }
            }
        }
        
        // Extraire l'URL de la photo
        // Walmart utilise des URLs spécifiques comme i5.walmartimages.com
        infos.urlPhoto = extraireImageWalmart(html: html)
        
        // Détecter le type de leurre
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
            
            // Si "hard bait" est dans le titre, c'est probablement un poisson nageur
            if infos.typeLeurre == nil && titre.contains("hard bait") {
                infos.typeLeurre = .poissonNageur
            }
        }
        
        return infos
    }
    
    /// Parser pour Des Poissons Si Grands (despoissonssigrands.com)
    private func extraireDesPoissonsSiGrands(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Extraire le titre de la page
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            
            // Format typique : "Marque Nom du leurre - Des Poissons Si Grands"
            let composants = titre.components(separatedBy: " - ").first?
                .trimmingCharacters(in: .whitespaces)
            
            if let nomComplet = composants {
                // Essayer de séparer marque et nom
                let mots = nomComplet.components(separatedBy: " ")
                if mots.count >= 2 {
                    infos.marque = mots[0]
                    infos.nom = mots.dropFirst().joined(separator: " ")
                } else {
                    infos.nom = nomComplet
                }
            }
        }
        
        // Extraire depuis les métadonnées (og:title, og:description)
        if let ogTitle = extraireMetaProperty(html: html, property: "og:title") {
            if infos.nom == nil {
                let mots = ogTitle.components(separatedBy: " ")
                if mots.count >= 2 {
                    infos.marque = mots[0]
                    infos.nom = mots.dropFirst().joined(separator: " ")
                }
            }
        }
        
        // Rechercher les informations produit dans les balises spécifiques
        // Chercher des classes comme "product-title", "product-name", "brand-name"
        infos = extraireDepuisClassesPresta(html: html, infos: infos)
        
        // Variantes : recherche standard
        infos.variantes = extraireVariantes(html: html)
        
        // Photo : recherche standard avec priorité aux images de produit
        infos.urlPhoto = extraireImageProduit(html: html, patterns: [
            "product-cover",
            "product-image",
            "img-fluid"
        ])
        
        // Type de leurre
        let texteAnalyse = (infos.pageTitle ?? "") + " " + (infos.nom ?? "") + " " + url
        infos.typeLeurre = detecterTypeLeurre(texte: texteAnalyse.lowercased())
        
        // Si "traine" ou "traîne" dans l'URL, c'est probablement un leurre de traîne
        if texteAnalyse.lowercased().contains("traine") {
            if infos.typeLeurre == nil {
                infos.typeLeurre = .poissonNageur
            }
        }
        
        return infos
    }
    
    /// Parser pour Pêch'Extrême (pechextreme.com)
    private func extrairePechExtreme(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Extraire le titre de la page
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            
            // Format typique : "Marque Nom - Pêch'Extrême"
            let composants = titre.components(separatedBy: " - ").first?
                .trimmingCharacters(in: .whitespaces)
            
            if let nomComplet = composants {
                // Essayer de séparer marque et nom
                let mots = nomComplet.components(separatedBy: " ")
                if mots.count >= 2 {
                    infos.marque = mots[0]
                    infos.nom = mots.dropFirst().joined(separator: " ")
                } else {
                    infos.nom = nomComplet
                }
            }
        }
        
        // Extraire depuis les métadonnées
        if let ogTitle = extraireMetaProperty(html: html, property: "og:title") {
            if infos.nom == nil {
                let mots = ogTitle.components(separatedBy: " ")
                if mots.count >= 2 {
                    infos.marque = mots[0]
                    infos.nom = mots.dropFirst().joined(separator: " ")
                }
            }
        }
        
        // Rechercher dans les classes PrestaShop
        infos = extraireDepuisClassesPresta(html: html, infos: infos)
        
        // Variantes : recherche standard
        infos.variantes = extraireVariantes(html: html)
        
        // Photo
        infos.urlPhoto = extraireImageProduit(html: html, patterns: [
            "product-cover",
            "product-image",
            "img-fluid",
            "js-qv-product-cover"
        ])
        
        // Type de leurre
        let texteAnalyse = (infos.pageTitle ?? "") + " " + (infos.nom ?? "") + " " + url
        infos.typeLeurre = detecterTypeLeurre(texte: texteAnalyse.lowercased())
        
        // Si "big-game" dans l'URL, favoriser poisson nageur ou jig
        if url.lowercased().contains("big-game") || url.lowercased().contains("leurres") {
            if infos.typeLeurre == nil {
                // Essayer de détecter depuis le contenu HTML
                if html.lowercased().contains("poisson nageur") {
                    infos.typeLeurre = .poissonNageur
                } else if html.lowercased().contains("jig") {
                    infos.typeLeurre = .jigMetallique
                }
            }
        }
        
        return infos
    }
    
    /// Parser universel (pour tous les autres sites)
    private func extraireUniversel(html: String, url: String) -> LeurreInfosExtraites {
        var infos = LeurreInfosExtraites(pageURL: url)
        
        // Extraire le titre
        if let titre = extraireBalise(html: html, tag: "title") {
            infos.pageTitle = titre
            
            // Essayer de détecter marque et nom
            let mots = titre.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if mots.count >= 2 {
                infos.marque = mots[0]
                infos.nom = mots.dropFirst().prefix(5).joined(separator: " ")
            }
        }
        
        // Variantes
        infos.variantes = extraireVariantes(html: html)
        
        // Photo
        infos.urlPhoto = extrairePremiereImage(html: html)
        
        // Type
        if let titre = infos.pageTitle?.lowercased() {
            infos.typeLeurre = detecterTypeLeurre(texte: titre)
        }
        
        return infos
    }
    
    // MARK: - Utilitaires d'extraction
    
    /// Extrait le contenu d'une balise HTML
    private func extraireBalise(html: String, tag: String) -> String? {
        let pattern = "<\(tag)[^>]*>(.*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, range: range) else {
            return nil
        }
        
        if let contentRange = Range(match.range(at: 1), in: html) {
            return String(html[contentRange])
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&amp;", with: "&")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    /// Extrait un pattern depuis l'URL
    private func extraireDepuisURL(url: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(url.startIndex..., in: url)
        guard let match = regex.firstMatch(in: url, range: range) else {
            return nil
        }
        
        if let contentRange = Range(match.range(at: 1), in: url) {
            return String(url[contentRange])
        }
        
        return nil
    }
    
    /// Extrait les variantes (dimensions) depuis le HTML
    private func extraireVariantes(html: String) -> [VarianteLeurre] {
        var variantes: [VarianteLeurre] = []
        
        // Pattern pour détecter : "9 cm", "14 cm", "22 cm"
        let patternLongueur = "([0-9]{1,3})\\s*cm"
        
        // Pattern pour détecter : "15g", "22g", "35 g"
        let patternPoids = "([0-9]{1,4})\\s*g(?!r)"
        
        // Pattern pour profondeur : "3-6m", "0.5-1.5m"
        let patternProfondeur = "([0-9.]+)\\s*-\\s*([0-9.]+)\\s*m"
        
        // Chercher toutes les longueurs
        if let regexLongueur = try? NSRegularExpression(pattern: patternLongueur, options: .caseInsensitive) {
            let range = NSRange(html.startIndex..., in: html)
            let matches = regexLongueur.matches(in: html, range: range)
            
            for match in matches {
                if let longueurRange = Range(match.range(at: 1), in: html),
                   let longueur = Double(html[longueurRange]) {
                    
                    // Créer une variante pour cette longueur
                    var variante = VarianteLeurre(
                        longueur: longueur,
                        description: "\(Int(longueur)) cm"
                    )
                    
                    // Essayer de trouver le poids associé dans les 100 caractères suivants
                    let startIndex = match.range.location
                    let searchRange = NSRange(location: startIndex, length: min(100, html.utf16.count - startIndex))
                    
                    if let regexPoids = try? NSRegularExpression(pattern: patternPoids, options: .caseInsensitive),
                       let matchPoids = regexPoids.firstMatch(in: html, range: searchRange),
                       let poidsRange = Range(matchPoids.range(at: 1), in: html),
                       let poids = Double(html[poidsRange]) {
                        variante.poids = poids
                        variante.description += " - \(Int(poids))g"
                    }
                    
                    // Vérifier qu'on n'a pas déjà cette variante
                    if !variantes.contains(where: { $0.longueur == variante.longueur }) {
                        variantes.append(variante)
                    }
                }
            }
        }
        
        // Si aucune variante trouvée, chercher juste les poids
        if variantes.isEmpty {
            if let regexPoids = try? NSRegularExpression(pattern: patternPoids, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..., in: html)
                let matches = regexPoids.matches(in: html, range: range)
                
                for match in matches {
                    if let poidsRange = Range(match.range(at: 1), in: html),
                       let poids = Double(html[poidsRange]) {
                        
                        let variante = VarianteLeurre(
                            poids: poids,
                            description: "\(Int(poids))g"
                        )
                        
                        if !variantes.contains(where: { $0.poids == variante.poids }) {
                            variantes.append(variante)
                        }
                    }
                }
            }
        }
        
        print("✅ \(variantes.count) variante(s) trouvée(s)")
        return variantes
    }
    
    /// Extrait les variantes spécifiques pour Nomad Tackle (depuis les tableaux HTML)
    private func extraireVariantesNomad(html: String) -> [VarianteLeurre] {
        var variantes: [VarianteLeurre] = []
        
        // Nomad utilise souvent des tableaux avec des lignes comme :
        // <tr><td>95mm</td><td>30g</td><td>3-6m</td></tr>
        
        // Pattern pour extraire les lignes de tableau
        let patternTableRow = "<tr[^>]*>(.*?)</tr>"
        
        guard let regexRow = try? NSRegularExpression(pattern: patternTableRow, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return []
        }
        
        let range = NSRange(html.startIndex..., in: html)
        let matches = regexRow.matches(in: html, range: range)
        
        for match in matches {
            if let rowRange = Range(match.range(at: 1), in: html) {
                let rowContent = String(html[rowRange])
                
                // Extraire les cellules <td>
                let patternCell = "<td[^>]*>(.*?)</td>"
                guard let regexCell = try? NSRegularExpression(pattern: patternCell, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
                    continue
                }
                
                let cellRange = NSRange(rowContent.startIndex..., in: rowContent)
                let cellMatches = regexCell.matches(in: rowContent, range: cellRange)
                
                var longueur: Double?
                var poids: Double?
                var profondeurMin: Double?
                var profondeurMax: Double?
                
                // Analyser chaque cellule
                for cellMatch in cellMatches {
                    if let cellContentRange = Range(cellMatch.range(at: 1), in: rowContent) {
                        let cellContent = String(rowContent[cellContentRange])
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .lowercased()
                        
                        // Longueur : "95mm", "9.5cm", "9 cm"
                        if cellContent.contains("mm") {
                            let valeur = cellContent.replacingOccurrences(of: "mm", with: "").trimmingCharacters(in: .whitespaces)
                            if let mm = Double(valeur) {
                                longueur = mm / 10.0 // Convertir en cm
                            }
                        } else if cellContent.contains("cm") {
                            let valeur = cellContent.replacingOccurrences(of: "cm", with: "").trimmingCharacters(in: .whitespaces)
                            longueur = Double(valeur)
                        }
                        
                        // Poids : "30g", "30 g"
                        if cellContent.contains("g") && !cellContent.contains("gr") {
                            let valeur = cellContent.replacingOccurrences(of: "g", with: "").trimmingCharacters(in: .whitespaces)
                            poids = Double(valeur)
                        }
                        
                        // Profondeur : "3-6m", "0.5-1.5m"
                        if cellContent.contains("m") && cellContent.contains("-") {
                            let components = cellContent.replacingOccurrences(of: "m", with: "").components(separatedBy: "-")
                            if components.count == 2 {
                                profondeurMin = Double(components[0].trimmingCharacters(in: .whitespaces))
                                profondeurMax = Double(components[1].trimmingCharacters(in: .whitespaces))
                            }
                        }
                    }
                }
                
                // Créer la variante si au moins longueur ou poids trouvé
                if longueur != nil || poids != nil {
                    var description = ""
                    
                    if let l = longueur {
                        description += "\(Int(l)) cm"
                    }
                    
                    if let p = poids {
                        if !description.isEmpty { description += " - " }
                        description += "\(Int(p))g"
                    }
                    
                    if let pmin = profondeurMin, let pmax = profondeurMax {
                        if !description.isEmpty { description += " - " }
                        description += "\(pmin)-\(pmax)m"
                    }
                    
                    let variante = VarianteLeurre(
                        longueur: longueur,
                        poids: poids,
                        profondeurMin: profondeurMin,
                        profondeurMax: profondeurMax,
                        description: description
                    )
                    
                    variantes.append(variante)
                }
            }
        }
        
        return variantes
    }
    
    /// Extrait les variantes depuis une page de collection Nomad
    private func extraireVariantesNomadCollection(html: String) -> [VarianteLeurre] {
        var variantes: [VarianteLeurre] = []
        
        // Sur les pages de collection, Nomad liste souvent les produits avec leurs tailles
        // Chercher des patterns dans les divs de produits
        // Ex: "DTX 140" ou "DTX MINNOW 140MM" ou "95mm - 30g"
        
        let patterns = [
            "([0-9]{2,3})mm",  // 95mm, 140mm
            "([0-9]{2,3})\\s*MM",  // 95 MM
            "DTX\\s+([0-9]{2,3})",  // DTX 140
            "([0-9]{1,2}\\.?[0-9]?)\\s*cm"  // 9.5 cm, 14 cm
        ]
        
        var taillesTrouvees: Set<Double> = []
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..., in: html)
                let matches = regex.matches(in: html, range: range)
                
                for match in matches {
                    if let tailleRange = Range(match.range(at: 1), in: html),
                       var taille = Double(html[tailleRange]) {
                        
                        // Si c'est en mm, convertir en cm
                        if pattern.contains("mm") || pattern.contains("MM") {
                            taille = taille / 10.0
                        }
                        
                        // Ajouter si pas déjà présent
                        if !taillesTrouvees.contains(taille) {
                            taillesTrouvees.insert(taille)
                            
                            let variante = VarianteLeurre(
                                longueur: taille,
                                description: "\(Int(taille)) cm"
                            )
                            variantes.append(variante)
                        }
                    }
                }
            }
        }
        
        return variantes.sorted { ($0.longueur ?? 0) < ($1.longueur ?? 0) }
    }
    
    /// Extrait l'URL de l'image spécifiquement pour Walmart
    private func extraireImageWalmart(html: String) -> String? {
        // Walmart utilise des URLs comme i5.walmartimages.com
        let pattern = "(https?://i[0-9]+\\.walmartimages\\.com/[^\"'\\s]+)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..., in: html)
        if let match = regex.firstMatch(in: html, range: range),
           let urlRange = Range(match.range(at: 1), in: html) {
            var url = String(html[urlRange])
            
            // Nettoyer l'URL (enlever les paramètres de redimensionnement si nécessaire)
            url = url.replacingOccurrences(of: "&amp;", with: "&")
            
            print("📸 Photo Walmart trouvée : \(url)")
            return url
        }
        
        // Fallback : utiliser l'extraction standard
        return extrairePremiereImage(html: html)
    }
    
    /// Extrait l'URL de la première image produit
    private func extrairePremiereImage(html: String) -> String? {
        // Chercher des balises <img> avec des attributs classiques
        let patterns = [
            "<img[^>]*src=[\"']([^\"']+product[^\"']+)[\"']",
            "<img[^>]*src=[\"']([^\"']+lure[^\"']+)[\"']",
            "<img[^>]*src=[\"']([^\"']+fishing[^\"']+)[\"']",
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
                        // Extraire le domaine de l'URL de la page
                        if let baseURL = extraireDomaineBase(html: html) {
                            url = baseURL + url
                        }
                    }
                    
                    // Vérifier que c'est une URL valide
                    if URL(string: url) != nil {
                        print("📸 Photo trouvée : \(url)")
                        return url
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Extrait le domaine de base depuis le HTML (balise <base> ou meta)
    private func extraireDomaineBase(html: String) -> String? {
        // Chercher une balise <base href="...">
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
        
        // Correspondances mot-clé → Type
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
    
    // MARK: - Utilitaires PrestaShop
    
    /// Extrait les métadonnées Open Graph (og:title, og:description, etc.)
    private func extraireMetaProperty(html: String, property: String) -> String? {
        let pattern = "<meta[^>]*property=[\"']\(property)[\"'][^>]*content=[\"']([^\"']+)[\"']"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..., in: html)
        if let match = regex.firstMatch(in: html, range: range),
           let contentRange = Range(match.range(at: 1), in: html) {
            return String(html[contentRange])
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&amp;", with: "&")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    /// Extrait les informations depuis les classes typiques de PrestaShop
    private func extraireDepuisClassesPresta(html: String, infos: LeurreInfosExtraites) -> LeurreInfosExtraites {
        var infosModifiees = infos
        
        // Chercher la marque dans class="product-manufacturer"
        if infosModifiees.marque == nil {
            if let marque = extraireContenuClass(html: html, className: "product-manufacturer") {
                infosModifiees.marque = marque
            }
        }
        
        // Chercher le nom dans class="product-title" ou "h1"
        if infosModifiees.nom == nil {
            if let nom = extraireContenuClass(html: html, className: "product-title") {
                infosModifiees.nom = nom
            } else if let h1 = extraireBalise(html: html, tag: "h1") {
                infosModifiees.nom = h1
            }
        }
        
        return infosModifiees
    }
    
    /// Extrait le contenu d'un élément avec une classe spécifique
    private func extraireContenuClass(html: String, className: String) -> String? {
        // Pattern pour chercher <div class="className">contenu</div>
        let patterns = [
            "<div[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*>(.*?)</div>",
            "<span[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*>(.*?)</span>",
            "<h1[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*>(.*?)</h1>",
            "<a[^>]*class=[\"'][^\"']*\(className)[^\"']*[\"'][^>]*>(.*?)</a>"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) {
                let range = NSRange(html.startIndex..., in: html)
                if let match = regex.firstMatch(in: html, range: range),
                   let contentRange = Range(match.range(at: 1), in: html) {
                    let contenu = String(html[contentRange])
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) // Enlever les balises HTML internes
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
        // D'abord, chercher les images avec les classes spécifiques
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
        
        // Fallback : extraction standard
        return extrairePremiereImage(html: html)
    }
    
    /// Nettoie une URL d'image (gère les URLs relatives, paramètres, etc.)
    private func nettoyerURLImage(_ url: String, html: String) -> String {
        var urlNettoyee = url
        
        // Nettoyer les entités HTML
        urlNettoyee = urlNettoyee.replacingOccurrences(of: "&amp;", with: "&")
        
        // Compléter si URL relative
        if urlNettoyee.hasPrefix("//") {
            urlNettoyee = "https:" + urlNettoyee
        } else if urlNettoyee.hasPrefix("/") {
            // Extraire le domaine de l'URL de la page
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
