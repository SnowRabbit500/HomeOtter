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
        // Menu Bar Extra (the main interface)
        MenuBarExtra {
            ContentView(service: service, openSettings: { openWindow(id: "settings") }, openEntityBrowser: { openWindow(id: "entities") })
                .onAppear {
                    applyStoredAppearance()
                }
        } label: {
            MenuBarLabel(service: service)
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

// MARK: - Menu Bar Label
struct MenuBarLabel: View {
    @ObservedObject var service: HomeAssistantService
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "house.fill")
            
            if !service.menuBarEntityId.isEmpty, let state = menuBarState {
                Text(state.displayState)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            
            Text(statusEmoji)
                .font(.system(size: 10))
        }
    }
    
    private var menuBarState: HAEntityState? {
        service.states.first { $0.entityId == service.menuBarEntityId }
    }
    
    private var isUpdateAvailable: Bool {
        service.states.first { $0.entityId == "update.home_assistant_core_update" }?.state == "on"
    }
    
    private var statusEmoji: String {
        // Update available takes priority - show blue
        if isUpdateAvailable {
            return "🔵"
        }
        
        // Connection error - show red
        if case .error = service.connectionStatus {
            return "🔴"
        }
        
        // System health status
        switch service.overallHealth {
        case .healthy: return "🟢"
        case .warning: return "🟠"
        case .critical: return "🔴"
        case .unknown: return "⚪"
        }
    }
}

