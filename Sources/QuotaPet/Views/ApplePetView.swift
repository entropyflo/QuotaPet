import AppKit
import SwiftUI
import QuotaPetCore

struct ApplePetView: View {
    let window: QuotaWindow?
    let mode: PetScaleMode
    let reduceMotion: Bool

    private var remaining: Double? { window?.remainingPercent }
    private var remainingStep: Int {
        guard let remaining else { return 0 }
        return min(10, max(0, Int(floor(remaining / 10))))
    }
    private var biteCount: Int {
        guard let remaining else { return 0 }
        return min(9, max(0, Int(floor((100 - remaining) / 10))))
    }

    var body: some View {
        Group {
            if mode == .half {
                flatApple
            } else {
                spriteApple
            }
        }
        .frame(width: 132, height: 112)
        .accessibilityHidden(true)
    }

    @ViewBuilder private var spriteApple: some View {
        if let image = AppleSpriteSheet.frame(at: spriteStage) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 126, height: 112)
                .shadow(color: .black.opacity(0.16), radius: 8, y: 5)
                .rotation3DEffect(
                    .degrees(rotationAngle),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.22
                )
                .animation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.80), value: spriteStage)
        } else if remaining == 0 {
            AppleCoreView()
        } else {
            dimensionalApple
        }
    }

    private var spriteStage: Int {
        guard let remaining else { return 0 }
        return min(9, max(0, Int(floor((100 - remaining) / 10))))
    }

    private var flatApple: some View {
        ZStack {
            AppleStemAndLeaf(leafColor: flatAppleColor.opacity(0.88))
            AppleSilhouette()
                .fill(flatAppleColor)
                .overlay(AppleSilhouette().stroke(.black.opacity(0.10), lineWidth: 1))
        }
        .frame(width: 112, height: 102)
    }

    private var dimensionalApple: some View {
        ZStack {
            AppleStemAndLeaf(leafColor: .green)
            BittenAppleShape(bites: biteCount)
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.34, blue: 0.24),
                            Color(red: 0.86, green: 0.05, blue: 0.08),
                            Color(red: 0.38, green: 0.01, blue: 0.03)
                        ],
                        center: UnitPoint(x: 0.34, y: 0.24),
                        startRadius: 3,
                        endRadius: 92
                    ),
                    style: FillStyle(eoFill: true)
                )
                .clipShape(AppleSilhouette())
                .overlay {
                    AppleSilhouette()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.52), .clear, .black.opacity(0.32)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
                .overlay(alignment: .topLeading) {
                    Ellipse()
                        .fill(.white.opacity(0.48))
                        .frame(width: 18, height: 9)
                        .blur(radius: 1.4)
                        .offset(x: 31, y: 30)
                }
                .shadow(color: .red.opacity(0.25), radius: 12, y: 7)
        }
        .frame(width: 126, height: 108)
        .rotation3DEffect(
            .degrees(rotationAngle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.28
        )
        .animation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.78), value: biteCount)
    }

    private var rotationAngle: Double {
        let angles: [Double] = [0, -13, 11, -10, 12, -11, 9, -8, 7, -6]
        return angles[min(biteCount, angles.count - 1)]
    }

    private var flatAppleColor: Color {
        guard remaining != nil else { return .gray }
        let t = Double(remainingStep) / 10
        let brown = (r: 0.30, g: 0.15, b: 0.055)
        let green = (r: 0.50, g: 0.78, b: 0.16)
        return Color(
            red: brown.r + (green.r - brown.r) * t,
            green: brown.g + (green.g - brown.g) * t,
            blue: brown.b + (green.b - brown.b) * t
        )
    }
}

struct CompactQuotaAppleView: View {
    let window: QuotaWindow?
    let now: Date

    private var remaining: Double? { window?.remainingPercent }
    private var progress: CGFloat { CGFloat((remaining ?? 0) / 100) }
    private var step: Int {
        guard let remaining else { return 0 }
        return min(10, max(0, Int(floor(remaining / 10))))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.10), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [ringColor.opacity(0.72), ringColor, ringColor.opacity(0.78)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: ringColor.opacity(0.35), radius: 4)

            ZStack {
                AppleStemAndLeaf(leafColor: flatAppleColor.opacity(0.88))
                AppleSilhouette()
                    .fill(flatAppleColor)
                    .overlay(AppleSilhouette().stroke(.black.opacity(0.12), lineWidth: 1))
            }
            .frame(width: 96, height: 88)
            .offset(y: 7)

            VStack(spacing: 1) {
                Text(remaining.map { "\(Int($0.rounded()))%" } ?? "--%")
                    .font(.body.weight(.heavy))
                Text(window?.remainingTimeDescription(at: now) ?? "暂不可用")
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.85), radius: 2.5, y: 1)
            .offset(y: 4)
        }
        .frame(width: 126, height: 126)
        .accessibilityElement(children: .combine)
    }

    private var ringColor: Color {
        guard let remaining else { return .gray }
        if remaining == 0 { return .brown }
        if remaining <= 20 { return .red }
        if remaining <= 50 { return .yellow }
        return .green
    }

    private var flatAppleColor: Color {
        guard remaining != nil else { return .gray }
        let t = Double(step) / 10
        let brown = (r: 0.30, g: 0.15, b: 0.055)
        let green = (r: 0.50, g: 0.78, b: 0.16)
        return Color(
            red: brown.r + (green.r - brown.r) * t,
            green: brown.g + (green.g - brown.g) * t,
            blue: brown.b + (green.b - brown.b) * t
        )
    }
}

@MainActor
private enum AppleSpriteSheet {
    static func frame(at index: Int) -> NSImage? {
        guard let url = Bundle.module.url(
            forResource: "apple-quota-10-stage-v2-cartoon",
            withExtension: "png"
        ), let sheet = NSImage(contentsOf: url) else { return nil }

        let columns: CGFloat = 5
        let rows: CGFloat = 2
        let cellSize = NSSize(width: sheet.size.width / columns, height: sheet.size.height / rows)
        let stage = min(9, max(0, index))
        let column = CGFloat(stage % 5)
        let rowFromTop = CGFloat(stage / 5)
        let sourceRect = NSRect(
            x: column * cellSize.width,
            y: (rows - 1 - rowFromTop) * cellSize.height,
            width: cellSize.width,
            height: cellSize.height
        )
        let frame = NSImage(size: cellSize)
        frame.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        sheet.draw(
            in: NSRect(origin: .zero, size: cellSize),
            from: sourceRect,
            operation: .copy,
            fraction: 1
        )
        frame.unlockFocus()
        return frame
    }
}

private struct AppleStemAndLeaf: View {
    let leafColor: Color

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.30, green: 0.13, blue: 0.04))
                .frame(width: 7, height: 28)
                .rotationEffect(.degrees(10))
                .offset(x: 5, y: -43)
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [leafColor.opacity(0.95), leafColor.opacity(0.48)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 31, height: 15)
                .rotationEffect(.degrees(-24))
                .offset(x: 21, y: -42)
        }
    }
}

private struct AppleSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.22))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.92, y: rect.height * 0.48),
            control1: CGPoint(x: rect.width * 0.68, y: rect.height * 0.10),
            control2: CGPoint(x: rect.width * 0.96, y: rect.height * 0.20)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.68, y: rect.height * 0.93),
            control1: CGPoint(x: rect.width * 0.94, y: rect.height * 0.72),
            control2: CGPoint(x: rect.width * 0.83, y: rect.height * 0.92)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.height * 0.86),
            control1: CGPoint(x: rect.width * 0.60, y: rect.height),
            control2: CGPoint(x: rect.width * 0.54, y: rect.height * 0.88)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.32, y: rect.height * 0.93),
            control1: CGPoint(x: rect.width * 0.46, y: rect.height * 0.88),
            control2: CGPoint(x: rect.width * 0.40, y: rect.height)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.08, y: rect.height * 0.48),
            control1: CGPoint(x: rect.width * 0.17, y: rect.height * 0.92),
            control2: CGPoint(x: rect.width * 0.06, y: rect.height * 0.72)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.height * 0.22),
            control1: CGPoint(x: rect.width * 0.04, y: rect.height * 0.20),
            control2: CGPoint(x: rect.width * 0.32, y: rect.height * 0.10)
        )
        path.closeSubpath()
        return path
    }
}

private struct BittenAppleShape: Shape {
    let bites: Int

    private let biteLayout: [(CGFloat, CGFloat, CGFloat)] = [
        (0.91, 0.34, 0.13), (0.93, 0.51, 0.14), (0.88, 0.69, 0.14),
        (0.75, 0.84, 0.13), (0.55, 0.88, 0.13), (0.35, 0.86, 0.13),
        (0.18, 0.72, 0.14), (0.10, 0.52, 0.14), (0.16, 0.33, 0.13)
    ]

    func path(in rect: CGRect) -> Path {
        var path = AppleSilhouette().path(in: rect)
        for (x, y, radius) in biteLayout.prefix(bites) {
            let diameter = rect.width * radius * 2
            path.addEllipse(in: CGRect(
                x: rect.width * x - diameter / 2,
                y: rect.height * y - diameter / 2,
                width: diameter,
                height: diameter
            ))
        }
        return path
    }
}

private struct AppleCoreView: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.96, green: 0.84, blue: 0.56), .white, Color(red: 0.77, green: 0.62, blue: 0.31)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 38, height: 88)
                .overlay {
                    VStack(spacing: 8) {
                        Capsule().fill(.brown).frame(width: 7, height: 14).rotationEffect(.degrees(-18))
                        HStack(spacing: 9) {
                            Ellipse().fill(.brown.opacity(0.86)).frame(width: 6, height: 11).rotationEffect(.degrees(-24))
                            Ellipse().fill(.brown.opacity(0.86)).frame(width: 6, height: 11).rotationEffect(.degrees(24))
                        }
                    }
                }
            Ellipse().fill(.red.gradient).frame(width: 70, height: 19).offset(y: -39)
            Ellipse().fill(.red.gradient).frame(width: 66, height: 18).offset(y: 39)
        }
        .shadow(color: .black.opacity(0.17), radius: 8, y: 5)
    }
}
