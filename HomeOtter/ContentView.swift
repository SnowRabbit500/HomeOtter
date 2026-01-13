//
//  ContentView.swift
//  HomeOtter
//
//  Created by Stefan Konijnenberg on 09/01/2026.
//

import SwiftUI
import Combine
import AppKit

struct ContentView: View {
    @ObservedObject var service: HomeAssistantService
    var openSettings: () -> Void
    var openEntityBrowser: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(service: service, openSettings: openSettings, openEntityBrowser: openEntityBrowser)
            
            Divider()
            
            if !service.isConfigured {
                // Not configured state
                NotConfiguredView(openSettings: openSettings)
            } else if service.connectionStatus == .connecting {
                // Loading state
                LoadingView()
            } else if case .error(let message) = service.connectionStatus {
                // Error state
                ErrorView(message: message, service: service)
            } else {
                // Main content
                MainDashboardView(service: service)
            }
            
            Divider()
            
            // Footer
            FooterView(service: service)
        }
        .frame(width: 340)
        .background(.thickMaterial)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
    }
}

// MARK: - Header
struct HeaderView: View {
    @ObservedObject var service: HomeAssistantService
    var openSettings: () -> Void
    var openEntityBrowser: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Modern Logo and Title
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.15), .blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                    
                    Text("🦦")
                        .font(.system(size: 20))
                }
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("HomeOtter")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    
                    HStack(spacing: 5) {
                        ConnectionIndicator(status: service.connectionStatus)
                        
                        if let config = service.config {
                            Text(config.locationName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 6) {
                HeaderActionButton(icon: "arrow.clockwise", help: "Refresh") {
                    Task { await service.refresh() }
                }
                
                HeaderActionButton(icon: "safari", help: "Open Home Assistant") {
                    if !service.baseURL.isEmpty, let url = URL(string: service.baseURL) {
                        NSWorkspace.shared.open(url)
                    }
                }
                .disabled(!service.isConfigured)
                
                HeaderActionButton(icon: "square.grid.2x2", help: "Browse entities") {
                    openEntityBrowser()
                }
                
                HeaderActionButton(icon: "gearshape.fill", help: "Settings") {
                    openSettings()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct HeaderActionButton: View {
    let icon: String
    let help: String
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isHovering ? .primary : .secondary)
                .frame(width: 30, height: 30)
                .background(isHovering ? Color.primary.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Connection Indicator
struct ConnectionIndicator: View {
    let status: ConnectionStatus
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .shadow(color: statusColor.opacity(0.4), radius: 2)
            
            if case .connecting = status {
                Circle()
                    .stroke(statusColor.opacity(0.5), lineWidth: 1)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 2.5 : 1)
                    .opacity(isAnimating ? 0 : 1)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                            isAnimating = true
                        }
                    }
            }
        }
        .help(status.description)
    }
    
    private var statusColor: Color {
        switch status {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .gray
        case .error: return .red
        }
    }
}

// MARK: - Not Configured View
struct NotConfiguredView: View {
    var openSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.and.flag")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("Welcome to HomeOtter!")
                .font(.headline)
            
            Text("Configure your Home Assistant\nconnection to get started")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                openSettings()
            } label: {
                Label("Configure", systemImage: "gear")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            
            Text("Connecting to Home Assistant...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let service: HomeAssistantService
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 42))
                .foregroundStyle(.red)
            
            Text("Connection Error")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                Task { await service.refresh() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

// MARK: - Main Dashboard
struct MainDashboardView: View {
    @ObservedObject var service: HomeAssistantService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Home Assistant Status & Updates
                if let config = service.config {
                    HomeAssistantStatusView(service: service, config: config)
                }

                // System Health Panel (always first)
                if !service.states.isEmpty {
                    SystemHealthView(service: service)
                }
                
                // Quick Stats Section
                if !service.states.isEmpty {
                    QuickStatsView(service: service)
                }
                
                if service.dashboardEntities.isEmpty {
                    // Empty dashboard hint
                    EmptyDashboardView()
                } else {
                    // User's selected entities
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pinned Entities")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(service.dashboardStates) { entity in
                                EntityCard(entity: entity, service: service)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .frame(minHeight: 400, maxHeight: 650)
    }
}

// MARK: - Home Assistant Status View
struct HomeAssistantStatusView: View {
    @ObservedObject var service: HomeAssistantService
    let config: HAConfig
    
    private var updateEntity: HAEntityState? {
        service.states.first { $0.entityId == "update.home_assistant_core_update" }
    }
    
    private var isUpdateAvailable: Bool {
        updateEntity?.state == "on"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // HA Logo Style Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                    Image(systemName: "house.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Home Assistant")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("Core \(config.version)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isUpdateAvailable {
                    Text("UPDATE")
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            
            if isUpdateAvailable, let entity = updateEntity {
                Button {
                    if let urlString = entity.attributes.releaseUrl, let url = URL(string: urlString) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("New version available: \(entity.attributes.latestVersion ?? "Unknown")")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("Click to see release notes")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Your system is up to date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(14)
        .background(.thickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUpdateAvailable ? .orange.opacity(0.3) : .blue.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - System Health View
struct SystemHealthView: View {
    @ObservedObject var service: HomeAssistantService
    
    // Get configured entity IDs from UserDefaults
    private var configuredCpuId: String {
        UserDefaults.standard.string(forKey: "cpuEntityId") ?? ""
    }
    
    private var configuredMemoryId: String {
        UserDefaults.standard.string(forKey: "memoryEntityId") ?? ""
    }
    
    private var configuredDiskId: String {
        UserDefaults.standard.string(forKey: "diskEntityId") ?? ""
    }
    
    // Find sensors - use configured first, then auto-detect
    private var cpuSensor: HAEntityState? {
        // Use configured entity if set
        if !configuredCpuId.isEmpty {
            return service.states.first { $0.entityId == configuredCpuId }
        }
        
        // Auto-detect fallback
        return service.states.first { entity in
            let id = entity.entityId.lowercased()
            let name = entity.friendlyName.lowercased()
            guard entity.entityId.hasPrefix("sensor.") else { return false }
            
            let isCPU = id.contains("processor") || id.contains("cpu") || 
                        name.contains("processor") || name.contains("cpu")
            let isUsage = id.contains("use") || id.contains("usage") || id.contains("load") ||
                          name.contains("use") || name.contains("load")
            
            return isCPU && isUsage
        }
    }
    
    private var memorySensor: HAEntityState? {
        // Use configured entity if set
        if !configuredMemoryId.isEmpty {
            return service.states.first { $0.entityId == configuredMemoryId }
        }
        
        // Auto-detect fallback - prefer percentage sensors
        return service.states.first { entity in
            let id = entity.entityId.lowercased()
            let name = entity.friendlyName.lowercased()
            guard entity.entityId.hasPrefix("sensor.") else { return false }
            
            let isMemory = id.contains("memory") || id.contains("ram") || id.contains("geheugen") ||
                           name.contains("memory") || name.contains("ram") || name.contains("geheugen")
            let isPercent = entity.attributes.unitOfMeasurement == "%"
            
            return isMemory && isPercent
        }
    }
    
    private var diskSensor: HAEntityState? {
        // Use configured entity if set
        if !configuredDiskId.isEmpty {
            return service.states.first { $0.entityId == configuredDiskId }
        }
        
        // Auto-detect fallback - prefer percentage sensors
        return service.states.first { entity in
            let id = entity.entityId.lowercased()
            let name = entity.friendlyName.lowercased()
            guard entity.entityId.hasPrefix("sensor.") else { return false }
            
            let isDisk = id.contains("disk") || id.contains("storage") || id.contains("schijf") ||
                         name.contains("disk") || name.contains("storage") || name.contains("schijf")
            let isPercent = entity.attributes.unitOfMeasurement == "%"
            
            return isDisk && isPercent
        }
    }
    
    private var isConfigured: Bool {
        !configuredCpuId.isEmpty || !configuredMemoryId.isEmpty || !configuredDiskId.isEmpty
    }
    
    private var hasAnySensor: Bool {
        cpuSensor != nil || memorySensor != nil || diskSensor != nil
    }
    
    // Get threshold from settings
    private var warningThreshold: Double {
        Double(UserDefaults.standard.integer(forKey: "healthWarningThreshold")).nonZeroOr(70)
    }
    
    private var criticalThreshold: Double {
        Double(UserDefaults.standard.integer(forKey: "healthCriticalThreshold")).nonZeroOr(90)
    }
    
    // Overall health status based on worst metric
    private var overallStatus: HealthStatus {
        service.overallHealth
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: overallStatus.icon)
                    .foregroundStyle(overallStatusColor)
                Text("System Health")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            if hasAnySensor {
                HStack(spacing: 8) {
                    // CPU
                    HealthGauge(
                        icon: "cpu",
                        label: "CPU",
                        value: cpuSensor?.state,
                        unit: cpuSensor?.attributes.unitOfMeasurement ?? "%",
                        color: gaugeColor(for: cpuSensor?.state),
                        history: service.cpuHistory
                    )
                    
                    // Memory
                    HealthGauge(
                        icon: "memorychip",
                        label: "Memory",
                        value: memorySensor?.state,
                        unit: memorySensor?.attributes.unitOfMeasurement ?? "%",
                        color: gaugeColor(for: memorySensor?.state),
                        history: service.memoryHistory
                    )
                    
                    // Disk
                    HealthGauge(
                        icon: "internaldrive",
                        label: "Disk",
                        value: diskSensor?.state,
                        unit: diskSensor?.attributes.unitOfMeasurement ?? "%",
                        color: gaugeColor(for: diskSensor?.state),
                        history: service.diskHistory
                    )
                }
            } else {
                // No sensors found - show setup hint
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "gear.badge")
                            .foregroundStyle(.secondary)
                        Text("Configure sensors in Settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Click ⚙️ → System Health Entities")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            overallStatusColor.opacity(0.12),
                            overallStatusColor.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(overallStatusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var overallStatusColor: Color {
        switch overallStatus {
        case .healthy: return .green
        case .warning: return .orange
        case .critical: return .red
        case .unknown: return .gray
        }
    }
    
    private func gaugeColor(for value: String?) -> Color {
        guard let value = value, 
              let percent = Double(value.replacingOccurrences(of: ",", with: ".")) else { return .gray }
        
        if percent >= criticalThreshold {
            return .red
        } else if percent >= warningThreshold {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Health Status
// Removed: Moved to Models.swift

// Helper extension
// Removed: Moved to Models.swift


// MARK: - Health Gauge
struct HealthGauge: View {
    let icon: String
    let label: String
    let value: String?
    let unit: String
    let color: Color
    let history: [Double]
    
    private var percentage: Double {
        guard let value = value, let percent = Double(value.replacingOccurrences(of: ",", with: ".")) else { return 0 }
        return min(max(percent, 0), 100)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Circular gauge
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 3.5)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: percentage / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            }
            
            VStack(spacing: 2) {
                if let value = value {
                    Text("\(value)\(unit)")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(color)
                } else {
                    Text("--").font(.system(.caption, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
                }
                
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            // Sparkline
            SparklineView(history: history, color: color)
                .frame(height: 14)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SparklineView: View {
    let history: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard history.count > 1 else { return }
                
                let stepX = geometry.size.width / CGFloat(history.count - 1)
                let maxY = 100.0
                let minY = 0.0
                
                for (index, value) in history.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height * (1.0 - CGFloat((value - minY) / (maxY - minY)))
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - Empty Dashboard
struct EmptyDashboardView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "star")
                .font(.title)
                .foregroundStyle(.secondary)
            
            Text("No entities pinned")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Click the grid icon to browse and pin entities")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Entity Card
struct EntityCard: View {
    let entity: HAEntityState
    @ObservedObject var service: HomeAssistantService
    
    @State private var isHovering = false
    
    private var isToggleable: Bool {
        let domain = entity.entityId.components(separatedBy: ".").first ?? ""
        return ["light", "switch", "fan", "cover", "lock"].contains(domain)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(stateColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: entity.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(stateColor)
            }
            
            // Entity info
            VStack(alignment: .leading, spacing: 2) {
                Text(entity.friendlyName)
                    .font(.system(.body, weight: .medium))
                    .lineLimit(1)
                
                Text(entity.displayState)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Toggle button for supported entities
            if isToggleable {
                Button {
                    Task {
                        await service.toggleEntity(entity.entityId)
                    }
                } label: {
                    Image(systemName: entity.state == "on" ? "power.circle.fill" : "power.circle")
                        .font(.title2)
                        .foregroundStyle(entity.state == "on" ? .green : .secondary)
                }
                .buttonStyle(.borderless)
                .help("Toggle")
            }
            
            // Remove from dashboard
            if isHovering {
                Button {
                    service.removeFromDashboard(entityId: entity.entityId)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Remove from dashboard")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(stateColor.opacity(0.3), lineWidth: 1)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var stateColor: Color {
        switch entity.state.lowercased() {
        case "on", "open", "unlocked", "playing", "home", "above_horizon":
            return .green
        case "off", "closed", "locked", "paused", "idle":
            return .secondary
        case "unavailable", "unknown":
            return .red
        default:
            return .blue
        }
    }
}

// MARK: - Quick Stats
struct QuickStatsView: View {
    @ObservedObject var service: HomeAssistantService
    
    private var lightsOn: Int {
        service.states.filter { $0.entityId.hasPrefix("light.") && $0.state == "on" }.count
    }
    
    private var switchesOn: Int {
        service.states.filter { $0.entityId.hasPrefix("switch.") && $0.state == "on" }.count
    }
    
    private var updatesAvailable: Int {
        service.states.filter { $0.entityId.hasPrefix("update.") && $0.state == "on" }.count
    }
    
    private var personsHome: Int {
        service.states.filter { $0.entityId.hasPrefix("person.") && $0.state == "home" }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Stats")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                StatBadge(icon: "lightbulb.fill", value: "\(lightsOn)", label: "Lights", color: .yellow)
                StatBadge(icon: "power", value: "\(switchesOn)", label: "Switches", color: .green)
                StatBadge(icon: "arrow.down.circle", value: "\(updatesAvailable)", label: "Updates", color: updatesAvailable > 0 ? .orange : .secondary)
                StatBadge(icon: "person.fill", value: "\(personsHome)", label: "Home", color: .blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
        )
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Footer
struct FooterView: View {
    @ObservedObject var service: HomeAssistantService
    
    // Timer to update the "last updated" text every second
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var lastUpdateText: String {
        guard let date = service.lastUpdate else { return "Never" }
        let seconds = Int(currentTime.timeIntervalSince(date))
        
        if seconds < 60 {
            return "\(seconds)s ago"
        } else if seconds < 3600 {
            return "\(seconds / 60)m ago"
        } else {
            return "\(seconds / 3600)h ago"
        }
    }
    
    private var refreshInterval: Int {
        let saved = UserDefaults.standard.integer(forKey: "refreshInterval")
        return saved > 0 ? saved : 30
    }
    
    var body: some View {
        HStack {
            // Last update time
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Updated \(lastUpdateText)")
                    .font(.caption2)
                
                Text("•")
                    .foregroundStyle(.tertiary)
                
                Text("Every \(refreshInterval)s")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.secondary)
            
            Spacer()
            
            // Quit button
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

#Preview {
    ContentView(service: HomeAssistantService(), openSettings: {}, openEntityBrowser: {})
}
