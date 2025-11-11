//
//  DesignSystem.swift
//  Evolution
//
//  Created by Claude on 11/11/25.
//

import SwiftUI

/// Centralized design system for consistent UI styling
enum DesignSystem {

    // MARK: - Colors
    enum Colors {
        // Primary brand colors
        static let primaryCyan = Color(red: 0.0, green: 0.8, blue: 0.9)
        static let primaryPurple = Color(red: 0.6, green: 0.2, blue: 0.8)
        static let primaryGreen = Color(red: 0.2, green: 0.8, blue: 0.4)

        // Accent colors
        static let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
        static let accentPink = Color(red: 1.0, green: 0.3, blue: 0.6)
        static let accentYellow = Color(red: 1.0, green: 0.9, blue: 0.0)

        // Status colors
        static let statusSuccess = Color(red: 0.2, green: 0.85, blue: 0.4)
        static let statusWarning = Color(red: 1.0, green: 0.7, blue: 0.0)
        static let statusError = Color(red: 0.95, green: 0.3, blue: 0.3)
        static let statusInfo = Color(red: 0.3, green: 0.7, blue: 1.0)

        // Neutral colors
        static let backgroundDark = Color(red: 0.08, green: 0.08, blue: 0.12)
        static let backgroundMedium = Color(red: 0.12, green: 0.12, blue: 0.18)
        static let backgroundLight = Color(red: 0.18, green: 0.18, blue: 0.24)

        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.7, green: 0.7, blue: 0.75)
        static let textTertiary = Color(red: 0.5, green: 0.5, blue: 0.55)

        // Gradient backgrounds
        static let gradientPurpleCyan = LinearGradient(
            colors: [primaryPurple.opacity(0.3), primaryCyan.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let gradientDark = LinearGradient(
            colors: [backgroundDark, backgroundMedium],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Typography
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 15, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 13, weight: .medium, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)

        // Monospaced variants for numbers
        static let monoLarge = Font.system(size: 28, weight: .bold, design: .monospaced)
        static let monoMedium = Font.system(size: 17, weight: .semibold, design: .monospaced)
        static let monoSmall = Font.system(size: 13, weight: .regular, design: .monospaced)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }

    // MARK: - Shadows
    enum Shadow {
        static let sm = Shadow.custom(radius: 4, opacity: 0.1)
        static let md = Shadow.custom(radius: 8, opacity: 0.15)
        static let lg = Shadow.custom(radius: 16, opacity: 0.2)
        static let xl = Shadow.custom(radius: 24, opacity: 0.25)

        static func custom(radius: CGFloat, opacity: Double) -> ViewModifier {
            return ShadowModifier(radius: radius, opacity: opacity)
        }
    }

    // MARK: - Animations
    enum Animations {
        static let fast = Animation.easeInOut(duration: 0.2)
        static let standard = Animation.easeInOut(duration: 0.3)
        static let slow = Animation.easeInOut(duration: 0.5)
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bounce = Animation.spring(response: 0.5, dampingFraction: 0.6)
    }
}

// MARK: - View Modifiers

struct ShadowModifier: ViewModifier {
    let radius: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(opacity), radius: radius, x: 0, y: radius / 2)
    }
}

struct GlassmorphicBackground: ViewModifier {
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.lg
    var opacity: Double = 0.1

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(opacity),
                                        Color.white.opacity(opacity * 0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = DesignSystem.Spacing.md
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignSystem.Colors.backgroundLight.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .modifier(ShadowModifier(radius: 8, opacity: 0.2))
    }
}

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    let color: Color

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(color.opacity(isPulsing ? 0.0 : 0.8), lineWidth: 2)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                        value: isPulsing
                    )
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - View Extensions

extension View {
    func glassmorphic(cornerRadius: CGFloat = DesignSystem.CornerRadius.lg, opacity: Double = 0.1) -> some View {
        modifier(GlassmorphicBackground(cornerRadius: cornerRadius, opacity: opacity))
    }

    func cardStyle(padding: CGFloat = DesignSystem.Spacing.md, cornerRadius: CGFloat = DesignSystem.CornerRadius.md) -> some View {
        modifier(CardStyle(padding: padding, cornerRadius: cornerRadius))
    }

    func pulseEffect(color: Color = .cyan) -> some View {
        modifier(PulseEffect(color: color))
    }

    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.2),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    phase = 500
                }
            }
    }
}
