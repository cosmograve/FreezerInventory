import Foundation
import SwiftData

enum ProductStorageStatus: String, Codable, CaseIterable {
    case frozen
    case defrost
    case done
}

enum ProductDisposition: String, Codable, CaseIterable {
    case active
    case archived
    case deleted
}

enum ProductUsageEventType: String, Codable, CaseIterable {
    case used
    case wasted
}

@Model
final class StoredProduct {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var weightGrams: Int
    var frozenDate: Date
    var storageTemperatureC: Int
    var note: String
    var expirationDate: Date
    var statusRaw: String
    var dispositionRaw: String
    var createdAt: Date
    var defrostedAt: Date?
    var archivedAt: Date?
    var deletedAt: Date?
    var defrostMethodRaw: String?
    var defrostTotalSeconds: Int?
    var defrostRemainingSeconds: Int?
    var defrostRunUntil: Date?
    var defrostIsRunning: Bool?

    init(
        id: UUID = UUID(),
        name: String,
        categoryRaw: String,
        weightGrams: Int,
        frozenDate: Date,
        storageTemperatureC: Int,
        note: String,
        expirationDate: Date,
        status: ProductStorageStatus = .frozen,
        disposition: ProductDisposition = .active,
        createdAt: Date = .now,
        defrostedAt: Date? = nil,
        archivedAt: Date? = nil,
        deletedAt: Date? = nil,
        defrostMethodRaw: String? = nil,
        defrostTotalSeconds: Int? = nil,
        defrostRemainingSeconds: Int? = nil,
        defrostRunUntil: Date? = nil,
        defrostIsRunning: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = categoryRaw
        self.weightGrams = weightGrams
        self.frozenDate = frozenDate
        self.storageTemperatureC = storageTemperatureC
        self.note = note
        self.expirationDate = expirationDate
        self.statusRaw = status.rawValue
        self.dispositionRaw = disposition.rawValue
        self.createdAt = createdAt
        self.defrostedAt = defrostedAt
        self.archivedAt = archivedAt
        self.deletedAt = deletedAt
        self.defrostMethodRaw = defrostMethodRaw
        self.defrostTotalSeconds = defrostTotalSeconds
        self.defrostRemainingSeconds = defrostRemainingSeconds
        self.defrostRunUntil = defrostRunUntil
        self.defrostIsRunning = defrostIsRunning
    }

    var status: ProductStorageStatus {
        get { ProductStorageStatus(rawValue: statusRaw) ?? .frozen }
        set { statusRaw = newValue.rawValue }
    }

    var disposition: ProductDisposition {
        get { ProductDisposition(rawValue: dispositionRaw) ?? .active }
        set { dispositionRaw = newValue.rawValue }
    }
}

@Model
final class ProductUsageEvent {
    @Attribute(.unique) var id: UUID
    var eventTypeRaw: String
    var createdAt: Date
    var productName: String
    var weightGrams: Int

    init(
        id: UUID = UUID(),
        eventType: ProductUsageEventType,
        createdAt: Date = .now,
        productName: String,
        weightGrams: Int
    ) {
        self.id = id
        self.eventTypeRaw = eventType.rawValue
        self.createdAt = createdAt
        self.productName = productName
        self.weightGrams = weightGrams
    }

    var eventType: ProductUsageEventType {
        get { ProductUsageEventType(rawValue: eventTypeRaw) ?? .used }
        set { eventTypeRaw = newValue.rawValue }
    }
}
