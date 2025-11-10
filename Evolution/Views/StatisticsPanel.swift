//
//  StatisticsPanel.swift
//  Evolution
//
//  Created by Claude on 11/10/25.
//

import SwiftUI
import Charts

struct StatisticsPanel: View {
    let statistics: GameStatistics

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Live Metrics
                LiveMetricsView(statistics: statistics)

                Divider()
                    .background(Color.white.opacity(0.3))

                // Population Chart
                PopulationChartView(snapshots: statistics.dailySnapshots)

                Divider()
                    .background(Color.white.opacity(0.3))

                // Speed Chart
                SpeedChartView(snapshots: statistics.dailySnapshots)

                Divider()
                    .background(Color.white.opacity(0.3))

                // Speed Distribution
                SpeedDistributionView(organisms: statistics.organisms)

                Divider()
                    .background(Color.white.opacity(0.3))

                // Organism List
                OrganismListView(organisms: statistics.organisms)
            }
            .padding()
        }
    }
}

struct LiveMetricsView: View {
    let statistics: GameStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Live Metrics")
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                MetricCard(title: "Day", value: "\(statistics.currentDay)")
                MetricCard(title: "Population", value: "\(statistics.population)")
            }

            HStack {
                MetricCard(title: "Avg Speed", value: String(format: "%.1f", statistics.averageSpeed))
                MetricCard(title: "Min/Max", value: "\(statistics.minSpeed)/\(statistics.maxSpeed)")
            }

            HStack {
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
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

struct PopulationChartView: View {
    let snapshots: [DailySnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Population Over Time")
                .font(.headline)
                .foregroundColor(.white)

            if snapshots.count > 1 {
                Chart(snapshots) { snapshot in
                    LineMark(
                        x: .value("Day", snapshot.day),
                        y: .value("Population", snapshot.population)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 150)
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
                    .frame(height: 150)
            }
        }
    }
}

struct SpeedChartView: View {
    let snapshots: [DailySnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Average Speed Over Time")
                .font(.headline)
                .foregroundColor(.white)

            if snapshots.count > 1 {
                Chart(snapshots) { snapshot in
                    LineMark(
                        x: .value("Day", snapshot.day),
                        y: .value("Speed", snapshot.averageSpeed)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 150)
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
                    .frame(height: 150)
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Speed Distribution")
                .font(.headline)
                .foregroundColor(.white)

            if !organisms.isEmpty {
                Chart(speedBuckets) { bucket in
                    BarMark(
                        x: .value("Speed", bucket.speed),
                        y: .value("Count", bucket.count)
                    )
                    .foregroundStyle(.purple)
                }
                .frame(height: 150)
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
                    .frame(height: 150)
            }
        }
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
