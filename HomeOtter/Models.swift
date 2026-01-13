//
//  Models.swift
//  HomeOtter
//
//  Created by Stefan Konijnenberg on 09/01/2026.
//

import Foundation

// MARK: - Home Assistant Config Response
struct HAConfig: Codable {
    let locationName: String
    let version: String
    let state: String
    let timeZone: String
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case locationName = "location_name"
        case version
        case state
        case timeZone = "time_zone"
        case latitude
        case longitude
    }
}

// MARK: - Home Assistant Entity State
struct HAEntityState: Codable, Identifiable {
    let entityId: String
    let state: String
    let attributes: HAAttributes
    let lastChanged: String
    let lastUpdated: String
    
    var id: String { entityId }
    
    enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state
        case attributes
        case lastChanged = "last_changed"
        case lastUpdated = "last_updated"
    }
    
    var friendlyName: String {
        attributes.friendlyName ?? entityId.components(separatedBy: ".").last?.replacingOccurrences(of: "_", with: " ").capitalized ?? entityId
    }
    
    var icon: String {
        // Map entity types to SF Symbols
        let domain = entityId.components(separatedBy: ".").first ?? ""
        switch domain {
        case "light": return state == "on" ? "lightbulb.fill" : "lightbulb"
        case "switch": return state == "on" ? "power.circle.fill" : "power.circle"
        case "sensor": return sensorIcon
        case "binary_sensor": return state == "on" ? "circle.fill" : "circle"
        case "climate": return "thermometer"
        case "lock": return state == "locked" ? "lock.fill" : "lock.open"
        case "cover": return state == "open" ? "blinds.horizontal.open" : "blinds.horizontal.closed"
        case "update": return state == "on" ? "arrow.triangle.2.circlepath.circle.fill" : "checkmark.circle"
        case "person": return "person.fill"
        case "sun": return state == "above_horizon" ? "sun.max.fill" : "moon.fill"
        case "weather": return "cloud.sun.fill"
        case "media_player": return state == "playing" ? "play.circle.fill" : "pause.circle"
        case "vacuum": return "sparkles"
        case "fan": return "fan"
        case "camera": return "camera.fill"
        case "alarm_control_panel": return "shield.fill"
        default: return "questionmark.circle"
        }
    }
    
    private var sensorIcon: String {
        let unit = attributes.unitOfMeasurement ?? ""
        if unit.contains("°") || unit.contains("C") || unit.contains("F") {
            return "thermometer"
        } else if unit.contains("%") && entityId.contains("humidity") {
            return "humidity.fill"
        } else if unit.contains("%") && entityId.contains("battery") {
            return "battery.100"
        } else if unit.contains("W") || unit.contains("kW") {
            return "bolt.fill"
        } else if unit.contains("lx") || unit.contains("lm") {
            return "sun.max"
        }
        return "sensor.fill"
    }
    
    var stateColor: String {
        switch state.lowercased() {
        case "on", "open", "unlocked", "playing", "home", "above_horizon":
            return "stateOn"
        case "off", "closed", "locked", "paused", "away", "below_horizon":
            return "stateOff"
        case "unavailable", "unknown":
            return "stateUnavailable"
        default:
            return "stateNeutral"
        }
    }
    
    var displayState: String {
        if let unit = attributes.unitOfMeasurement, !unit.isEmpty {
            return "\(state) \(unit)"
        }
        return state.capitalized
    }
}

struct HAAttributes: Codable {
    let friendlyName: String?
    let unitOfMeasurement: String?
    let deviceClass: String?
    let installedVersion: String?
    let latestVersion: String?
    let entityPicture: String?
    let releaseUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case friendlyName = "friendly_name"
        case unitOfMeasurement = "unit_of_measurement"
        case deviceClass = "device_class"
        case installedVersion = "installed_version"
        case latestVersion = "latest_version"
        case entityPicture = "entity_picture"
        case releaseUrl = "release_url"
    }
}

// MARK: - Dashboard Entity (User-selected entities to show)
struct DashboardEntity: Codable, Identifiable, Equatable, Hashable {
    let entityId: String
    var id: String { entityId }
    
    static func == (lhs: DashboardEntity, rhs: DashboardEntity) -> Bool {
        lhs.entityId == rhs.entityId
    }
}

// MARK: - Connection Status
enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
    
    var icon: String {
        switch self {
        case .disconnected: return "wifi.slash"
        case .connecting: return "wifi.exclamationmark"
        case .connected: return "wifi"
        case .error: return "exclamationmark.triangle"
        }
    }
    
    var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error(let msg): return msg
        }
    }
}

// MARK: - Health Status
enum HealthStatus: String {
    case healthy
    case warning
    case critical
    case unknown
    
    var icon: String {
        switch self {
        case .healthy: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.shield.fill"
        case .critical: return "xmark.shield.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Extensions
extension Double {
    func nonZeroOr(_ defaultValue: Double) -> Double {
        self == 0 ? defaultValue : self
    }
}


