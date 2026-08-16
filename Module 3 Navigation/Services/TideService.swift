// TideService.swift
// Go Les Picots V.4
//
// Service de récupération des marées depuis cabaigne.net.
// Source : données SHOM republication — fiabilité correcte pour usage pêche.
// Cache UserDefaults par commune, rafraîchissement automatique toutes les 6h.
//
// Parser HTML brut validé sur réponse réelle (200, 65207 bytes, 16/08/2026).
// Structure HTML : <h3>date</h3> + <tr><td>marée</td><td>heure</td><td>hauteur</td></tr>

import Foundation
import Combine

// MARK: - Modèles publics

struct CabaigneEvent: Identifiable, Codable {
    let id: UUID
    let time: Date
    let isHigh: Bool
    let height: Double

    init(time: Date, isHigh: Bool, height: Double) {
        self.id     = UUID()
        self.time   = time
        self.isHigh = isHigh
        self.height = height
    }
}

struct CabaigneDay: Identifiable, Codable {
    let id: UUID
    let date: Date
    let events: [CabaigneEvent]
    let sunrise: Date?
    let sunset: Date?

    init(date: Date, events: [CabaigneEvent], sunrise: Date?, sunset: Date?) {
        self.id      = UUID()
        self.date    = date
        self.events  = events.sorted { $0.time < $1.time }
        self.sunrise = sunrise
        self.sunset  = sunset
    }
}

struct CabaigneCommune: Identifiable, Hashable {
    let id: String
    let name: String

    var url: URL {
        URL(string: "https://www.cabaigne.net/oceanie/nouvelle-caledonie/\(id)/horaire-marees.html")!
    }
}

// MARK: - Catalogue communes

extension CabaigneCommune {
    static let all: [CabaigneCommune] = [
        CabaigneCommune(id: "noumea",        name: "Nouméa"),
        CabaigneCommune(id: "dumbea",        name: "Dumbéa"),
        CabaigneCommune(id: "mont-dore",     name: "Mont-Dore"),
        CabaigneCommune(id: "paita",         name: "Paita"),
        CabaigneCommune(id: "yate",          name: "Yaté"),
        CabaigneCommune(id: "baie-de-prony", name: "Baie de Prony"),
        CabaigneCommune(id: "ile-ouen",      name: "Île Ouen"),
        CabaigneCommune(id: "thio",          name: "Thio"),
        CabaigneCommune(id: "moindou",       name: "Moindou"),
        CabaigneCommune(id: "poe",           name: "Poé"),
        CabaigneCommune(id: "nepoui",        name: "Népoui"),
        CabaigneCommune(id: "voh",           name: "Voh"),
        CabaigneCommune(id: "koumac",        name: "Koumac"),
        CabaigneCommune(id: "poingam",       name: "Poingam"),
        CabaigneCommune(id: "pouebo",        name: "Pouébo"),
        CabaigneCommune(id: "poindimie",     name: "Poindimié"),
        CabaigneCommune(id: "ponerihouen",   name: "Ponérihouen"),
        CabaigneCommune(id: "wala",          name: "Wala"),
        CabaigneCommune(id: "tiga",          name: "Tiga"),
        CabaigneCommune(id: "ile-lifou",     name: "Île Lifou"),
        CabaigneCommune(id: "mare",          name: "Maré"),
        CabaigneCommune(id: "ouvea",         name: "Ouvéa"),
        CabaigneCommune(id: "ile-des-pins",  name: "Île des Pins"),
    ]
    static let defaultCommune = CabaigneCommune.all.first!
}

// MARK: - Cache interne

private struct CabaigneCache: Codable {
    let commune: String
    let fetchedAt: Date
    let days: [CabaigneDay]

    var isStale: Bool {
        Date().timeIntervalSince(fetchedAt) > 6 * 3600
    }
}

// MARK: - Service principal

@MainActor
final class TideService: ObservableObject {

    @Published var tideDays: [CabaigneDay] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedCommune: CabaigneCommune = .defaultCommune {
        didSet {
            guard oldValue.id != selectedCommune.id else { return }
            Task { await load(for: selectedCommune, forceRefresh: false) }
        }
    }

    private let timeZone = TimeZone(identifier: "Pacific/Noumea")!
    private static let cacheKeyPrefix = "cabaigneCache_"

    init() {
        Task { await load(for: selectedCommune, forceRefresh: false) }
    }

    // MARK: API publique

    func load(for commune: CabaigneCommune, forceRefresh: Bool) async {
        if !forceRefresh, let cached = loadCache(for: commune), !cached.isStale {
            tideDays = cached.days
            errorMessage = nil
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let days = try await fetchAndParse(commune: commune)
            tideDays = days
            saveCache(CabaigneCache(commune: commune.id, fetchedAt: Date(), days: days))
            errorMessage = nil
        } catch {
            if let cached = loadCache(for: commune) {
                tideDays = cached.days
                errorMessage = "Données en cache (réseau indisponible)"
            } else {
                tideDays = []
                errorMessage = "Impossible de charger les marées : \(error.localizedDescription)"
            }
        }
        isLoading = false
    }

    func tideDay(for date: Date) -> CabaigneDay? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return tideDays.first { cal.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Réseau

    private func fetchAndParse(commune: CabaigneCommune) async throws -> [CabaigneDay] {
        var request = URLRequest(url: commune.url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CabaigneServiceError.httpError
        }
        guard let html = String(data: data, encoding: .utf8) ??
                         String(data: data, encoding: .isoLatin1) else {
            throw CabaigneServiceError.decodingError
        }

        return try parseHTML(html)
    }

    // MARK: - Parser HTML brut
    //
    // Structure HTML réelle cabaigne.net (validée 16/08/2026, 65207 bytes) :
    //
    // <h3>samedi 15 août 2026</h3>
    // ...
    // <tr>
    //   <td>marée basse</td><td>15:37</td><td>0.18m</td>
    // </tr>
    // <tr>
    //   <td>marée haute</td><td>21:52</td><td>1.47m</td>
    // </tr>
    // ...
    // <img src="...sunrise.png"> Lever de soleil : 06:19
    // <img src="...sunset.png">  Coucher de soleil : 17:39

    private func parseHTML(_ html: String) throws -> [CabaigneDay] {
        var days: [CabaigneDay] = []
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone

        let dateFmt = DateFormatter()
        dateFmt.locale     = Locale(identifier: "fr_FR")
        dateFmt.dateFormat = "EEEE d MMMM yyyy"
        dateFmt.timeZone   = timeZone

        let timeFmt = DateFormatter()
        timeFmt.locale     = Locale(identifier: "fr_FR")
        timeFmt.dateFormat = "HH:mm"
        timeFmt.timeZone   = timeZone

        // Construit une Date complète depuis une date de base + "HH:mm"
        func buildDate(base: Date, timeStr: String) -> Date? {
            guard let parsed = timeFmt.date(from: timeStr) else { return nil }
            var comps = cal.dateComponents([.year, .month, .day], from: base)
            let tc    = cal.dateComponents([.hour, .minute], from: parsed)
            comps.hour = tc.hour; comps.minute = tc.minute; comps.second = 0
            return cal.date(from: comps)
        }

        // Extrait la première occurrence HH:mm dans une chaîne
        func extractHHmm(from str: String) -> String? {
            guard let regex = try? NSRegularExpression(pattern: #"(\d{2}:\d{2})"#),
                  let match = regex.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)),
                  let range = Range(match.range(at: 1), in: str) else { return nil }
            return String(str[range])
        }

        // Supprime les balises HTML
        func stripTags(_ s: String) -> String {
            s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
             .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // --- Découpe le HTML en blocs par jour ---
        // Chaque bloc commence à un <h3>date</h3> et se termine au <h3> suivant
        let dayPattern = #"<h3>([^<]+)</h3>(.*?)(?=<h3>|$)"#
        guard let dayRegex = try? NSRegularExpression(
            pattern: dayPattern,
            options: [.dotMatchesLineSeparators, .caseInsensitive]
        ) else { throw CabaigneServiceError.parseError }

        let fullRange = NSRange(html.startIndex..., in: html)
        let dayMatches = dayRegex.matches(in: html, range: fullRange)

        for match in dayMatches {
            guard let dateRange    = Range(match.range(at: 1), in: html),
                  let contentRange = Range(match.range(at: 2), in: html) else { continue }

            let rawDate = String(html[dateRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Ignore les <h3> non-dates (ex : "Marées suivantes :", "Au sommaire :")
            guard let baseDate = dateFmt.date(from: rawDate) else { continue }

            let block = String(html[contentRange])
            var events:  [CabaigneEvent] = []
            var sunrise: Date? = nil
            var sunset:  Date? = nil

            // --- Lignes de marée : <tr><td>marée basse/haute</td><td>HH:mm</td><td>Xm</td></tr> ---
            let rowPattern = #"<td[^>]*>\s*(?:<[^>]+>)?\s*(mar[eéè]e\s+(?:basse|haute))\s*(?:</[^>]+>)?\s*</td>\s*<td[^>]*>\s*(?:<[^>]+>)?\s*(\d{2}:\d{2})\s*(?:</[^>]+>)?\s*</td>\s*<td[^>]*>\s*([\d.]+)\s*m?"#
            if let rowRegex = try? NSRegularExpression(
                pattern: rowPattern,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            ) {
                let bRange = NSRange(block.startIndex..., in: block)
                for row in rowRegex.matches(in: block, range: bRange) {
                    guard let t1 = Range(row.range(at: 1), in: block),
                          let t2 = Range(row.range(at: 2), in: block),
                          let t3 = Range(row.range(at: 3), in: block) else { continue }

                    let typeStr  = String(block[t1]).lowercased()
                    let heureStr = String(block[t2])
                    let hautStr  = String(block[t3])

                    guard let height    = Double(hautStr),
                          let eventDate = buildDate(base: baseDate, timeStr: heureStr) else { continue }

                    events.append(CabaigneEvent(
                        time: eventDate,
                        isHigh: typeStr.contains("haute"),
                        height: height
                    ))
                }
            }

            // --- Lever / coucher de soleil ---
            // <img src="...sunrise.png"> ... 06:19 ...
            // <img src="...sunset.png">  ... 17:39 ...
            let sunPattern = #"(sunrise|sunset)\.png[^>]*>(.*?)(?=<li|</ul|<h[23]|$)"#
            if let sunRegex = try? NSRegularExpression(
                pattern: sunPattern,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            ) {
                let bRange = NSRange(block.startIndex..., in: block)
                for sun in sunRegex.matches(in: block, range: bRange) {
                    guard let typeRange = Range(sun.range(at: 1), in: block),
                          let txtRange  = Range(sun.range(at: 2), in: block) else { continue }

                    let sunType = String(block[typeRange]).lowercased()
                    let raw     = stripTags(String(block[txtRange]))

                    guard let timeStr = extractHHmm(from: raw),
                          let date    = buildDate(base: baseDate, timeStr: timeStr) else { continue }

                    if sunType == "sunrise" { sunrise = date }
                    else                    { sunset  = date }
                }
            }

            guard !events.isEmpty else { continue }
            days.append(CabaigneDay(
                date: baseDate,
                events: events,
                sunrise: sunrise,
                sunset: sunset
            ))
        }

        guard !days.isEmpty else { throw CabaigneServiceError.parseError }
        return days
    }

    // MARK: - Cache UserDefaults

    private func cacheKey(for commune: CabaigneCommune) -> String {
        Self.cacheKeyPrefix + commune.id
    }

    private func saveCache(_ cache: CabaigneCache) {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey(for: selectedCommune))
    }

    private func loadCache(for commune: CabaigneCommune) -> CabaigneCache? {
        guard let data  = UserDefaults.standard.data(forKey: cacheKey(for: commune)),
              let cache = try? JSONDecoder().decode(CabaigneCache.self, from: data),
              cache.commune == commune.id else { return nil }
        return cache
    }
}

// MARK: - Erreurs

enum CabaigneServiceError: LocalizedError {
    case httpError, decodingError, parseError

    var errorDescription: String? {
        switch self {
        case .httpError:     return "Erreur HTTP lors de l'accès à cabaigne.net"
        case .decodingError: return "Impossible de décoder la réponse"
        case .parseError:    return "Aucune donnée de marée trouvée dans la page"
        }
    }
}
