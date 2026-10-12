//
//  OnscreenEntities.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 10/1/26.
//

import SwiftUI
import CoreData
import AppIntents

// Onscreen awareness: Siri can act on the item, category, brand, or seller being viewed
// ("Mark this as disposed"). Nothing is annotated while the lock screen covers the window,
// which still has the belongings behind it.

extension EnvironmentValues {
    @Entry var hidesOnscreenEntities = false
}

// The managed objects with an App Intents entity, identified by the object's uuid
nonisolated protocol OnscreenEntityConvertible: NSManagedObject {
    associatedtype Entity: AppEntity where Entity.ID == UUID
    var uuid: UUID? { get }
    var name: String? { get }
}

extension Item: OnscreenEntityConvertible {
    typealias Entity = ItemEntity
}

extension Kind: OnscreenEntityConvertible {
    typealias Entity = CategoryEntity
}

extension Brand: OnscreenEntityConvertible {
    typealias Entity = BrandEntity
}

extension Seller: OnscreenEntityConvertible {
    typealias Entity = SellerEntity
}

extension OnscreenEntityConvertible {
    // SwiftUI asks for a list's identifiers on a queue of its choosing, so this reads
    // through the object's context
    nonisolated var entityIdentifier: EntityIdentifier? {
        guard let context = managedObjectContext else {
            return nil
        }
        let objectID = self.objectID
        let uuid = context.performAndWait { (context.object(with: objectID) as? Self)?.uuid }
        return uuid.map { EntityIdentifier(for: Entity.self, identifier: $0) }
    }
}

extension View {
    // On a List selecting these objects: its rows are annotated only when the system asks
    func onscreenEntities<Object: OnscreenEntityConvertible>(_ type: Object.Type) -> some View {
        modifier(OnscreenListModifier<Object>())
    }

    // On the detail view of the object; also advertised as the user activity
    func onscreenEntity<Object: OnscreenEntityConvertible>(_ object: Object) -> some View {
        modifier(OnscreenDetailModifier(identifier: object.entityIdentifier, title: object.name ?? ""))
    }
}

private struct OnscreenListModifier<Object: OnscreenEntityConvertible>: ViewModifier {
    @Environment(\.hidesOnscreenEntities) private var hidesEntities

    func body(content: Content) -> some View {
        let hidesEntities = self.hidesEntities
        content
            .appEntityIdentifier(forSelectionType: Object.self) { object in
                hidesEntities ? nil : object.entityIdentifier
            }
    }
}

private struct OnscreenDetailModifier: ViewModifier {
    @Environment(\.hidesOnscreenEntities) private var hidesEntities

    let identifier: EntityIdentifier?
    let title: String

    func body(content: Content) -> some View {
        let identifier = hidesEntities ? nil : self.identifier
        content
            .appEntityIdentifier(identifier)
            .userActivity(Self.activityType, isActive: identifier != nil) { activity in
                activity.title = title
                activity.appEntityIdentifier = identifier
                // Nothing continues an activity on another device, and ItemIndexer covers Spotlight
                activity.isEligibleForHandoff = false
                activity.isEligibleForSearch = false
            }
    }

    private static let activityType = "com.resonance.jlee.Belongings.viewing"
}
