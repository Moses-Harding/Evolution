//
//  StatisticsPanel.swift
//  Evolution
//
//  Created by Claude on 11/10/25.
//

import SwiftUI
import Charts

struct StatisticsPanel: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Live Metrics - larger and more prominent
                LiveMetricsView(statistics: viewModel.statistics)

                Divider()
                    .background(Color.white.opacity(0.3))

                // Species Panel - show active species
                if !viewModel.statistics.activeSpecies.isEmpty {
                    SpeciesPanelView(species: viewModel.statistics.activeSpecies)

                    Divider()
                        .background(Color.white.opacity(0.3))
                }

                // Charts in tabs for better space usage
                TabView {
                    VStack {
                        PopulationChartView(snapshots: viewModel.statistics.dailySnapshots)
                        SpeedChartView(snapshots: viewModel.statistics.dailySnapshots)
                    }
                    .tag(0)

                    SpeedDistributionView(organisms: viewModel.statistics.organisms)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 400)

                Divider()
                    .background(Color.white.opacity(0.3))

                // Organism List
                OrganismListView(organisms: viewModel.statistics.organisms)
            }
            .padding()
        }
    }
}

struct LiveMetricsView: View {
    let statistics: GameStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EVOLUTION METRICS")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.cyan)

            HStack(spacing: 12) {
                MetricCard(title: "Day", value: "\(statistics.currentDay)")
                MetricCard(title: "Population", value: "\(statistics.population)")
            }

            HStack(spacing: 12) {
                MetricCard(title: "Avg Speed", value: String(format: "%.1f", statistics.averageSpeed))
                MetricCard(title: "Range", value: "\(statistics.minSpeed)-\(statistics.maxSpeed)")
            }

            HStack(spacing: 12) {
                MetricCard(title: "Births", value: "\(statistics.births)", color: .green)
                MetricCard(title: "Deaths", value: "\(statistics.deaths)", color: .red)
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    var color: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
}

struct PopulationChartView: View {
    let snapshots: [DailySnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Population Over Time")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            if snapshots.count > 1 {
                Chart(snapshots) { snapshot in
                    LineMark(
                        x: .value("Day", snapshot.day),
                        y: .value("Population", snapshot.population)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(position: .bottom) {
                        AxisValueLabel()
                            .foregroundStyle(.white)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisValueLabel()
                            .foregroundStyle(.white)
                    }
                }
            } else {
                Text("Collecting data...")
                    .foregroundColor(.gray)
                    .frame(height: 140)
            }
        }
    }
}

struct SpeedChartView: View {
    let snapshots: [DailySnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Average Speed Over Time")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            if snapshots.count > 1 {
                Chart(snapshots) { snapshot in
                    LineMark(
                        x: .value("Day", snapshot.day),
                        y: .value("Speed", snapshot.averageSpeed)
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(position: .bottom) {
                        AxisValueLabel()
                            .foregroundStyle(.white)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisValueLabel()
                            .foregroundStyle(.white)
                    }
                }
            } else {
                Text("Collecting data...")
                    .foregroundColor(.gray)
                    .frame(height: 140)
            }
        }
    }
}

struct SpeedDistributionView: View {
    let organisms: [OrganismInfo]

    private var speedBuckets: [SpeedBucket] {
        var buckets: [Int: Int] = [:]
        for organism in organisms {
            let bucket = (organism.speed / 5) * 5  // Group by 5s
            buckets[bucket, default: 0] += 1
        }
        return buckets.map { SpeedBucket(speed: $0.key, count: $0.value) }
            .sorted { $0.speed < $1.speed }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Speed Distribution")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            if !organisms.isEmpty {
                Chart(speedBuckets) { bucket in
                    BarMark(
                        x: .value("Speed", bucket.speed),
                        y: .value("Count", bucket.count)
                    )
                    .foregroundStyle(.purple)
                }
                .frame(height: 300)
                .chartXAxis {
                    AxisMarks(position: .bottom) {
                        AxisValueLabel()
                            .foregroundStyle(.white)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisValueLabel()
                            .foregroundStyle(.white)
                    }
                }
            } else {
                Text("No organisms")
                    .foregroundColor(.gray)
                    .frame(height: 300)
            }
        }
        .padding()
    }
}

struct SpeedBucket: Identifiable {
    let id = UUID()
    let speed: Int
    let count: Int
}

struct OrganismListView: View {
    let organisms: [OrganismInfo]

    private var sortedOrganisms: [OrganismInfo] {
        organisms.sorted { $0.speed > $1.speed }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Organisms (\(organisms.count))")
                .font(.headline)
                .foregroundColor(.white)

            if organisms.isEmpty {
                Text("No organisms alive")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(sortedOrganisms) { organism in
                            OrganismRow(organism: organism)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }
}

struct SpeciesPanelView: View {
    let species: [SpeciesInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Species (\(species.count))")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.cyan)

            if species.isEmpty {
                Text("No species alive")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                VStack(spacing: 6) {
                    ForEach(species) { speciesData in
                        SpeciesRow(species: speciesData)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct SpeciesRow: View {
    let species: SpeciesInfo

    var body: some View {
        HStack(spacing: 10) {
            // Species color indicator
            Circle()
                .fill(Color(red: species.color.red, green: species.color.green, blue: species.color.blue))
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )

            // Species name
            Text(species.name)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 120, alignment: .leading)

            Spacer()

            // Population
            Text("\(species.population)")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.green)
                .frame(width: 30, alignment: .trailing)

            // Average speed
            Text("Spd: \(Int(species.averageSpeed))")
                .font(.caption2)
                .foregroundColor(.orange)
                .frame(width: 50, alignment: .leading)

            // Age at founding
            Text("Day \(species.foundedOnDay)")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(red: species.color.red, green: species.color.green, blue: species.color.blue).opacity(0.3), lineWidth: 1)
        )
    }
}

struct OrganismRow: View {
    let organism: OrganismInfo

    private var idPrefix: String {
        String(organism.id.uuidString.prefix(8))
    }

    var body: some View {
        HStack {
            Circle()
                .fill(organism.hasFoodToday ? Color.yellow : Color.gray)
                .frame(width: 8, height: 8)

            Text(idPrefix)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)

            Spacer()

            Text("Speed: \(organism.speed)")
                .font(.caption)
                .foregroundColor(.white)

            Text("Gen: \(organism.generation)")
                .font(.caption)
                .foregroundColor(.cyan)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(4)
    }
}
