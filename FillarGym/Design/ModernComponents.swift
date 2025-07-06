//
//  ModernComponents.swift
//  FillarGym
//
//  Created by 浜崎大輔 on 2025/07/06.
//

import SwiftUI

// MARK: - Modern Card Component
struct ModernCard<Content: View>: View {
    let elevation: CardElevation
    let padding: CGFloat
    let isPremium: Bool
    let content: Content
    
    init(
        elevation: CardElevation = .medium,
        padding: CGFloat = DesignSystem.Spacing.lg,
        isPremium: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.padding = padding
        self.isPremium = isPremium
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundView)
            .cornerRadius(DesignSystem.CornerRadius.large)
            .shadow(
                color: isPremium ? DesignSystem.Colors.shadowPremium : elevation.shadow.color,
                radius: elevation.shadow.radius,
                x: elevation.shadow.x,
                y: elevation.shadow.y
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .stroke(
                        isPremium ? 
                        LinearGradient(
                            gradient: Gradient(colors: [
                                DesignSystem.Colors.accent.opacity(0.3),
                                DesignSystem.Colors.secondary.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : 
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isPremium ? 1 : 0
                    )
            )
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isPremium {
            LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.surface,
                    DesignSystem.Colors.surfaceElevated
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            DesignSystem.Colors.surface
        }
    }
}

// MARK: - Pill Button Component
struct PillButton: View {
    let title: String
    let icon: String?
    let size: ButtonSize
    let variant: ButtonVariant
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        variant: ButtonVariant = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.variant = variant
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: variant.textColor))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.IconSize.small, weight: .semibold))
                }
                
                Text(title)
                    .font(DesignSystem.Typography.bodyBold)
            }
            .foregroundColor(variant.textColor)
            .frame(height: size.height)
            .frame(minWidth: size.height * 2)
            .padding(.horizontal, size.horizontalPadding)
            .background(backgroundView)
            .cornerRadius(DesignSystem.CornerRadius.pill)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .shadow(
                color: isPressed ? DesignSystem.Colors.shadowLight : DesignSystem.Colors.shadowMedium,
                radius: isPressed ? 2 : 4,
                x: 0,
                y: isPressed ? 1 : 2
            )
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .animation(DesignSystem.Animation.quick, value: isPressed)
        .disabled(isLoading)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .outline:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pill)
                .stroke(DesignSystem.Colors.primary, lineWidth: 2)
                .background(Color.clear)
        case .ghost:
            Color.clear
        default:
            variant.backgroundColor
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.large, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: DesignSystem.ButtonSize.large, height: DesignSystem.ButtonSize.large)
                .background(DesignSystem.Colors.surface)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.94 : 1.0)
                .shadow(
                    color: isPressed ? DesignSystem.Colors.shadowMedium : DesignSystem.Colors.shadowStrong,
                    radius: isPressed ? 8 : 12,
                    x: 0,
                    y: isPressed ? 4 : 6
                )
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .animation(DesignSystem.Animation.spring, value: isPressed)
    }
}

// MARK: - Progress Card
struct ProgressCard: View {
    let title: String
    let value: Double
    let total: Double
    let unit: String
    let color: Color
    let icon: String
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return min(value / total, 1.0)
    }
    
    var body: some View {
        ModernCard(elevation: .medium) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.IconSize.medium, weight: .semibold))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack(alignment: .lastTextBaseline) {
                        Text("\(Int(value))")
                            .font(DesignSystem.Typography.numberLarge)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(unit)
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(Int(percentage * 100))%")
                            .font(DesignSystem.Typography.numberSmall)
                            .foregroundColor(color)
                    }
                    
                    ProgressView(value: percentage)
                        .progressViewStyle(ModernProgressViewStyle(color: color))
                }
            }
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let trend: TrendDirection?
    let color: Color
    let icon: String
    
    var body: some View {
        ModernCard(elevation: .low, padding: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.IconSize.small, weight: .medium))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    if let trend = trend {
                        TrendIndicator(direction: trend)
                    }
                }
                
                Text(value)
                    .font(DesignSystem.Typography.numberMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    let status: BadgeStatus
    
    var body: some View {
        Text(text)
            .font(DesignSystem.Typography.caption)
            .foregroundColor(status.textColor)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(status.backgroundColor)
            .cornerRadius(DesignSystem.CornerRadius.pill)
    }
}

// MARK: - Trend Indicator
struct TrendIndicator: View {
    let direction: TrendDirection
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: direction.iconName)
                .font(.system(size: 10, weight: .bold))
            
            Text(direction.label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(direction.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(direction.backgroundColor)
        .cornerRadius(4)
    }
}

// MARK: - Modern Progress View Style
struct ModernProgressViewStyle: ProgressViewStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(DesignSystem.Colors.backgroundSecondary)
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(color)
                    .frame(
                        width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0),
                        height: 8
                    )
                    .animation(DesignSystem.Animation.standard, value: configuration.fractionCompleted)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Supporting Types
enum TrendDirection {
    case up
    case down
    case stable
    
    var iconName: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "arrow.left.arrow.right"
        }
    }
    
    var label: String {
        switch self {
        case .up: return "上昇"
        case .down: return "下降"
        case .stable: return "安定"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return DesignSystem.Colors.success
        case .down: return DesignSystem.Colors.error
        case .stable: return DesignSystem.Colors.textSecondary
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .up: return DesignSystem.Colors.success.opacity(0.1)
        case .down: return DesignSystem.Colors.error.opacity(0.1)
        case .stable: return DesignSystem.Colors.backgroundSecondary
        }
    }
}

enum BadgeStatus {
    case success
    case warning
    case error
    case info
    case neutral
    
    var backgroundColor: Color {
        switch self {
        case .success: return DesignSystem.Colors.success.opacity(0.1)
        case .warning: return DesignSystem.Colors.warning.opacity(0.1)
        case .error: return DesignSystem.Colors.error.opacity(0.1)
        case .info: return DesignSystem.Colors.info.opacity(0.1)
        case .neutral: return DesignSystem.Colors.backgroundSecondary
        }
    }
    
    var textColor: Color {
        switch self {
        case .success: return DesignSystem.Colors.success
        case .warning: return DesignSystem.Colors.warning
        case .error: return DesignSystem.Colors.error
        case .info: return DesignSystem.Colors.info
        case .neutral: return DesignSystem.Colors.textSecondary
        }
    }
}

// MARK: - Press Events View Modifier
struct PressEvents: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(1.0)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                if pressing {
                    onPress()
                } else {
                    onRelease()
                }
            }, perform: {})
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}