//
//  EntityBrowserView.swift
//  HomeOtter
//
//  Created by Stefan Konijnenberg on 09/01/2026.
//

import SwiftUI

struct EntityBrowserView: View {
    @ObservedObject var service: HomeAssistantService
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedDomain: String?
    
    private var filteredStates: [HAEntityState] {
        var states = service.states
        
        if let domain = selectedDomain {
            states = states.filter { $0.entityId.hasPrefix("\(domain).") }
        }
        
        if !searchText.isEmpty {
            states = states.filter { 
                $0.entityId.localizedCaseInsensitiveContains(searchText) ||
                $0.friendlyName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return states.sorted { $0.friendlyName < $1.friendlyName }
    }
    
    private var domains: [String] {
        Array(Set(service.states.map { $0.entityId.components(separatedBy: ".").first ?? "" }))
            .sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "square.grid.2x2")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Browse Entities")
                    .font(.headline)
                Spacer()
                Text("\(filteredStates.count) entities")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Domain Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    DomainPill(name: "All", isSelected: selectedDomain == nil) {
                        selectedDomain = nil
                    }
                    
                    ForEach(domains, id: \.self) { domain in
                        DomainPill(name: domain, isSelected: selectedDomain == domain) {
                            selectedDomain = domain
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(.regularMaterial)
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search entities...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(10)
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Entity List
            if filteredStates.isEmpty {
                ContentUnavailableView {
                    Label("No Entities Found", systemImage: "magnifyingglass")
                } description: {
                    Text("Try adjusting your search or filter")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredStates) { entity in
                            EntityBrowserRow(entity: entity, service: service)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 450, height: 550)
        .background(.thickMaterial)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.9))
    }
}

struct DomainPill: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct EntityBrowserRow: View {
    let entity: HAEntityState
    @ObservedObject var service: HomeAssistantService
    
    @State private var isHovering = false
    
    private var isInDashboard: Bool {
        service.isInDashboard(entityId: entity.entityId)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: entity.icon)
                .font(.title3)
                .foregroundStyle(stateColor)
                .frame(width: 28)
            
            // Entity Info
            VStack(alignment: .leading, spacing: 2) {
                Text(entity.friendlyName)
                    .font(.system(.body, weight: .medium))
                    .lineLimit(1)
                
                Text(entity.entityId)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // State
            Text(entity.displayState)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(stateColor.opacity(0.15))
                .foregroundStyle(stateColor)
                .clipShape(Capsule())
            
            // Add/Remove Button
            Button {
                if isInDashboard {
                    service.removeFromDashboard(entityId: entity.entityId)
                } else {
                    service.addToDashboard(entityId: entity.entityId)
                }
            } label: {
                Image(systemName: isInDashboard ? "star.fill" : "star")
                    .foregroundStyle(isInDashboard ? .yellow : .secondary)
            }
            .buttonStyle(.borderless)
            .help(isInDashboard ? "Remove from dashboard" : "Add to dashboard")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
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

#Preview {
    EntityBrowserView(service: HomeAssistantService())
}
