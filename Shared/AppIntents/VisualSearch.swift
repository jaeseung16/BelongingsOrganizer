//
//  VisualSearch.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/5/26.
//

import Foundation
import AppIntents
import CoreImage
import CoreML
import CoreVideo
import Vision
import os
#if canImport(VisualIntelligence)
import VisualIntelligence
#endif

// The simulator SDK has no VisualIntelligence, so only the two intent types are guarded;
// the matching below builds everywhere
#if canImport(VisualIntelligence)
// Visual Intelligence: point the camera at something, or take a screenshot, and the
// belongings that look like it appear among the results
struct ItemVisualSearchQuery: IntentValueQuery {
    @Dependency private var viewModel: BelongingsViewModel

    func values(for input: SemanticContentDescriptor) async throws -> [ItemEntity] {
        let signpostState = PerformanceSignposts.signposter.beginInterval("visualSearch")
        defer { PerformanceSignposts.signposter.endInterval("visualSearch", signpostState) }

        let snapshots = await VisualSearch.items(labels: input.labels, pixelBuffer: input.pixelBuffer, in: viewModel.persistenceHelper)
        return await ItemEntity.withThumbnails(snapshots)
    }
}

// "More results": opens the item list searching for what was recognized
@AppIntent(schema: .visualIntelligence.semanticContentSearch)
struct ShowVisualSearchResultsIntent: AppIntent {
    static let supportedModes: IntentModes = .foreground

    var semanticContent: SemanticContentDescriptor

    @Dependency private var viewModel: BelongingsViewModel

    @MainActor
    func perform() async throws -> some IntentResult {
        await VisualSearch.showResults(labels: semanticContent.labels, pixelBuffer: semanticContent.pixelBuffer, in: viewModel)
        return .result()
    }
}
#endif

#if DEBUG
// For UI tests, which run on the simulator: the same matching and search, from plain labels
struct VisualSearchItemNamesIntent: AppIntent {
    static let title: LocalizedStringResource = "Visual Search Item Names"
    static let isDiscoverable = false

    @Parameter(title: "Labels")
    var labels: [String]

    @Dependency private var viewModel: BelongingsViewModel

    @MainActor
    func perform() async throws -> some ReturnsValue<[String]> {
        let snapshots = await VisualSearch.items(labels: labels, pixelBuffer: nil, in: viewModel.persistenceHelper)
        return .result(value: snapshots.map(\.entity.name))
    }
}

struct ShowVisualSearchResultsForLabelsIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Visual Search Results for Labels"
    static let isDiscoverable = false
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Labels")
    var labels: [String]

    @Dependency private var viewModel: BelongingsViewModel

    @MainActor
    func perform() async throws -> some IntentResult {
        await VisualSearch.showResults(labels: labels, pixelBuffer: nil, in: viewModel)
        return .result()
    }
}
#endif

enum VisualSearch {
    // The system shows a short row of results; "More results" opens the app's search
    static let resultLimit = 10
    // Fetched before ranking, so an item matching several labels isn't cut off by recency
    private static let candidateLimit = 100
    // Keeps the fetch predicate small
    private nonisolated static let maximumTermCount = 8

    // Matches for the system's labels first. They can be too general or missing, so the
    // image's own classification fills in the rest.
    static func items(labels: [String], pixelBuffer: CVReadOnlyPixelBuffer?,
                      in persistenceHelper: PersistenceHelper) async -> [(entity: ItemEntity, photo: Data?)] {
        // Like Spotlight, nothing shows while the app lock is on
        guard !IntentAccessPolicy.isAppLocked else {
            return []
        }
        let labelTerms = terms(from: labels)
        var items = bestMatches(for: labelTerms, in: persistenceHelper)

        if items.count < resultLimit, let pixelBuffer {
            let classifiedTerms = terms(from: await ImageLabeler.labels(for: pixelBuffer))
                .filter { term in !labelTerms.contains { $0.caseInsensitiveCompare(term) == .orderedSame } }
            let more = bestMatches(for: classifiedTerms, in: persistenceHelper)
                .filter { !items.contains($0) }
            items += more.prefix(resultLimit - items.count)
        }

        return ItemEntity.snapshots(of: items)
    }

    // "More results". The item list searches names only, so it searches for the first term
    // that some item's name contains.
    static func showResults(labels: [String], pixelBuffer: CVReadOnlyPixelBuffer?, in viewModel: BelongingsViewModel) async {
        var terms = terms(from: labels)
        if terms.isEmpty, let pixelBuffer {
            terms = self.terms(from: await ImageLabeler.labels(for: pixelBuffer))
        }
        let term = terms.first { term in
            let items: [Item] = viewModel.persistenceHelper.fetch(.item, nameContaining: term, sortDescriptors: [], limit: 1)
            return !items.isEmpty
        }
        viewModel.showItems(matching: term ?? terms.first ?? "")
    }

    // "laptop, laptop computer" (MobileNet's style) becomes two terms, and a plural drops its "s"
    // so that "Headphones" also finds "headphone"
    nonisolated static func terms(from labels: [String]) -> [String] {
        var terms = [String]()
        for label in labels {
            for part in label.split(separator: ",") {
                var term = part.trimmingCharacters(in: .whitespacesAndNewlines)
                if term.count > 3, term.hasSuffix("s"), !term.hasSuffix("ss") {
                    term.removeLast()
                }
                if term.count >= 2, !terms.contains(where: { $0.caseInsensitiveCompare(term) == .orderedSame }) {
                    terms.append(term)
                }
            }
        }
        return Array(terms.prefix(maximumTermCount))
    }

    // Ranked by how many terms match (a name match counts double), then owned before disposed,
    // then most recently updated
    private static func bestMatches(for terms: [String], in persistenceHelper: PersistenceHelper) -> [Item] {
        let candidates = persistenceHelper.fetchItems(matchingAny: terms, limit: candidateLimit)
        let scored = candidates.map { item in
            let name = item.name ?? ""
            let otherNames = item.kinds.compactMap(\.name) + [item.firstBrand?.name].compactMap { $0 }
            let score = terms.reduce(0) { score, term in
                if contains(name, term) {
                    return score + 2
                }
                return otherNames.contains { contains($0, term) } ? score + 1 : score
            }
            return (item: item, score: score)
        }
        return scored
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                if (lhs.item.disposed == nil) != (rhs.item.disposed == nil) {
                    return lhs.item.disposed == nil
                }
                return (lhs.item.lastupd ?? .distantPast) > (rhs.item.lastupd ?? .distantPast)
            }
            .prefix(resultLimit)
            .map(\.item)
    }

    // The same comparison as the fetch predicate's CONTAINS[cd]
    private static func contains(_ string: String, _ term: String) -> Bool {
        string.range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}

// The bundled MobileNet classifier, run on the image Visual Intelligence passes in
nonisolated enum ImageLabeler {
    private static let logger = Logger()
    private static let minimumConfidence: Float = 0.1
    private static let maximumCount = 3

    // Loaded once, on first use. Through the compiled model's URL rather than the generated
    // MobileNet class, which is main-actor isolated in this target.
    private static let model: CoreMLModelContainer? = {
        guard let url = Bundle.main.url(forResource: "MobileNet", withExtension: "mlmodelc") else {
            logger.error("MobileNet.mlmodelc is missing from the bundle")
            return nil
        }
        do {
            return try CoreMLModelContainer(model: MLModel(contentsOf: url))
        } catch {
            logger.error("Failed to load MobileNet: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }()

    @concurrent
    static func labels(for pixelBuffer: CVReadOnlyPixelBuffer) async -> [String] {
        guard let model else {
            return []
        }
        let signpostState = PerformanceSignposts.signposter.beginInterval("classifyImage")
        defer { PerformanceSignposts.signposter.endInterval("classifyImage", signpostState) }

        let image = pixelBuffer.withUnsafeBuffer { CIImage(cvPixelBuffer: $0) }
        var request = CoreMLRequest(model: model)
        request.cropAndScaleAction = .centerCrop
        do {
            let observations = try await request.perform(on: image)
            return observations
                .compactMap { $0 as? ClassificationObservation }
                .filter { $0.confidence >= minimumConfidence }
                .sorted { $0.confidence > $1.confidence }
                .prefix(maximumCount)
                .map(\.identifier)
        } catch {
            logger.error("Failed to classify: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
}
