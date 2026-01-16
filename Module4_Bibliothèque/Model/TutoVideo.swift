//
//  TutoVideo.swift
//  Go les Picots V.4 - Module 4
//
//  Modèle pour les vidéos tutoriels YouTube
//
//  Created: 2026-01-16
//

import Foundation

/// Vidéo tutoriel YouTube
struct TutoVideo: Identifiable, Codable {
    let id: String              // ID YouTube (ex: "sL9DND_UsOs")
    let titre: String           // Titre de la vidéo
    let categorie: CategorieTuto
    let duree: String           // Durée au format "4:36"
    let source: String = "Pacific Community" // Chaîne YouTube
    
    /// URL complète YouTube
    var urlYouTube: String {
        "https://www.youtube.com/watch?v=\(id)"
    }
    
    /// URL de la vignette (thumbnail) YouTube
    var urlVignette: String {
        "https://img.youtube.com/vi/\(id)/hqdefault.jpg"
    }
}

/// Catégories des tutoriels (mêmes que fiches pédagogiques)
enum CategorieTuto: String, Codable, CaseIterable {
    case montages = "Montages & Techniques de Base"
    case animations = "Animations & Jigging"
    case strategies = "Stratégies & Méthodes"
    case equipement = "Équipement & Bricolage"
    
    var icon: String {
        switch self {
        case .montages: return "link.circle.fill"
        case .animations: return "water.waves"
        case .strategies: return "map.fill"
        case .equipement: return "wrench.and.screwdriver.fill"
        }
    }
    
    var couleur: String {
        switch self {
        case .montages: return "0277BD"      // Bleu
        case .animations: return "00ACC1"    // Cyan
        case .strategies: return "FFBC42"    // Orange
        case .equipement: return "8E24AA"    // Violet
        }
    }
}

// MARK: - Database

/// Base de données des vidéos tutoriels
struct TutoVideoDatabase {
    
    static let videos: [TutoVideo] = [
        
        // ═════════════════════════════════════════════════════════
        // MONTAGES & TECHNIQUES DE BASE (7 vidéos)
        // ═════════════════════════════════════════════════════════
        
        TutoVideo(
            id: "sL9DND_UsOs",
            titre: "Fish and tips S1 Ep1 - Fishing: know the basics",
            categorie: .montages,
            duree: "4:36"
        ),
        
        TutoVideo(
            id: "_mvSL2d-ye8",
            titre: "Fish and tips S1 Ep2 - Trolling",
            categorie: .montages,
            duree: "3:37"
        ),
        
        TutoVideo(
            id: "A4-z-TtYYNI",
            titre: "Fish and tips S1 Ep3 - Trolling with multiple lures",
            categorie: .montages,
            duree: "2:15"
        ),
        
        TutoVideo(
            id: "v9u_dlFSo0g",
            titre: "Fish and tips S1 Ep4 - Trolling with natural bait",
            categorie: .montages,
            duree: "3:24"
        ),
        
        TutoVideo(
            id: "a7M1z89kgAY",
            titre: "Fish and tips S1 Ep5 - Trolling using weights or diving devices",
            categorie: .montages,
            duree: "4:42"
        ),
        
        TutoVideo(
            id: "l4u40hUKke4",
            titre: "Pêche à la traîne à l'appât naturel - Fish and Tips S1 Ep4 (Français)",
            categorie: .montages,
            duree: "3:24"
        ),
        
        TutoVideo(
            id: "m1TXSf2CafY",
            titre: "Setting around Fish aggregating devices (FADs) Bonus #3",
            categorie: .montages,
            duree: "2:21"
        ),
        
        // ═════════════════════════════════════════════════════════
        // ANIMATIONS & JIGGING (5 vidéos)
        // ═════════════════════════════════════════════════════════
        
        TutoVideo(
            id: "cAmrQEs36pg",
            titre: "Spreader-rod jigging - Fish & Tips Season 2 Ep4",
            categorie: .animations,
            duree: "6:51"
        ),
        
        TutoVideo(
            id: "lYvAImt1uT8",
            titre: "Baitfish jigging - Fish & Tips Season 3, Episode 1",
            categorie: .animations,
            duree: "9:21"
        ),
        
        TutoVideo(
            id: "6PYCVKPg69o",
            titre: "Pencil squid jigging - Fish & Tips Season 3, Episode 2",
            categorie: .animations,
            duree: "6:43"
        ),
        
        TutoVideo(
            id: "Iw9ijrtUOKo",
            titre: "Ika-shibi fishing - Fish & Tips Season 3, Episode 3",
            categorie: .animations,
            duree: "8:45"
        ),
        
        TutoVideo(
            id: "NyZNSzcEweI",
            titre: "Deep-water squid fishing - Fish & Tips Season 3, Episode 4",
            categorie: .animations,
            duree: "10:08"
        ),
        
        // ═════════════════════════════════════════════════════════
        // STRATÉGIES & MÉTHODES (7 vidéos)
        // ═════════════════════════════════════════════════════════
        
        TutoVideo(
            id: "yV0UgQSE6lI",
            titre: "Drop-stone fishing - Fish & Tips Season 2 Ep1",
            categorie: .strategies,
            duree: "6:35"
        ),
        
        TutoVideo(
            id: "Edbp0aPaCV8",
            titre: "Palu-ahi fishing - Fish&Tips Season 2 Ep2",
            categorie: .strategies,
            duree: "6:12"
        ),
        
        TutoVideo(
            id: "-hmLcpixW30",
            titre: "Cone-bag fishing - Fish&Tips Season 2 Ep3",
            categorie: .strategies,
            duree: "5:00"
        ),
        
        TutoVideo(
            id: "6YnsTuy2dxY",
            titre: "Drift line with a self-righting buoy - Fish& Tip bonus#1 Season 2",
            categorie: .strategies,
            duree: "5:09"
        ),
        
        TutoVideo(
            id: "eDgTgSxQ_uE",
            titre: "Chum canister fishing - Fish&Tips bonus#3 Season 2",
            categorie: .strategies,
            duree: "3:57"
        ),
        
        TutoVideo(
            id: "HA-AwEVQ4VU",
            titre: "La pêche au caillou - Fish & Tips S2 Ep1 (Français)",
            categorie: .strategies,
            duree: "6:35"
        ),
        
        TutoVideo(
            id: "-uNlwzxhKrY",
            titre: "Flying fish scoop-netting - Fish & Tips Season 3, Episode 5",
            categorie: .strategies,
            duree: "8:01"
        ),
        
        // ═════════════════════════════════════════════════════════
        // ÉQUIPEMENT & BRICOLAGE (3 vidéos)
        // ═════════════════════════════════════════════════════════
        
        TutoVideo(
            id: "ymkyzkL_7XI",
            titre: "How to create your own foam float - Fish & Tips bonus#2 Season 2",
            categorie: .equipement,
            duree: "2:56"
        ),
        
        TutoVideo(
            id: "2MWR3L2U0bw",
            titre: "Fishing lights Bonus #1 - Fish & Tips Season 3",
            categorie: .equipement,
            duree: "4:31"
        ),
        
        TutoVideo(
            id: "Mq3Y_jaubBs",
            titre: "Sea anchor Bonus #2 - Fish & Tips Season 3",
            categorie: .equipement,
            duree: "4:52"
        ),
    ]
    
    /// Récupérer les vidéos par catégorie
    static func videos(pour categorie: CategorieTuto) -> [TutoVideo] {
        videos.filter { $0.categorie == categorie }
    }
    
    /// Récupérer toutes les catégories avec vidéos
    static var categoriesAvecVideos: [CategorieTuto] {
        CategorieTuto.allCases.filter { categorie in
            !videos(pour: categorie).isEmpty
        }
    }
}
