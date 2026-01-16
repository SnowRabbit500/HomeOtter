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
    @State private var menuBarEntityIds: [String] = []
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
        .frame(width: 400, height: 580)
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
            menuBarEntityIds: $menuBarEntityIds,
            launchAtLogin: $launchAtLogin,
            notificationsEnabled: $notificationsEnabled,
            service: service,
            parent: self
        ))
        .sheet(item: $showEntityPicker, content: entityPickerSheet)
    }
    
    // MARK: - Subviews
    
    // iStats-style dark gradient background
    private var viewBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.13, blue: 0.20),
                Color(red: 0.08, green: 0.09, blue: 0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var header: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("HomeOtter")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                    )
                Text("Settings")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(2)
                    .textCase(.uppercase)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.3))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.03))
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                connectionSection
                menuBarSection
                systemHealthSection
                alertThresholdsSection
                appearanceSection
                infoSection
                aboutSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private var menuBarSection: some View {
        SettingsSection(title: "Menu Bar Display", icon: "menubar.rectangle", color: .white.opacity(0.6), isExpandedByDefault: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Show sensor values in your menu bar")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("\(menuBarEntityIds.count)/\(HomeAssistantService.maxMenuBarSensors)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                }
                
                // List of current menu bar sensors
                if !menuBarEntityIds.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(Array(menuBarEntityIds.enumerated()), id: \.offset) { index, entityId in
                            MenuBarSensorRow(
                                index: index,
                                entityId: entityId,
                                service: service,
                                onRemove: {
                                    menuBarEntityIds.removeAll { $0 == entityId }
                                    service.menuBarEntityIds = menuBarEntityIds
                                },
                                onMoveUp: index > 0 ? {
                                    menuBarEntityIds.swapAt(index, index - 1)
                                    service.menuBarEntityIds = menuBarEntityIds
                                } : nil,
                                onMoveDown: index < menuBarEntityIds.count - 1 ? {
                                    menuBarEntityIds.swapAt(index, index + 1)
                                    service.menuBarEntityIds = menuBarEntityIds
                                } : nil
                            )
                        }
                    }
                }
                
                // Add button
                if menuBarEntityIds.count < HomeAssistantService.maxMenuBarSensors {
                    Button {
                        showEntityPicker = .menuBar
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text("Add Sensor")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.cyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.cyan.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // Connection section: open if not connected, closed if connected
    private var connectionSection: some View {
        SettingsSection(title: "Connection", icon: "network", color: .white.opacity(0.6), isExpandedByDefault: !service.isConfigured || service.connectionStatus != .connected) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Home Assistant URL")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    TextField("https://your-ha-instance.ui.nabu.casa", text: $urlText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Long-Lived Access Token")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    HStack(spacing: 8) {
                        if showToken {
                            TextField("Paste your token here", text: $tokenText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white)
                        } else {
                            SecureField("Paste your token here", text: $tokenText)
                                .textFieldStyle(.plain)
                                .foregroundStyle(.white)
                        }
                        Button { showToken.toggle() } label: {
                            Image(systemName: showToken ? "eye.slash" : "eye")
                                .foregroundStyle(.white.opacity(0.4))
                        }.buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                HStack(spacing: 12) {
                    Button(action: testConnection) {
                        HStack(spacing: 6) {
                            if isTesting { 
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.cyan)
                            } else { 
                                Image(systemName: "antenna.radiowaves.left.and.right")
                            }
                            Text("Test")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }.buttonStyle(.plain)
                    
                    Button { saveSettings() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Save & Close")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.cyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.cyan.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }.buttonStyle(.plain)
                }
                if let result = testResult { TestResultView(result: result) }
            }
        }
    }
    
    private var systemHealthSection: some View {
        SettingsSection(title: "System Health", icon: "heart.text.clipboard", color: .white.opacity(0.6), isExpandedByDefault: false) {
            VStack(alignment: .leading, spacing: 8) {
                EntitySelectorRow(icon: "cpu", label: "CPU", entityId: $cpuEntityId, color: .cyan) { showEntityPicker = .cpu }
                EntitySelectorRow(icon: "memorychip", label: "Memory", entityId: $memoryEntityId, color: .cyan) { showEntityPicker = .memory }
                EntitySelectorRow(icon: "internaldrive", label: "Disk", entityId: $diskEntityId, color: .cyan) { showEntityPicker = .disk }
            }
        }
    }
    
    private var alertThresholdsSection: some View {
        SettingsSection(title: "Thresholds", icon: "bell.badge", color: .white.opacity(0.6), isExpandedByDefault: false) {
            VStack(alignment: .leading, spacing: 16) {
                ThresholdSlider(title: "Warning", value: $warningThreshold, color: .orange, range: 0...99)
                ThresholdSlider(title: "Critical", value: $criticalThreshold, color: .red, range: 0...99)
                HStack(spacing: 12) {
                    ThresholdPreview(label: "Healthy", range: "0-\(Int(warningThreshold))%", color: .green)
                    ThresholdPreview(label: "Warning", range: "\(Int(warningThreshold))-\(Int(criticalThreshold))%", color: .orange)
                    ThresholdPreview(label: "Critical", range: ">\(Int(criticalThreshold))%", color: .red)
                }
            }
        }
    }
    
    private var appearanceSection: some View {
        SettingsSection(title: "Preferences", icon: "paintpalette", color: .white.opacity(0.6), isExpandedByDefault: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("THEME")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(1)
                    Picker("Theme", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.cyan)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                HStack {
                    Text("Launch at login")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Toggle("", isOn: $launchAtLogin)
                        .toggleStyle(.switch)
                        .tint(.cyan)
                }
                
                HStack {
                    Text("Notifications")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Toggle("", isOn: $notificationsEnabled)
                        .toggleStyle(.switch)
                        .tint(.cyan)
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Refresh Interval")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text("\(Int(refreshInterval))s")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.cyan)
                    }
                    Slider(value: $refreshInterval, in: 10...120, step: 10)
                        .tint(.cyan)
                }
            }
        }
    }
    
    private var infoSection: some View {
        SettingsSection(title: "Home Assistant", icon: "house.fill", color: .white.opacity(0.6), isExpandedByDefault: false) {
            VStack(alignment: .leading, spacing: 8) {
                if let config = service.config {
                    InfoRow(label: "Location", value: config.locationName)
                    InfoRow(label: "Version", value: config.version)
                    InfoRow(label: "State", value: config.state)
                    InfoRow(label: "Timezone", value: config.timeZone)
                } else {
                    Text("Connect to see info")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
    }
    
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle", color: .white.opacity(0.6), isExpandedByDefault: false) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HomeOtter")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("A menu bar companion for Home Assistant")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                Text("v1.0")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
    
    // MARK: - Helpers
    
    func entityPickerSheet(for pickerType: EntityPickerType) -> some View {
        EntityPickerSheet(
            service: service,
            pickerType: pickerType,
            excludedEntityIds: pickerType == .menuBar ? menuBarEntityIds : [],
            onSelect: { entityId in
                switch pickerType {
                case .cpu: cpuEntityId = entityId
                case .memory: memoryEntityId = entityId
                case .disk: diskEntityId = entityId
                case .menuBar:
                    if !menuBarEntityIds.contains(entityId) && menuBarEntityIds.count < HomeAssistantService.maxMenuBarSensors {
                        menuBarEntityIds.append(entityId)
                        service.menuBarEntityIds = menuBarEntityIds
                    }
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
        menuBarEntityIds = service.menuBarEntityIds
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
    @Binding var menuBarEntityIds: [String]
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
            .onChange(of: menuBarEntityIds) { _, n in service.menuBarEntityIds = n }
            
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
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
        }
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

// Collapsible iStats-style section
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    var isExpandedByDefault: Bool = true
    @ViewBuilder var content: Content
    
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Clickable header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(title.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .tracking(1.2)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Content card (collapsible)
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) { content }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .onAppear {
            isExpanded = isExpandedByDefault
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
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Text("\(Int(value))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }
            Slider(value: $value, in: range, step: 5)
                .tint(color)
        }
    }
}

struct TestResultView: View {
    let result: SettingsView.TestResult
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    private var color: Color { resultCase == .success ? .green : .red }
    private var icon: String { resultCase == .success ? "checkmark.circle.fill" : "xmark.circle.fill" }
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
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                Text(entityId.isEmpty ? "Not configured" : entityId)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
            }
            Spacer()
            HStack(spacing: 8) {
                if !entityId.isEmpty {
                    Button { entityId = "" } label: { 
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.2)) 
                    }.buttonStyle(.plain)
                }
                Button { onSelect() } label: {
                    Text("Select")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }.buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct EntityPickerSheet: View {
    @ObservedObject var service: HomeAssistantService
    let pickerType: SettingsView.EntityPickerType
    var excludedEntityIds: [String] = []
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var title: String {
        switch pickerType {
        case .cpu: return "Select CPU Sensor"
        case .memory: return "Select Memory Sensor"
        case .disk: return "Select Disk Sensor"
        case .menuBar: return "Add Menu Bar Sensor"
        }
    }
    
    private var accentColor: Color {
        .cyan // Uniform accent color
    }
    
    private var filteredSensors: [HAEntityState] {
        let sensors = service.states.filter { $0.entityId.hasPrefix("sensor.") && !excludedEntityIds.contains($0.entityId) }
        let result = searchText.isEmpty ? sensors.filter { entity in
            let id = entity.entityId.lowercased()
            let name = entity.friendlyName.lowercased()
            switch pickerType {
            case .cpu: return id.contains("cpu") || id.contains("processor") || name.contains("cpu") || name.contains("processor")
            case .memory: return id.contains("memory") || id.contains("ram") || id.contains("geheugen") || name.contains("memory") || name.contains("ram") || name.contains("geheugen")
            case .disk: return id.contains("disk") || id.contains("storage") || id.contains("schijf") || name.contains("disk") || name.contains("storage") || name.contains("schijf")
            case .menuBar: return true
            }
        } : sensors.filter { $0.entityId.localizedCaseInsensitiveContains(searchText) || $0.friendlyName.localizedCaseInsensitiveContains(searchText) }
        return result.sorted { $0.friendlyName < $1.friendlyName }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            list
        }
        .frame(width: 400, height: 500)
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.13, blue: 0.20), Color(red: 0.08, green: 0.09, blue: 0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.3))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
    }
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))
            TextField("Search sensors...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(.white)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.3))
                }.buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
    }
    
    private var list: some View {
        Group {
            if filteredSensors.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("No sensors found")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredSensors) { sensor in
                            SensorPickerRow(sensor: sensor, accentColor: accentColor) {
                                onSelect(sensor.entityId)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
    }
}

struct SensorPickerRow: View {
    let sensor: HAEntityState
    var accentColor: Color = .cyan
    let onSelect: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(sensor.friendlyName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(sensor.entityId)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
                Spacer()
                Text(sensor.displayState)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isHovering ? accentColor.opacity(0.15) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

struct ThresholdPreview: View {
    let label: String
    let range: String
    let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .shadow(color: color.opacity(0.5), radius: 4)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            Text(range)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Menu Bar Sensor Row
struct MenuBarSensorRow: View {
    let index: Int
    let entityId: String
    @ObservedObject var service: HomeAssistantService
    let onRemove: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    private var entity: HAEntityState? {
        service.states.first { $0.entityId == entityId }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Order number - cyan accent (uniform with system health)
            Text("\(index + 1)")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Color.cyan))
            
            // Sensor info
            VStack(alignment: .leading, spacing: 2) {
                Text(entity?.friendlyName ?? entityId)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let state = entity {
                        Text(state.displayState)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.cyan)
                    } else {
                        Text(entityId)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.3))
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    if let moveUp = onMoveUp {
                        Button { moveUp() } label: {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                    }
                    if let moveDown = onMoveDown {
                        Button { moveDown() } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Button { onRemove() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.2))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SettingsView(service: HomeAssistantService())
}
