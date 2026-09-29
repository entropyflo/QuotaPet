import AppKit
import SwiftUI

extension View {
    func quotaLiquidGlass(tint: Color, cornerRadius: CGFloat = 16) -> some View {
        modifier(QuotaLiquidGlassModifier(tint: tint, cornerRadius: cornerRadius))
    }
}

private struct QuotaLiquidGlassModifier: ViewModifier {
    let tint: Color
    let cornerRadius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(macOS 26.0, *), !reduceTransparency {
            content
                .glassEffect(.clear.tint(tint.opacity(0.07)).interactive(), in: shape)
                .overlay {
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.82),
                                .white.opacity(0.22),
                                tint.opacity(0.34)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.9
                    )
                }
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.white.opacity(0.34))
                        .frame(height: 1.2)
                        .padding(.horizontal, cornerRadius)
                        .padding(.top, 1)
                }
                .shadow(color: .black.opacity(0.12), radius: 11, y: 5)
                .shadow(color: tint.opacity(0.12), radius: 14, y: 3)
        } else {
            content
                .background {
                    shape
                        .fill(reduceTransparency
                              ? AnyShapeStyle(Color(nsColor: .windowBackgroundColor))
                              : AnyShapeStyle(.ultraThinMaterial))
                        .overlay {
                            shape.fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(reduceTransparency ? 0.04 : 0.08),
                                        tint.opacity(reduceTransparency ? 0.06 : 0.025),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                        .overlay {
                            shape.strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.62), .white.opacity(0.08), tint.opacity(0.16)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                        }
                        .overlay(alignment: .top) {
                            Capsule()
                                .fill(.white.opacity(reduceTransparency ? 0.08 : 0.16))
                                .frame(height: 1)
                                .padding(.horizontal, cornerRadius)
                                .padding(.top, 1)
                        }
                }
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                .shadow(color: tint.opacity(0.04), radius: 12, y: 2)
        }
    }
}

struct LiquidQuotaProgress: View {
    let progress: Double
    let color: Color
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var clampedProgress: CGFloat {
        CGFloat(min(1, max(0, progress)))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                track
                if clampedProgress > 0 {
                    fill
                        .frame(width: geometry.size.width * clampedProgress)
                }
            }
        }
        .frame(height: 11)
        .accessibilityHidden(true)
    }

    @ViewBuilder private var track: some View {
        if #available(macOS 26.0, *), !reduceTransparency {
            Color.clear.glassEffect(.clear, in: Capsule())
        } else {
            Capsule()
                .fill(.primary.opacity(reduceTransparency ? 0.16 : 0.09))
                .overlay(Capsule().stroke(.white.opacity(0.34), lineWidth: 0.7))
                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        }
    }

    @ViewBuilder private var fill: some View {
        if #available(macOS 26.0, *), !reduceTransparency {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.78), color, color.opacity(0.76)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.white.opacity(0.52))
                        .frame(height: 2.2)
                        .padding(.horizontal, 3)
                        .padding(.top, 1.2)
                }
                .glassEffect(.clear, in: Capsule())
                .shadow(color: color.opacity(0.34), radius: 4, y: 1)
        } else {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.80), color, color.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.white.opacity(reduceTransparency ? 0.12 : 0.48))
                        .frame(height: 2.2)
                        .padding(.horizontal, 3)
                        .padding(.top, 1.2)
                }
                .overlay(Capsule().stroke(.white.opacity(0.34), lineWidth: 0.6))
                .shadow(color: color.opacity(0.32), radius: 4, y: 1)
        }
    }
}
