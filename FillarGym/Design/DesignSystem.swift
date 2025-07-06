//
//  DesignSystem.swift
//  FillarGym
//
//  Created by 浜崎大輔 on 2025/07/06.
//

import SwiftUI

// MARK: - Design System
struct DesignSystem {
    
    // MARK: - Colors (Premium Blue Theme)
    struct Colors {
        // Primary Colors - Deep Luxury Blue
        static let primary = Color(hex: "#1A365D")        // Deep Navy Blue
        static let primaryDark = Color(hex: "#0F2A44")    // Darker Navy
        static let primaryLight = Color(hex: "#2D5A87")   // Lighter Navy
        
        // Secondary Colors - Sophisticated Blue
        static let secondary = Color(hex: "#2563EB")      // Royal Blue
        static let secondaryDark = Color(hex: "#1D4ED8")  // Deep Royal Blue
        static let secondaryLight = Color(hex: "#3B82F6") // Bright Blue
        
        // Accent Colors - Premium Gold/Amber
        static let accent = Color(hex: "#D4AF37")         // Luxury Gold
        static let accentDark = Color(hex: "#B8941F")     // Darker Gold
        static let accentLight = Color(hex: "#F1D34E")    // Light Gold
        
        // Status Colors
        static let error = Color(hex: "#DC2626")          // Sophisticated Red
        static let warning = Color(hex: "#D97706")        // Warm Orange
        static let success = Color(hex: "#059669")        // Deep Green
        static let info = Color(hex: "#0EA5E9")           // Sky Blue
        
        // Neutral Colors - Cool Blue Tints
        static let background = Color(hex: "#F8FAFC")     // Cool White
        static let backgroundSecondary = Color(hex: "#F1F5F9") // Light Blue Gray
        static let surface = Color(hex: "#FFFFFF")        // Pure White
        static let surfaceSecondary = Color(hex: "#F8FAFC") // Cool Surface
        static let surfaceElevated = Color(hex: "#EFF6FF") // Elevated Blue Tint
        
        // Text Colors - Blue-Gray Spectrum
        static let textPrimary = Color(hex: "#0F172A")    // Dark Blue Black
        static let textSecondary = Color(hex: "#334155")  // Blue Gray
        static let textTertiary = Color(hex: "#64748B")   // Light Blue Gray
        static let textInverse = Color(hex: "#FFFFFF")    // Pure White
        static let textAccent = Color(hex: "#1E40AF")     // Blue Accent Text
        
        // Border Colors
        static let border = Color(hex: "#E2E8F0")         // Light Border
        static let borderSecondary = Color(hex: "#CBD5E1") // Medium Border
        static let borderFocus = Color(hex: "#2563EB")    // Blue Focus
        
        // Shadow Colors - Blue Tinted Shadows
        static let shadowLight = Color(hex: "#1E40AF").opacity(0.04)   // Blue Tinted Light Shadow
        static let shadowMedium = Color(hex: "#1E40AF").opacity(0.08)  // Blue Tinted Medium Shadow
        static let shadowStrong = Color(hex: "#1E40AF").opacity(0.12)  // Blue Tinted Strong Shadow
        static let shadowPremium = Color(hex: "#0F172A").opacity(0.15) // Premium Dark Shadow
    }
    
    // MARK: - Typography
    struct Typography {
        // Large Titles
        static let largeTitle = Font.custom("Inter", size: 34)
            .weight(.bold)
        
        // Titles
        static let title1 = Font.custom("Inter", size: 28)
            .weight(.bold)
        static let title2 = Font.custom("Inter", size: 24)
            .weight(.bold)
        static let title3 = Font.custom("Inter", size: 20)
            .weight(.semibold)
        
        // Headlines
        static let headline = Font.custom("Inter", size: 18)
            .weight(.semibold)
        static let subheadline = Font.custom("Inter", size: 16)
            .weight(.medium)
        
        // Body Text
        static let body = Font.custom("Inter", size: 14)
            .weight(.regular)
        static let bodyBold = Font.custom("Inter", size: 14)
            .weight(.semibold)
        
        // Small Text
        static let caption = Font.custom("Inter", size: 12)
            .weight(.medium)
        static let caption2 = Font.custom("Inter", size: 11)
            .weight(.regular)
        
        // Numbers & Data
        static let numberLarge = Font.custom("Inter", size: 32)
            .weight(.black)
        static let numberMedium = Font.custom("Inter", size: 24)
            .weight(.bold)
        static let numberSmall = Font.custom("Inter", size: 16)
            .weight(.semibold)
    }
    
    // MARK: - Spacing (8pt Grid System)
    struct Spacing {
        static let xs: CGFloat = 4      // 0.5 units
        static let sm: CGFloat = 8      // 1 unit
        static let md: CGFloat = 16     // 2 units
        static let lg: CGFloat = 24     // 3 units
        static let xl: CGFloat = 32     // 4 units
        static let xxl: CGFloat = 40    // 5 units
        static let xxxl: CGFloat = 48   // 6 units
        static let giant: CGFloat = 64  // 8 units
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        static let pill: CGFloat = 9999 // For pill-shaped buttons
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Shadow(
            color: Colors.shadowLight,
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let medium = Shadow(
            color: Colors.shadowMedium,
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let large = Shadow(
            color: Colors.shadowMedium,
            radius: 16,
            x: 0,
            y: 8
        )
        
        static let extraLarge = Shadow(
            color: Colors.shadowStrong,
            radius: 24,
            x: 0,
            y: 12
        )
    }
    
    // MARK: - Button Sizes
    struct ButtonSize {
        static let small: CGFloat = 32
        static let medium: CGFloat = 44
        static let large: CGFloat = 56
    }
    
    // MARK: - Icon Sizes
    struct IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeOut(duration: 0.5)
        
        // Spring animations for interactive elements
        static let spring = SwiftUI.Animation.spring(
            response: 0.4,
            dampingFraction: 0.8,
            blendDuration: 0
        )
        
        static let springBouncy = SwiftUI.Animation.spring(
            response: 0.5,
            dampingFraction: 0.6,
            blendDuration: 0
        )
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers for Design System
struct ModernCardStyle: ViewModifier {
    let elevation: CardElevation
    
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.large)
            .shadow(
                color: elevation.shadow.color,
                radius: elevation.shadow.radius,
                x: elevation.shadow.x,
                y: elevation.shadow.y
            )
    }
}

struct PillButtonStyle: ViewModifier {
    let size: ButtonSize
    let variant: ButtonVariant
    
    func body(content: Content) -> some View {
        content
            .font(DesignSystem.Typography.bodyBold)
            .foregroundColor(variant.textColor)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(variant.backgroundColor)
            .cornerRadius(DesignSystem.CornerRadius.pill)
            .shadow(
                color: DesignSystem.Colors.shadowLight,
                radius: 2,
                x: 0,
                y: 1
            )
    }
}

// MARK: - Enums for Design System
enum CardElevation {
    case flat
    case low
    case medium
    case high
    
    var shadow: Shadow {
        switch self {
        case .flat:
            return Shadow(color: .clear, radius: 0, x: 0, y: 0)
        case .low:
            return DesignSystem.Shadows.small
        case .medium:
            return DesignSystem.Shadows.medium
        case .high:
            return DesignSystem.Shadows.large
        }
    }
}

enum ButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return DesignSystem.ButtonSize.small
        case .medium: return DesignSystem.ButtonSize.medium
        case .large: return DesignSystem.ButtonSize.large
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return DesignSystem.Spacing.md
        case .medium: return DesignSystem.Spacing.lg
        case .large: return DesignSystem.Spacing.xl
        }
    }
}

enum ButtonVariant {
    case primary
    case secondary
    case outline
    case ghost
    case danger
    
    var backgroundColor: Color {
        switch self {
        case .primary: return DesignSystem.Colors.primary
        case .secondary: return DesignSystem.Colors.secondary
        case .outline: return Color.clear
        case .ghost: return Color.clear
        case .danger: return DesignSystem.Colors.error
        }
    }
    
    var textColor: Color {
        switch self {
        case .primary, .secondary, .danger: return DesignSystem.Colors.textInverse
        case .outline, .ghost: return DesignSystem.Colors.primary
        }
    }
}

// MARK: - View Extensions
extension View {
    func modernCard(elevation: CardElevation = .medium) -> some View {
        modifier(ModernCardStyle(elevation: elevation))
    }
    
    func pillButton(size: ButtonSize = .medium, variant: ButtonVariant = .primary) -> some View {
        modifier(PillButtonStyle(size: size, variant: variant))
    }
    
}