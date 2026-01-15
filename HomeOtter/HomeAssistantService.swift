//
//  HomeAssistantService.swift
//  HomeOtter
//
//  Created by Stefan Konijnenberg on 09/01/2026.
//

import Foundation
import Combine
import ServiceManagement
import UserNotifications

@MainActor
class HomeAssistantService: ObservableObject {
    @Published var config: HAConfig?
    @Published var states: [HAEntityState] = []
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastUpdate: Date?
    @Published var launchAtLogin: Bool = false {
        didSet {
            updateLaunchAtLogin(launchAtLogin)
        }
    }
    
    private var refreshTimer: Timer?
    private var refreshInterval: TimeInterval {
        let saved = UserDefaults.standard.integer(forKey: "refreshInterval")
        return TimeInterval(saved > 0 ? saved : 30)
    }
    
    // Track previous states for notification triggers
    private var previousHealth: HealthStatus = .unknown
    private var previousUpdateAvailable: Bool = false
    
    // UserDefaults keys
    private let urlKey = "homeAssistantURL"
    private let tokenKey = "homeAssistantToken"
    private let dashboardEntitiesKey = "dashboardEntities"
    private let launchAtLoginKey = "launchAtLogin"
    private let menuBarEntityIdKey = "menuBarEntityId"
    
    var baseURL: String {
        get { UserDefaults.standard.string(forKey: urlKey) ?? "" }
        set { 
            UserDefaults.standard.set(newValue, forKey: urlKey)
            objectWillChange.send()
        }
    }
    
    var token: String {
        get { UserDefaults.standard.string(forKey: tokenKey) ?? "" }
        set { 
            UserDefaults.standard.set(newValue, forKey: tokenKey)
            objectWillChange.send()
        }
    }
    
    var menuBarEntityId: String {
        get { UserDefaults.standard.string(forKey: menuBarEntityIdKey) ?? "" }
        set { 
            UserDefaults.standard.set(newValue, forKey: menuBarEntityIdKey)
            objectWillChange.send()
        }
    }
    
    var dashboardEntities: [DashboardEntity] {
        get {
            guard let data = UserDefaults.standard.data(forKey: dashboardEntitiesKey),
                  let entities = try? JSONDecoder().decode([DashboardEntity].self, from: data) else {
                return []
            }
            return entities
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: dashboardEntitiesKey)
            }
            objectWillChange.send()
        }
    }
    
    var isConfigured: Bool {
        !baseURL.isEmpty && !token.isEmpty
    }
    
    var overallHealth: HealthStatus {
        let cpuId = UserDefaults.standard.string(forKey: "cpuEntityId") ?? ""
        let memoryId = UserDefaults.standard.string(forKey: "memoryEntityId") ?? ""
        let diskId = UserDefaults.standard.string(forKey: "diskEntityId") ?? ""
        
        let warningThreshold = Double(UserDefaults.standard.integer(forKey: "healthWarningThreshold")).nonZeroOr(75)
        let criticalThreshold = Double(UserDefaults.standard.integer(forKey: "healthCriticalThreshold")).nonZeroOr(90)
        
        let cpuState = states.first { $0.entityId == cpuId }?.state ?? 
                       autoDetectSensor(type: .cpu)?.state
        let memState = states.first { $0.entityId == memoryId }?.state ?? 
                       autoDetectSensor(type: .memory)?.state
        let diskState = states.first { $0.entityId == diskId }?.state ?? 
                        autoDetectSensor(type: .disk)?.state
        
        let values = [cpuState, memState, diskState]
            .compactMap { $0 }
            .compactMap { Double($0.replacingOccurrences(of: ",", with: ".")) }
        
        guard !values.isEmpty else { return .unknown }
        
        let maxValue = values.max() ?? 0
        
        if maxValue >= criticalThreshold {
            return .critical
        } else if maxValue >= warningThreshold {
            return .warning
        } else {
            return .healthy
        }
    }
    
    enum SensorType { case cpu, memory, disk }
    
    private func autoDetectSensor(type: SensorType) -> HAEntityState? {
        states.first { entity in
            let id = entity.entityId.lowercased()
            let name = entity.friendlyName.lowercased()
            guard entity.entityId.hasPrefix("sensor.") else { return false }
            
            switch type {
            case .cpu:
                let isCPU = id.contains("processor") || id.contains("cpu") || 
                            name.contains("processor") || name.contains("cpu")
                let isUsage = id.contains("use") || id.contains("usage") || id.contains("load") ||
                              name.contains("use") || name.contains("load")
                return isCPU && isUsage
            case .memory:
                let isMemory = id.contains("memory") || id.contains("ram") || id.contains("geheugen") ||
                               name.contains("memory") || name.contains("ram") || name.contains("geheugen")
                return isMemory && entity.attributes.unitOfMeasurement == "%"
            case .disk:
                let isDisk = id.contains("disk") || id.contains("storage") || id.contains("schijf") ||
                             name.contains("disk") || name.contains("storage") || name.contains("schijf")
                return isDisk && entity.attributes.unitOfMeasurement == "%"
            }
        }
    }
    
    var dashboardStates: [HAEntityState] {
        let entityIds = Set(dashboardEntities.map { $0.entityId })
        return states.filter { entityIds.contains($0.entityId) }
    }
    
    // Grouped states for easy browsing
    var groupedStates: [String: [HAEntityState]] {
        Dictionary(grouping: states) { entity in
            entity.entityId.components(separatedBy: ".").first ?? "other"
        }
    }
    
    init() {
        // Sync launch at login status
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        UserDefaults.standard.set(self.launchAtLogin, forKey: launchAtLoginKey)
        
        // Request notification permissions
        Task {
            await NotificationManager.shared.requestPermission()
        }
        
        startAutoRefresh()
        
        // Initial refresh if configured
        if isConfigured {
            Task {
                await refresh()
            }
        }
    }
    
    func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func updateRefreshInterval(_ seconds: Int) {
        // Restart timer with new interval
        startAutoRefresh()
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: launchAtLoginKey)
        let loginService = SMAppService.mainApp
        
        do {
            if enabled {
                if loginService.status != .enabled {
                    try loginService.register()
                }
            } else {
                if loginService.status == .enabled {
                    try loginService.unregister()
                }
            }
        } catch {
            print("Failed to update launch at login status: \(error)")
        }
    }
    
    func refresh() async {
        guard isConfigured else {
            connectionStatus = .disconnected
            return
        }
        
        connectionStatus = .connecting
        
        do {
            async let configTask = fetchConfig()
            async let statesTask = fetchStates()
            
            let (fetchedConfig, fetchedStates) = try await (configTask, statesTask)
            
            self.config = fetchedConfig
            self.states = fetchedStates
            self.connectionStatus = .connected
            self.lastUpdate = Date()
            
            // Check for health status changes and send notifications
            await checkHealthStatusChange()
            
            // Check for HA updates and send notifications
            await checkUpdateAvailability()
        } catch {
            self.connectionStatus = .error(error.localizedDescription)
        }
    }
    
    private func checkHealthStatusChange() async {
        let currentHealth = overallHealth
        
        // Only send notification if status worsens
        if currentHealth != previousHealth {
            switch currentHealth {
            case .warning:
                if previousHealth == .healthy || previousHealth == .unknown {
                    let details = getHealthDetails()
                    await NotificationManager.shared.sendHealthAlert(status: .warning, details: details)
                }
            case .critical:
                if previousHealth != .critical {
                    let details = getHealthDetails()
                    await NotificationManager.shared.sendHealthAlert(status: .critical, details: details)
                }
            case .healthy, .unknown:
                break
            }
            
            previousHealth = currentHealth
        }
    }
    
    private func checkUpdateAvailability() async {
        let updateEntity = states.first { $0.entityId == "update.home_assistant_core_update" }
        let isUpdateAvailable = updateEntity?.state == "on"
        
        // Only notify once when update becomes available
        if isUpdateAvailable && !previousUpdateAvailable {
            if let version = updateEntity?.attributes.latestVersion {
                await NotificationManager.shared.sendUpdateAvailable(version: version)
            }
        }
        
        previousUpdateAvailable = isUpdateAvailable
    }
    
    private func getHealthDetails() -> String {
        let cpuId = UserDefaults.standard.string(forKey: "cpuEntityId") ?? ""
        let memoryId = UserDefaults.standard.string(forKey: "memoryEntityId") ?? ""
        let diskId = UserDefaults.standard.string(forKey: "diskEntityId") ?? ""
        
        let warningThreshold = Double(UserDefaults.standard.integer(forKey: "healthWarningThreshold")).nonZeroOr(75)
        
        let cpuState = states.first { $0.entityId == cpuId }?.state ?? 
                       autoDetectSensor(type: .cpu)?.state
        let memState = states.first { $0.entityId == memoryId }?.state ?? 
                       autoDetectSensor(type: .memory)?.state
        let diskState = states.first { $0.entityId == diskId }?.state ?? 
                        autoDetectSensor(type: .disk)?.state
        
        var issues: [String] = []
        
        if let cpu = cpuState, let cpuVal = Double(cpu.replacingOccurrences(of: ",", with: ".")), cpuVal >= warningThreshold {
            issues.append("CPU: \(Int(cpuVal))%")
        }
        if let mem = memState, let memVal = Double(mem.replacingOccurrences(of: ",", with: ".")), memVal >= warningThreshold {
            issues.append("Memory: \(Int(memVal))%")
        }
        if let disk = diskState, let diskVal = Double(disk.replacingOccurrences(of: ",", with: ".")), diskVal >= warningThreshold {
            issues.append("Disk: \(Int(diskVal))%")
        }
        
        return issues.isEmpty ? "System threshold exceeded" : issues.joined(separator: ", ")
    }
    
    private func fetchConfig() async throws -> HAConfig {
        let url = URL(string: "\(baseURL)/api/config")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HAError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HAError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(HAConfig.self, from: data)
    }
    
    private func fetchStates() async throws -> [HAEntityState] {
        let url = URL(string: "\(baseURL)/api/states")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HAError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HAError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([HAEntityState].self, from: data)
    }
    
    // Toggle a switch/light
    func toggleEntity(_ entityId: String) async {
        guard isConfigured else { return }
        
        let domain = entityId.components(separatedBy: ".").first ?? "homeassistant"
        let service = "toggle"
        
        let url = URL(string: "\(baseURL)/api/services/\(domain)/\(service)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["entity_id": entityId]
        request.httpBody = try? JSONEncoder().encode(body)
        
        do {
            _ = try await URLSession.shared.data(for: request)
            // Refresh states after toggle
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            await refresh()
        } catch {
            print("Toggle failed: \(error)")
        }
    }
    
    func addToDashboard(entityId: String) {
        var entities = dashboardEntities
        if !entities.contains(where: { $0.entityId == entityId }) {
            entities.append(DashboardEntity(entityId: entityId))
            dashboardEntities = entities
        }
    }
    
    func removeFromDashboard(entityId: String) {
        var entities = dashboardEntities
        entities.removeAll { $0.entityId == entityId }
        dashboardEntities = entities
    }
    
    func isInDashboard(entityId: String) -> Bool {
        dashboardEntities.contains { $0.entityId == entityId }
    }
}

// MARK: - Errors
enum HAError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        }
    }
}

// MARK: - Notification Manager
class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("Notification permission granted")
                // Enable by default after permission is granted
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                }
            }
        } catch {
            print("Notification permission error: \(error)")
        }
    }
    
    func sendHealthAlert(status: HealthStatus, details: String) async {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "HomeOtter Health Alert"
        
        switch status {
        case .warning:
            content.body = "⚠️ Warning: \(details)"
            content.sound = .default
        case .critical:
            content.body = "🚨 Critical: \(details)"
            content.sound = .defaultCritical
        case .healthy, .unknown:
            return // Don't send notifications for these
        }
        
        let request = UNNotificationRequest(
            identifier: "health-alert-\(UUID().uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
    
    func sendUpdateAvailable(version: String) async {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Home Assistant Update Available"
        content.body = "🎉 Version \(version) is now available!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "ha-update-available",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
}
