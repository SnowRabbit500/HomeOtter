//
//  SettingsView.swift
//  HomeOtter
//
//  Created by Stefan Konijnenberg on 09/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var service: HomeAssistantService
    @Environment(\.dismiss) private var dismiss
    
    @State private var urlText: String = ""
    @State private var tokenText: String = ""
    @State private var showToken: Bool = false
    @State private var isTesting: Bool = false
    @State private var testResult: TestResult?
    
    // Thresholds
    @State private var warningThreshold: Double = 75
    @State private var criticalThreshold: Double = 90
    
    // Appearance
    @State private var appearanceMode: AppearanceMode = .auto
    @State private var refreshInterval: Double = 30
    @State private var launchAtLogin: Bool = false
    @State private var notificationsEnabled: Bool = false
    
    // System Health Entities
    @State private var cpuEntityId: String = ""
    @State private var memoryEntityId: String = ""
    @State private var diskEntityId: String = ""
    @State private var menuBarEntityId: String = ""
    @State private var showEntityPicker: EntityPickerType?
    
    enum EntityPickerType: Identifiable {
        case cpu, memory, disk, menuBar
        var id: Self { self }
    }
    
    enum TestResult {
        case success(String)
        case failure(String)
    }
    
    // The body is now very simple to help the compiler
    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            mainContent
        }
        .frame(width: 420, height: 850)
        .background(viewBackground)
        .onAppear(perform: loadSettings)
        .modifier(SettingsLogicModifier(
            warningThreshold: $warningThreshold,
            criticalThreshold: $criticalThreshold,
            appearanceMode: $appearanceMode,
            refreshInterval: $refreshInterval,
            cpuEntityId: $cpuEntityId,
            memoryEntityId: $memoryEntityId,
            diskEntityId: $diskEntityId,
            menuBarEntityId: $menuBarEntityId,
            launchAtLogin: $launchAtLogin,
            notificationsEnabled: $notificationsEnabled,
            service: service,
            parent: self
        ))
        .sheet(item: $showEntityPicker, content: entityPickerSheet)
    }
    
    // MARK: - Subviews
    
    private var viewBackground: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor).opacity(0.9)
            Rectangle().fill(.thickMaterial)
        }
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.orange.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: "gearshape.fill").font(.title3).foregroundStyle(.orange)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings").font(.headline)
                Text("Configuration & Preferences").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.secondary)
            }.buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                connectionSection
                menuBarSection
                systemHealthSection
                alertThresholdsSection
                appearanceSection
                infoSection
                aboutSection
            }
            .padding()
        }
    }
    
    private var menuBarSection: some View {
        SettingsSection(title: "Menu Bar Display", icon: "menubar.rectangle", color: .blue) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Show a specific sensor value directly in your macOS menu bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                EntitySelectorRow(icon: "chart.bar.fill", label: "Menu Bar Sensor", entityId: $menuBarEntityId, color: .blue) {
                    showEntityPicker = .menuBar
                }
            }
        }
    }

    private var connectionSection: some View {
        SettingsSection(title: "Connection", icon: "network", color: .blue) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Home Assistant URL").font(.subheadline).foregroundStyle(.secondary)
                    TextField("https://your-ha-instance.ui.nabu.casa", text: $urlText)
                        .textFieldStyle(.roundedBorder).font(.system(.body, design: .monospaced))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Long-Lived Access Token").font(.subheadline).foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        if showToken {
                            TextField("Paste your token here", text: $tokenText)
                                .textFieldStyle(.roundedBorder).font(.system(.caption, design: .monospaced))
                        } else {
                            SecureField("Paste your token here", text: $tokenText).textFieldStyle(.roundedBorder)
                        }
                        Button { showToken.toggle() } label: {
                            Image(systemName: showToken ? "eye.slash" : "eye").foregroundStyle(.secondary)
                        }.buttonStyle(.borderless)
                    }
                }
                HStack(spacing: 12) {
                    Button(action: testConnection) {
                        HStack {
                            if isTesting { ProgressView().controlSize(.small) }
                            else { Image(systemName: "antenna.radiowaves.left.and.right") }
                            Text("Test Connection")
                        }.frame(maxWidth: .infinity)
                    }.buttonStyle(.bordered)
                    Button("Save & Close") { saveSettings() }
                        .buttonStyle(.borderedProminent).tint(.blue)
                }
                if let result = testResult { TestResultView(result: result) }
            }
        }
    }
    
    private var systemHealthSection: some View {
        SettingsSection(title: "System Health Entities", icon: "heart.text.clipboard", color: .pink) {
            VStack(alignment: .leading, spacing: 12) {
                EntitySelectorRow(icon: "cpu", label: "CPU", entityId: $cpuEntityId, color: .green) { showEntityPicker = .cpu }
                EntitySelectorRow(icon: "memorychip", label: "Memory", entityId: $memoryEntityId, color: .blue) { showEntityPicker = .memory }
                EntitySelectorRow(icon: "internaldrive", label: "Disk", entityId: $diskEntityId, color: .orange) { showEntityPicker = .disk }
            }
        }
    }
    
    private var alertThresholdsSection: some View {
        SettingsSection(title: "Alert Thresholds", icon: "bell.badge", color: .orange) {
            VStack(alignment: .leading, spacing: 16) {
                ThresholdSlider(title: "Warning", value: $warningThreshold, color: .orange, range: 0...99)
                ThresholdSlider(title: "Critical", value: $criticalThreshold, color: .red, range: 0...99)
                HStack(spacing: 20) {
                    ThresholdPreview(label: "Healthy", range: "0-\(Int(warningThreshold))%", color: .green)
                    ThresholdPreview(label: "Warning", range: "\(Int(warningThreshold))-\(Int(criticalThreshold))%", color: .orange)
                    ThresholdPreview(label: "Critical", range: ">\(Int(criticalThreshold))%", color: .red)
                }
            }
        }
    }
    
    private var appearanceSection: some View {
        SettingsSection(title: "General Settings", icon: "paintpalette", color: .purple) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme").font(.subheadline).foregroundStyle(.secondary)
                    Picker("Theme", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Label(mode.label, systemImage: mode.icon).tag(mode)
                        }
                    }.pickerStyle(.segmented)
                }
                Divider()
                Toggle("Launch HomeOtter at login", isOn: $launchAtLogin)
                    .toggleStyle(.switch).font(.subheadline)
                Divider()
                Toggle("Enable notifications", isOn: $notificationsEnabled)
                    .toggleStyle(.switch).font(.subheadline)
                Text("Get notified when thresholds are exceeded or HA updates are available")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Refresh Interval")
                        Spacer()
                        Text("\(Int(refreshInterval))s").monospaced().foregroundStyle(.purple)
                    }
                    Slider(value: $refreshInterval, in: 10...120, step: 10).tint(.purple)
                }
            }
        }
    }
    
    private var infoSection: some View {
        SettingsSection(title: "Home Assistant Info", icon: "house.fill", color: .cyan) {
            VStack(alignment: .leading, spacing: 8) {
                if let config = service.config {
                    InfoRow(label: "Location", value: config.locationName)
                    InfoRow(label: "Version", value: config.version)
                    InfoRow(label: "State", value: config.state)
                    InfoRow(label: "Timezone", value: config.timeZone)
                } else {
                    Text("Connect to see Home Assistant info").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle", color: .gray) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("HomeOtter").font(.headline)
                    Spacer()
                    Text("v1.0").foregroundStyle(.secondary)
                }
                Text("A menu bar companion for Home Assistant").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Helpers
    
    func entityPickerSheet(for pickerType: EntityPickerType) -> some View {
        EntityPickerSheet(
            service: service,
            pickerType: pickerType,
            onSelect: { entityId in
                switch pickerType {
                case .cpu: cpuEntityId = entityId
                case .memory: memoryEntityId = entityId
                case .disk: diskEntityId = entityId
                case .menuBar: menuBarEntityId = entityId
                }
                showEntityPicker = nil
            }
        )
    }
    
    func loadSettings() {
        urlText = service.baseURL
        tokenText = service.token
        let savedWarning = UserDefaults.standard.integer(forKey: "healthWarningThreshold")
        let savedCritical = UserDefaults.standard.integer(forKey: "healthCriticalThreshold")
        warningThreshold = savedWarning > 0 ? Double(savedWarning) : 75
        criticalThreshold = savedCritical > 0 ? Double(savedCritical) : 90
        if let savedMode = UserDefaults.standard.string(forKey: "appearanceMode"), let mode = AppearanceMode(rawValue: savedMode) { appearanceMode = mode }
        let savedInterval = UserDefaults.standard.integer(forKey: "refreshInterval")
        refreshInterval = savedInterval > 0 ? Double(savedInterval) : 30
        cpuEntityId = UserDefaults.standard.string(forKey: "cpuEntityId") ?? ""
        memoryEntityId = UserDefaults.standard.string(forKey: "memoryEntityId") ?? ""
        diskEntityId = UserDefaults.standard.string(forKey: "diskEntityId") ?? ""
        menuBarEntityId = service.menuBarEntityId
        launchAtLogin = service.launchAtLogin
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }
    
    func saveWarningThreshold(_ n: Double) {
        UserDefaults.standard.set(Int(n), forKey: "healthWarningThreshold")
        if n >= criticalThreshold { criticalThreshold = min(n + 5, 99); UserDefaults.standard.set(Int(criticalThreshold), forKey: "healthCriticalThreshold") }
    }
    
    func saveCriticalThreshold(_ n: Double) {
        UserDefaults.standard.set(Int(n), forKey: "healthCriticalThreshold")
        if n <= warningThreshold { warningThreshold = max(n - 5, 0); UserDefaults.standard.set(Int(warningThreshold), forKey: "healthWarningThreshold") }
    }
    
    func saveAppearanceMode(_ n: AppearanceMode) {
        UserDefaults.standard.set(n.rawValue, forKey: "appearanceMode")
        applyAppearance(n)
    }
    
    func saveRefreshInterval(_ n: Double) {
        UserDefaults.standard.set(Int(n), forKey: "refreshInterval")
        service.updateRefreshInterval(Int(n))
    }
    
    private func applyAppearance(_ mode: AppearanceMode) {
        switch mode {
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        case .auto: NSApp.appearance = nil
        }
    }
    
    func testConnection() {
        isTesting = true
        testResult = nil
        let originalURL = service.baseURL
        let originalToken = service.token
        service.baseURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        service.token = tokenText.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await service.refresh()
            await MainActor.run {
                isTesting = false
                switch service.connectionStatus {
                case .connected:
                    if let config = service.config { testResult = .success("Connected to \(config.locationName) (HA \(config.version))") }
                    else { testResult = .success("Connected successfully!") }
                case .error(let msg):
                    testResult = .failure(msg)
                    service.baseURL = originalURL
                    service.token = originalToken
                default:
                    testResult = .failure("Connection failed")
                    service.baseURL = originalURL
                    service.token = originalToken
                }
            }
        }
    }
    
    func saveSettings() {
        service.baseURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        service.token = tokenText.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await service.refresh()
            await MainActor.run { dismiss() }
        }
    }
}

// MARK: - Settings Logic Modifier
struct SettingsLogicModifier: ViewModifier {
    @Binding var warningThreshold: Double
    @Binding var criticalThreshold: Double
    @Binding var appearanceMode: AppearanceMode
    @Binding var refreshInterval: Double
    @Binding var cpuEntityId: String
    @Binding var memoryEntityId: String
    @Binding var diskEntityId: String
    @Binding var menuBarEntityId: String
    @Binding var launchAtLogin: Bool
    @Binding var notificationsEnabled: Bool
    
    let service: HomeAssistantService
    let parent: SettingsView
    
    func body(content: Content) -> some View {
        let general = content
            .onChange(of: warningThreshold) { _, n in parent.saveWarningThreshold(n) }
            .onChange(of: criticalThreshold) { _, n in parent.saveCriticalThreshold(n) }
            .onChange(of: appearanceMode) { _, n in parent.saveAppearanceMode(n) }
            .onChange(of: refreshInterval) { _, n in parent.saveRefreshInterval(n) }
        
        let entities = general
            .onChange(of: cpuEntityId) { _, n in UserDefaults.standard.set(n, forKey: "cpuEntityId") }
            .onChange(of: memoryEntityId) { _, n in UserDefaults.standard.set(n, forKey: "memoryEntityId") }
            .onChange(of: diskEntityId) { _, n in UserDefaults.standard.set(n, forKey: "diskEntityId") }
            .onChange(of: menuBarEntityId) { _, n in service.menuBarEntityId = n }
            
        return entities
            .onChange(of: launchAtLogin) { _, n in service.launchAtLogin = n }
            .onChange(of: notificationsEnabled) { _, n in UserDefaults.standard.set(n, forKey: "notificationsEnabled") }
    }
}

// These are no longer needed since we flattened the logic above
/*
struct GeneralSettingsModifier: ViewModifier { ... }
struct EntitySettingsModifier: ViewModifier { ... }
struct SystemSettingsModifier: ViewModifier { ... }
*/

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(.body, design: .monospaced))
        }.font(.caption)
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case auto, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .auto: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 24, height: 24)
                    Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundStyle(color)
                }
                Text(title).font(.caption).fontWeight(.bold).foregroundStyle(.secondary).textCase(.uppercase)
            }.padding(.leading, 4)
            VStack { content }.padding(16).background(.thickMaterial).clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.1), lineWidth: 1))
        }
    }
}

struct ThresholdSlider: View {
    let title: String
    @Binding var value: Double
    let color: Color
    let range: ClosedRange<Double>
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(Int(value))%").monospaced().foregroundStyle(color).fontWeight(.bold)
            }
            Slider(value: $value, in: range, step: 5).tint(color)
        }
    }
}

struct TestResultView: View {
    let result: SettingsView.TestResult
    var body: some View {
        HStack {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 24, height: 24)
                Image(systemName: icon).font(.system(size: 12, weight: .bold)).foregroundStyle(color)
            }
            Text(message).font(.caption).foregroundStyle(color)
        }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(color.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
    private var color: Color { resultCase == .success ? .green : .red }
    private var icon: String { resultCase == .success ? "checkmark" : "xmark" }
    private var resultCase: ResultCase {
        switch result {
        case .success: return .success
        case .failure: return .failure
        }
    }
    private var message: String {
        switch result {
        case .success(let msg): return msg
        case .failure(let msg): return msg
        }
    }
    enum ResultCase { case success, failure }
}

struct EntitySelectorRow: View {
    let icon: String
    let label: String
    @Binding var entityId: String
    let color: Color
    let onSelect: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.caption).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline).fontWeight(.medium)
                Text(entityId.isEmpty ? "Not configured" : entityId).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            HStack(spacing: 8) {
                if !entityId.isEmpty {
                    Button { entityId = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.buttonStyle(.plain)
                }
                Button("Select") { onSelect() }.buttonStyle(.bordered).controlSize(.small)
            }
        }.padding(10).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EntityPickerSheet: View {
    @ObservedObject var service: HomeAssistantService
    let pickerType: SettingsView.EntityPickerType
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    private var title: String {
        switch pickerType {
        case .cpu: return "Select CPU Sensor"
        case .memory: return "Select Memory Sensor"
        case .disk: return "Select Disk Sensor"
        case .menuBar: return "Select Menu Bar Sensor"
        }
    }
    private var filteredSensors: [HAEntityState] {
        let sensors = service.states.filter { $0.entityId.hasPrefix("sensor.") }
        let result = searchText.isEmpty ? sensors.filter { entity in
            let id = entity.entityId.lowercased()
            let name = entity.friendlyName.lowercased()
            switch pickerType {
            case .cpu: return id.contains("cpu") || id.contains("processor") || name.contains("cpu") || name.contains("processor")
            case .memory: return id.contains("memory") || id.contains("ram") || id.contains("geheugen") || name.contains("memory") || name.contains("ram") || name.contains("geheugen")
            case .disk: return id.contains("disk") || id.contains("storage") || id.contains("schijf") || name.contains("disk") || name.contains("storage") || name.contains("schijf")
            case .menuBar: return true // Show all sensors for menu bar selection
            }
        } : sensors.filter { $0.entityId.localizedCaseInsensitiveContains(searchText) || $0.friendlyName.localizedCaseInsensitiveContains(searchText) }
        return result.sorted { $0.friendlyName < $1.friendlyName }
    }
    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            Divider()
            list
            footer
        }.frame(width: 400, height: 450).background(.regularMaterial)
    }
    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: "magnifyingglass").font(.caption).foregroundStyle(.blue)
            }
            Text(title).font(.headline)
            Spacer()
            Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.secondary) }.buttonStyle(.plain)
        }.padding().background(.ultraThinMaterial)
    }
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search sensors...", text: $searchText).textFieldStyle(.plain)
            if !searchText.isEmpty { Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.buttonStyle(.plain) }
        }.padding(12).background(.thickMaterial).clipShape(RoundedRectangle(cornerRadius: 10)).padding()
    }
    private var list: some View {
        Group {
            if filteredSensors.isEmpty {
                ContentUnavailableView { Label("No Sensors Found", systemImage: "magnifyingglass") } description: { Text("Try searching for a different term") }
            } else {
                ScrollView { LazyVStack(spacing: 1) { ForEach(filteredSensors) { s in SensorPickerRow(sensor: s) { onSelect(s.entityId) } } }.padding(.vertical, 4) }
            }
        }
    }
    private var footer: some View {
        HStack {
            Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
            Text("Tip: Search for your sensor name in any language").font(.caption).foregroundStyle(.secondary)
        }.padding().background(.ultraThinMaterial)
    }
}

struct SensorPickerRow: View {
    let sensor: HAEntityState
    let onSelect: () -> Void
    @State private var isHovering = false
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.1)).frame(width: 28, height: 28)
                    Image(systemName: "sensor.fill").font(.caption).foregroundStyle(.blue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(sensor.friendlyName).font(.body).foregroundStyle(.primary)
                    Text(sensor.entityId).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Text(sensor.displayState).font(.system(.caption, design: .rounded, weight: .bold)).padding(.horizontal, 8).padding(.vertical, 4).background(Color.blue.opacity(0.15)).foregroundStyle(.blue).clipShape(Capsule())
            }.padding(.horizontal, 12).padding(.vertical, 8).background(isHovering ? Color.accentColor.opacity(0.1) : Color.clear).contentShape(Rectangle())
        }.buttonStyle(.plain).onHover { hovering in isHovering = hovering }
    }
}

struct ThresholdPreview: View {
    let label: String
    let range: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 20, height: 20)
                Circle().fill(color).frame(width: 8, height: 8)
            }
            Text(label).font(.caption2).fontWeight(.bold).foregroundStyle(color)
            Text(range).font(.caption2).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity)
    }
}

#Preview {
    SettingsView(service: HomeAssistantService())
}
