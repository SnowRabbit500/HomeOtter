//
//  HomeOtterApp.swift
//  HomeOtter
//
//  Created by Stefan Konijnenberg on 09/01/2026.
//

import SwiftUI
import AppKit

@main
struct HomeOtterApp: App {
    @StateObject private var service = HomeAssistantService()
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Menu Bar Extra
        MenuBarExtra {
            ContentView(service: service, openSettings: { openWindow(id: "settings") }, openEntityBrowser: { openWindow(id: "entities") })
                .onAppear {
                    applyStoredAppearance()
                }
        } label: {
            MenuBarView(service: service)
        }
        .menuBarExtraStyle(.window)
        
        // Settings Window
        Window("HomeOtter Settings", id: "settings") {
            SettingsView(service: service)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        
        // Entity Browser Window
        Window("Browse Entities", id: "entities") {
            EntityBrowserView(service: service)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// MARK: - Apply Stored Appearance
func applyStoredAppearance() {
    if let savedMode = UserDefaults.standard.string(forKey: "appearanceMode") {
        DispatchQueue.main.async {
            switch savedMode {
            case "light":
                NSApp.appearance = NSAppearance(named: .aqua)
            case "dark":
                NSApp.appearance = NSAppearance(named: .darkAqua)
            default:
                NSApp.appearance = nil
            }
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        applyStoredAppearance()
    }
}

// MARK: - Menu Bar View (simplified)
struct MenuBarView: View {
    @ObservedObject var service: HomeAssistantService
    
    var body: some View {
        // HStack with Image + Text for menu bar
        HStack(spacing: 4) {
            Image(systemName: "house.fill")
            Text(menuBarText)
        }
    }
    
    private var menuBarText: String {
        var parts: [String] = []
        
        // Status emoji
        parts.append(statusEmoji)
        
        // Sensor values
        let sensorValues = service.menuBarSensorIds.compactMap { id in
            service.states.first(where: { $0.entityId == id })?.displayState
        }
        if !sensorValues.isEmpty {
            parts.append(sensorValues.joined(separator: " │ "))
        }
        
        return parts.joined(separator: " ")
    }
    
    private var statusEmoji: String {
        if service.states.first(where: { $0.entityId == "update.home_assistant_core_update" })?.state == "on" {
            return "🔵"
        }
        if case .error = service.connectionStatus {
            return "🔴"
        }
        switch service.overallHealth {
        case .healthy: return "🟢"
        case .warning: return "🟠"
        case .critical: return "🔴"
        case .unknown: return "⚪"
        }
    }
    
}

