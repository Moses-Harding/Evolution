//
//  ConfigurationView.swift
//  Evolution
//
//  Created by Claude on 11/10/25.
//

import SwiftUI

struct ConfigurationView: View {
    @State private var config = GameConfiguration.default
    @State private var showingPresets = false

    var onStart: (GameConfiguration) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Population Settings")) {
                    Stepper("Initial Population: \(config.initialPopulation)",
                           value: $config.initialPopulation,
                           in: 1...50)

                    Stepper("Initial Speed: \(config.initialSpeed)",
                           value: $config.initialSpeed,
                           in: config.minSpeed...config.maxSpeed)
                }

                Section(header: Text("Evolution Parameters")) {
                    HStack {
                        Text("Speed Range")
                        Spacer()
                        Text("\(config.minSpeed) - \(config.maxSpeed)")
                            .foregroundColor(.secondary)
                    }

                    Stepper("Min Speed: \(config.minSpeed)",
                           value: $config.minSpeed,
                           in: 1...config.maxSpeed)

                    Stepper("Max Speed: \(config.maxSpeed)",
                           value: $config.maxSpeed,
                           in: config.minSpeed...100)

                    Stepper("Mutation Range: ±\(config.mutationRange)",
                           value: $config.mutationRange,
                           in: 0...10)

                    Text("Speed mutates by ±0 to ±\(config.mutationRange)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Food Settings")) {
                    Stepper("Food Per Day: \(config.foodPerDay)",
                           value: $config.foodPerDay,
                           in: 1...20)

                    HStack {
                        Text("Food Size")
                        Slider(value: $config.foodSize, in: 4...16, step: 1)
                        Text("\(Int(config.foodSize))")
                            .frame(width: 30)
                    }
                }

                Section(header: Text("Time Settings (seconds)")) {
                    HStack {
                        Text("Day Duration")
                        Slider(value: $config.dayCycleDuration, in: 10...120, step: 5)
                        Text("\(Int(config.dayCycleDuration))s")
                            .frame(width: 40)
                    }

                    HStack {
                        Text("Movement Phase")
                        Slider(value: $config.movementPhaseDuration,
                              in: 5...config.dayCycleDuration,
                              step: 5)
                        Text("\(Int(config.movementPhaseDuration))s")
                            .frame(width: 40)
                    }

                    Text("Evaluation happens in final \(Int(config.dayCycleDuration - config.movementPhaseDuration)) seconds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Reproduction Settings")) {
                    HStack {
                        Text("Reproduction Chance")
                        Slider(value: $config.reproductionProbability, in: 0...1, step: 0.05)
                        Text("\(Int(config.reproductionProbability * 100))%")
                            .frame(width: 50)
                    }

                    HStack {
                        Text("Spawn Distance")
                        Slider(value: $config.spawnDistance, in: 10...100, step: 5)
                        Text("\(Int(config.spawnDistance))")
                            .frame(width: 40)
                    }

                    Text("How far offspring spawn from parent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Display Settings")) {
                    HStack {
                        Text("Organism Size")
                        Slider(value: $config.organismRadius, in: 5...20, step: 1)
                        Text("\(Int(config.organismRadius))")
                            .frame(width: 30)
                    }
                }

                Section {
                    Button(action: { showingPresets = true }) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Load Preset")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }

                    Button(action: { config = GameConfiguration.default }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Default")
                        }
                    }
                }

                Section {
                    Button(action: { onStart(config) }) {
                        HStack {
                            Spacer()
                            Text("Start Simulation")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Simulation Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPresets) {
                PresetSelectionView(config: $config, isPresented: $showingPresets)
            }
        }
    }
}

struct PresetSelectionView: View {
    @Binding var config: GameConfiguration
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                PresetRow(
                    name: "Default",
                    description: "Balanced settings for standard gameplay",
                    icon: "circle.fill",
                    color: .blue
                ) {
                    config = .default
                    isPresented = false
                }

                PresetRow(
                    name: "Fast Evolution",
                    description: "More food, faster cycles, higher reproduction",
                    icon: "hare.fill",
                    color: .green
                ) {
                    config = .fastEvolution
                    isPresented = false
                }

                PresetRow(
                    name: "Slow Evolution",
                    description: "Limited food, slower pace, lower reproduction",
                    icon: "tortoise.fill",
                    color: .orange
                ) {
                    config = .slowEvolution
                    isPresented = false
                }

                PresetRow(
                    name: "High Mutation",
                    description: "Larger speed mutations, faster evolution",
                    icon: "waveform.path",
                    color: .purple
                ) {
                    config = .highMutation
                    isPresented = false
                }

                PresetRow(
                    name: "Extreme Speed",
                    description: "Wide speed range (1-50) with high mutation",
                    icon: "bolt.fill",
                    color: .red
                ) {
                    config = .extremeSpeed
                    isPresented = false
                }
            }
            .navigationTitle("Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct PresetRow: View {
    let name: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    ConfigurationView { config in
        print("Starting with config: \(config)")
    }
}
