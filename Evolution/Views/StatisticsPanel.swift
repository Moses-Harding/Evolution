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
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Live Metrics - Hero section
                LiveMetricsView(statistics: viewModel.statistics)

                // Species Panel
                if !viewModel.statistics.activeSpecies.isEmpty {
                    SpeciesPanelView(species: viewModel.statistics.activeSpecies)
                }

                // Milestones Panel
                MilestonesView(milestones: viewModel.statistics.milestones)

                // Charts Section
                ChartsSection(snapshots: viewModel.statistics.dailySnapshots, organisms: viewModel.statistics.organisms)

                // Organism List
                OrganismListView(organisms: viewModel.statistics.organisms)
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.gradientDark)
    }
}

// MARK: - Live Metrics

struct LiveMetricsView: View {
    let statistics: GameStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header with gradient
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("EVOLUTION")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .tracking(2)

                    Text("Day \(statistics.currentDay)")
                        .font(DesignSystem.Typography.largeTitle)
                        .foregroundColor(DesignSystem.Colors.primaryCyan)
                }

                Spacer()

                // Population pulse indicator
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primaryGreen.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .pulseEffect(color: DesignSystem.Colors.primaryGreen)

                    VStack(spacing: 2) {
                        Image(systemName: "person.3.fill")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.primaryGreen)
                        Text("\(statistics.population)")
                            .font(DesignSystem.Typography.monoSmall)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
            }

            // Key metrics grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
                ElegantMetricCard(
                    icon: "bolt.fill",
                    title: "Avg Speed",
                    value: String(format: "%.1f", statistics.averageSpeed),
                    gradient: LinearGradient(colors: [DesignSystem.Colors.accentOrange, DesignSystem.Colors.accentYellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

                ElegantMetricCard(
                    icon: "arrow.up.arrow.down",
                    title: "Speed Range",
                    value: "\(statistics.minSpeed)-\(statistics.maxSpeed)",
                    gradient: LinearGradient(colors: [DesignSystem.Colors.primaryPurple, DesignSystem.Colors.primaryCyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

                ElegantMetricCard(
                    icon: "plus.circle.fill",
                    title: "Births",
                    value: "\(statistics.births)",
                    gradient: LinearGradient(colors: [DesignSystem.Colors.statusSuccess, DesignSystem.Colors.primaryGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

                ElegantMetricCard(
                    icon: "minus.circle.fill",
                    title: "Deaths",
                    value: "\(statistics.totalDeaths)",
                    gradient: LinearGradient(colors: [DesignSystem.Colors.statusError, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }

            // Death causes breakdown
            if statistics.totalDeaths > 0 {
                DeathCausesView(statistics: statistics)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .cardStyle(padding: DesignSystem.Spacing.lg, cornerRadius: DesignSystem.CornerRadius.xl)
    }
}

struct ElegantMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(gradient)

                Spacer()
            }

            Text(value)
                .font(DesignSystem.Typography.monoLarge)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundLight.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(gradient.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct DeathCausesView: View {
    let statistics: GameStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("DEATH ANALYSIS")
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .tracking(1.5)

            HStack(spacing: DesignSystem.Spacing.xs) {
                if statistics.deathsByStarvation > 0 {
                    ElegantDeathChip(icon: "🍽️", count: statistics.deathsByStarvation, label: "Starve", color: .red)
                }
                if statistics.deathsByOldAge > 0 {
                    ElegantDeathChip(icon: "⏳", count: statistics.deathsByOldAge, label: "Age", color: .gray)
                }
                if statistics.deathsByLowEnergy > 0 {
                    ElegantDeathChip(icon: "⚡", count: statistics.deathsByLowEnergy, label: "Energy", color: .orange)
                }
                if statistics.deathsByHazard > 0 {
                    ElegantDeathChip(icon: "☠️", count: statistics.deathsByHazard, label: "Hazard", color: .purple)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.backgroundDark.opacity(0.6))
        )
    }
}

struct ElegantDeathChip: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            Text(icon)
                .font(DesignSystem.Typography.caption2)
            Text("\(count)")
                .font(DesignSystem.Typography.monoSmall)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.5))
        )
    }
}

// MARK: - Species Panel

struct SpeciesPanelView: View {
    let species: [SpeciesInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(DesignSystem.Colors.primaryGreen)
                Text("SPECIES DIVERSITY")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Spacer()

                Text("\(species.count)")
                    .font(DesignSystem.Typography.monoMedium)
                    .foregroundColor(DesignSystem.Colors.primaryGreen)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.primaryGreen.opacity(0.2))
                    )
            }

            if !species.isEmpty {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(species) { speciesData in
                        ElegantSpeciesRow(species: speciesData)
                    }
                }
            } else {
                Text("Awaiting species emergence...")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(DesignSystem.Spacing.lg)
            }
        }
        .cardStyle(padding: DesignSystem.Spacing.lg, cornerRadius: DesignSystem.CornerRadius.xl)
    }
}

struct ElegantSpeciesRow: View {
    let species: SpeciesInfo

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Species color with glow
            ZStack {
                Circle()
                    .fill(Color(red: species.color.red, green: species.color.green, blue: species.color.blue))
                    .frame(width: 20, height: 20)
                    .shadow(color: Color(red: species.color.red, green: species.color.green, blue: species.color.blue).opacity(0.6), radius: 6)

                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(species.name)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Day \(species.foundedOnDay)")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textTertiary)

                    Circle()
                        .fill(DesignSystem.Colors.textTertiary)
                        .frame(width: 2, height: 2)

                    Text("Spd: \(Int(species.averageSpeed))")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }

            Spacer()

            // Population badge
            Text("\(species.population)")
                .font(DesignSystem.Typography.monoSmall)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryGreen)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xxs)
                .background(
                    Capsule()
                        .fill(DesignSystem.Colors.primaryGreen.opacity(0.15))
                        .overlay(Capsule().stroke(DesignSystem.Colors.primaryGreen.opacity(0.3), lineWidth: 0.5))
                )
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundLight.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: species.color.red, green: species.color.green, blue: species.color.blue).opacity(0.4),
                                    Color(red: species.color.red, green: species.color.green, blue: species.color.blue).opacity(0.1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Milestones

struct MilestonesView: View {
    let milestones: EvolutionMilestones

    private var hasMilestones: Bool {
        milestones.fastestSpeed != nil ||
        milestones.oldestAge != nil ||
        milestones.largestSize != nil ||
        milestones.highestEnergy != nil ||
        milestones.deepestGeneration != nil ||
        milestones.largestPopulation != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(DesignSystem.Colors.accentYellow)
                Text("EVOLUTION RECORDS")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }

            if hasMilestones {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
                    if let speedRecord = milestones.fastestSpeed {
                        ElegantMilestoneCard(
                            icon: "bolt.fill",
                            title: "Fastest",
                            value: String(format: "%.0f", speedRecord.value),
                            detail: "Gen \(speedRecord.generation)",
                            gradient: LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    }

                    if let ageRecord = milestones.oldestAge {
                        ElegantMilestoneCard(
                            icon: "hourglass",
                            title: "Oldest",
                            value: "\(Int(ageRecord.value))",
                            detail: "Gen \(ageRecord.generation)",
                            gradient: LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    }

                    if let sizeRecord = milestones.largestSize {
                        ElegantMilestoneCard(
                            icon: "arrow.up.left.and.arrow.down.right",
                            title: "Largest",
                            value: String(format: "%.2f", sizeRecord.value),
                            detail: "Gen \(sizeRecord.generation)",
                            gradient: LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    }

                    if let energyRecord = milestones.highestEnergy {
                        ElegantMilestoneCard(
                            icon: "bolt.circle.fill",
                            title: "Energy",
                            value: String(format: "%.1f", energyRecord.value),
                            detail: "Gen \(energyRecord.generation)",
                            gradient: LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    }

                    if let genRecord = milestones.deepestGeneration {
                        ElegantMilestoneCard(
                            icon: "infinity",
                            title: "Generation",
                            value: "\(Int(genRecord.value))",
                            detail: "Day \(genRecord.achievedOnDay)",
                            gradient: LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    }

                    if let popRecord = milestones.largestPopulation {
                        ElegantMilestoneCard(
                            icon: "person.3.fill",
                            title: "Population",
                            value: "\(Int(popRecord.value))",
                            detail: "Day \(popRecord.achievedOnDay)",
                            gradient: LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    }
                }
            } else {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundColor(DesignSystem.Colors.textTertiary)

                    Text("Awaiting first records...")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .cardStyle(padding: DesignSystem.Spacing.lg, cornerRadius: DesignSystem.CornerRadius.xl)
    }
}

struct ElegantMilestoneCard: View {
    let icon: String
    let title: String
    let value: String
    let detail: String
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(gradient)

            Text(value)
                .font(DesignSystem.Typography.monoLarge)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Text(detail)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundLight.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(gradient.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Charts Section

struct ChartsSection: View {
    let snapshots: [DailySnapshot]
    let organisms: [OrganismInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            TabView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    PopulationChartView(snapshots: snapshots)
                    SpeedChartView(snapshots: snapshots)
                }
                .tag(0)

                SpeedDistributionView(organisms: organisms)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 450)
        }
        .cardStyle(padding: DesignSystem.Spacing.lg, cornerRadius: DesignSystem.CornerRadius.xl)
    }
}

struct PopulationChartView: View {
    let snapshots: [DailySnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Population Over Time")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            if snapshots.count > 1 {
                Chart(snapshots) { snapshot in
                    LineMark(
                        x: .value("Day", snapshot.day),
                        y: .value("Population", snapshot.population)
                    )
                    .foregroundStyle(DesignSystem.Colors.primaryGreen)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                    AreaMark(
                        x: .value("Day", snapshot.day),
                        y: .value("Population", snapshot.population)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primaryGreen.opacity(0.3), DesignSystem.Colors.primaryGreen.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(position: .bottom) {
                        AxisValueLabel()
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisValueLabel()
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        ProgressView()
                            .tint(DesignSystem.Colors.primaryCyan)
                        Text("Collecting data...")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    Spacer()
                }
                .frame(height: 150)
            }
        }
    }
}

struct SpeedChartView: View {
    let snapshots: [DailySnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Average Speed Evolution")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            if snapshots.count > 1 {
                Chart(snapshots) { snapshot in
                    LineMark(
                        x: .value("Day", snapshot.day),
                        y: .value("Speed", snapshot.averageSpeed)
                    )
                    .foregroundStyle(DesignSystem.Colors.accentOrange)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                    AreaMark(
                        x: .value("Day", snapshot.day),
                        y: .value("Speed", snapshot.averageSpeed)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.accentOrange.opacity(0.3), DesignSystem.Colors.accentOrange.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(position: .bottom) {
                        AxisValueLabel()
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisValueLabel()
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        ProgressView()
                            .tint(DesignSystem.Colors.primaryCyan)
                        Text("Collecting data...")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    Spacer()
                }
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
            let bucket = (organism.speed / 5) * 5
            buckets[bucket, default: 0] += 1
        }
        return buckets.map { SpeedBucket(speed: $0.key, count: $0.value) }
            .sorted { $0.speed < $1.speed }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Speed Distribution")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            if !organisms.isEmpty {
                Chart(speedBuckets) { bucket in
                    BarMark(
                        x: .value("Speed", bucket.speed),
                        y: .value("Count", bucket.count)
                    )
                    .foregroundStyle(DesignSystem.Colors.primaryPurple)
                    .cornerRadius(4)
                }
                .frame(height: 320)
                .chartXAxis {
                    AxisMarks(position: .bottom) {
                        AxisValueLabel()
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisValueLabel()
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.largeTitle)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        Text("No organisms")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    Spacer()
                }
                .frame(height: 320)
            }
        }
        .padding(DesignSystem.Spacing.md)
    }
}

struct SpeedBucket: Identifiable {
    let id = UUID()
    let speed: Int
    let count: Int
}

// MARK: - Organism List

struct OrganismListView: View {
    let organisms: [OrganismInfo]

    private var sortedOrganisms: [OrganismInfo] {
        organisms.sorted { $0.speed > $1.speed }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(DesignSystem.Colors.primaryCyan)
                Text("ORGANISMS")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Spacer()

                Text("\(organisms.count)")
                    .font(DesignSystem.Typography.monoMedium)
                    .foregroundColor(DesignSystem.Colors.primaryCyan)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.primaryCyan.opacity(0.2))
                    )
            }

            if organisms.isEmpty {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(DesignSystem.Colors.statusWarning)
                    Text("Population extinct")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.xl)
            } else {
                LazyVStack(spacing: DesignSystem.Spacing.xxs) {
                    ForEach(sortedOrganisms.prefix(50)) { organism in
                        ElegantOrganismRow(organism: organism)
                    }

                    if organisms.count > 50 {
                        Text("+ \(organisms.count - 50) more organisms")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(DesignSystem.Spacing.sm)
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .cardStyle(padding: DesignSystem.Spacing.lg, cornerRadius: DesignSystem.CornerRadius.xl)
    }
}

struct ElegantOrganismRow: View {
    let organism: OrganismInfo

    private var idPrefix: String {
        String(organism.id.uuidString.prefix(8))
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Status indicator
            Circle()
                .fill(organism.hasFoodToday ? DesignSystem.Colors.statusSuccess : DesignSystem.Colors.statusError)
                .frame(width: 6, height: 6)
                .shadow(color: organism.hasFoodToday ? DesignSystem.Colors.statusSuccess : DesignSystem.Colors.statusError, radius: 3)

            // ID
            Text(idPrefix)
                .font(DesignSystem.Typography.monoSmall)
                .foregroundColor(DesignSystem.Colors.textTertiary)

            Spacer()

            // Speed
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.accentOrange)
                Text("\(organism.speed)")
                    .font(DesignSystem.Typography.monoSmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }

            // Generation
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.primaryCyan)
                Text("\(organism.generation)")
                    .font(DesignSystem.Typography.monoSmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.backgroundLight.opacity(0.2))
        )
    }
}
