//
//  EvolutionApp.swift
//  Evolution
//
//  Created by Moses Harding on 11/9/25.
//

import SwiftUI

@main
struct EvolutionApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                print("Evolution: App entered background - continuing simulation")
            case .active:
                print("Evolution: App became active")
            case .inactive:
                print("Evolution: App became inactive")
            @unknown default:
                break
            }
        }
    }
}
