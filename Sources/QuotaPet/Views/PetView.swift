import SwiftUI
import QuotaPetCore

struct PetView: View {
    @ObservedObject var state: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassNamespace
    @State private var hovering = false
    @State private var weeklyPresented = false
    @State private var weeklyExpansion: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            if state.petScaleMode == .half {
                compactLayout
            } else {
                fullLayout(
                    scale: min(geometry.size.width / 300, geometry.size.height / 280)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onHover { value in
            if reduceMotion {
                hovering = value
                weeklyPresented = value
                weeklyExpansion = value ? 1 : 0
            } else {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.80)) {
                    hovering = value
                }
            }
        }
        .task(id: hovering) {
            guard !reduceMotion else { return }
            await animateWeeklyGlass(for: hovering)
        }
    }

    private var compactLayout: some View {
        ZStack(alignment: .bottomTrailing) {
            CompactQuotaAppleView(window: state.snapshot?.fiveHour, now: state.now)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if hovering && !state.clickThrough {
                scaleSwitcher
                    .transition(.scale(scale: 0.72).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(moveGesture)
        .accessibilityLabel(accessibilityText)
    }

    private func fullLayout(scale: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            petContent

            if hovering && !state.clickThrough {
                scaleSwitcher
                    .transition(.scale(scale: 0.72).combined(with: .opacity))
            }
        }
        .frame(width: 300, height: 280)
        .contentShape(Rectangle())
        .gesture(moveGesture)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: 300 * scale, height: 280 * scale, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var petContent: some View {
        VStack(spacing: 6) {
            quotaGlassCluster
            ApplePetView(
                window: state.snapshot?.fiveHour,
                mode: state.petScaleMode,
                reduceMotion: reduceMotion
            )
        }
        .padding(14)
        .frame(width: 300, height: 280, alignment: .bottom)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder private var quotaGlassCluster: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 18) {
                VStack(spacing: -10 + (34 * weeklyExpansion)) {
                    quotaHeader
                        .zIndex(2)
                        .glassEffectID("five-hour", in: glassNamespace)
                        .glassEffectTransition(.matchedGeometry)

                    if weeklyPresented {
                        detailPanel(expansion: weeklyExpansion)
                            .zIndex(1)
                            .glassEffectID("weekly", in: glassNamespace)
                            .glassEffectTransition(.matchedGeometry)
                    }
                }
            }
        } else {
            VStack(spacing: 16) {
                quotaHeader
                    .zIndex(2)
                if hovering {
                    detailPanel(expansion: 1)
                        .zIndex(1)
                        .transition(
                            .scale(scale: 0.16, anchor: .top)
                            .combined(with: .offset(y: -18))
                            .combined(with: .opacity)
                        )
                }
            }
        }
    }

    @MainActor
    private func animateWeeklyGlass(for isHovering: Bool) async {
        if isHovering {
            weeklyExpansion = 0
            weeklyPresented = true

            do {
                try await Task.sleep(for: .milliseconds(35))
            } catch {
                return
            }
            guard hovering else { return }

            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                weeklyExpansion = 1
            }
        } else {
            guard weeklyPresented else { return }

            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                weeklyExpansion = 0
            }

            do {
                try await Task.sleep(for: .milliseconds(310))
            } catch {
                return
            }
            guard !hovering else { return }

            withAnimation(.easeIn(duration: 0.10)) {
                weeklyPresented = false
            }
        }
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .global)
            .onChanged { value in
                guard !state.isLocked else { return }
                state.beginMovingPet(initialTranslation: value.translation)
                state.movePetToCurrentMouseLocation()
            }
            .onEnded { _ in state.endMovingPet() }
    }

    private var scaleSwitcher: some View {
        Button {
            if reduceMotion {
                state.togglePetScale()
            } else {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.80)) {
                    state.togglePetScale()
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text(state.petScaleMode.label)
                    .monospacedDigit()
            }
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .quotaLiquidGlass(tint: statusColor, cornerRadius: 13)
        }
        .buttonStyle(.plain)
        .padding(7)
        .help("点击切换 0.5x / 1x")
        .accessibilityLabel("当前宠物大小 \(state.petScaleMode.label)，点击切换")
    }

    private var quotaHeader: some View {
        VStack(spacing: 4) {
            if let window = state.snapshot?.fiveHour {
                HStack {
                    Text("5小时")
                    Spacer()
                    Text("\(Int(window.remainingPercent.rounded()))%")
                        .fontWeight(.bold)
                }
                LiquidQuotaProgress(
                    progress: window.remainingPercent / 100,
                    color: statusColor
                )
                Text("重置还有 \(window.remainingTimeDescription(at: state.now))")
                    .font(.caption)
            } else {
                Text("5小时额度暂不可用").font(.callout.weight(.semibold))
                Text(state.connectionText).font(.caption).lineLimit(1)
            }
        }
        .padding(10)
        .frame(width: 210)
        .quotaLiquidGlass(tint: statusColor, cornerRadius: 16)
    }

    private func detailPanel(expansion: CGFloat) -> some View {
        let progress = min(1, max(0, expansion))
        let width = 20 + (190 * progress)
        let expandedHeight: CGFloat = state.snapshot?.isStale == true ? 58 : 42
        let height = 20 + ((expandedHeight - 20) * progress)
        let contentOpacity = min(1, max(0, (progress - 0.34) / 0.30))

        return VStack(spacing: 3) {
            if let weekly = state.snapshot?.weekly {
                Text("周额度剩余 \(Int(weekly.remainingPercent.rounded()))%")
                Text("重置：\(weekly.resetsAt.formatted(date: .abbreviated, time: .standard))")
            } else {
                Text("周额度暂不可用")
            }
            if state.snapshot?.isStale == true { Text("数据已过期").foregroundStyle(.secondary) }
        }
        .opacity(contentOpacity)
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(width: width, height: height)
        .clipped()
        .quotaLiquidGlass(tint: statusColor, cornerRadius: 12)
    }

    private var statusColor: Color {
        guard let remaining = state.snapshot?.fiveHour?.remainingPercent else { return .gray }
        if remaining == 0 { return Color.brown.opacity(0.85) }
        if remaining <= 20 { return .red }
        if remaining <= 50 { return .yellow }
        return .green
    }

    private var accessibilityText: String {
        guard let window = state.snapshot?.fiveHour else { return "QuotaPet，5小时额度暂不可用" }
        return "QuotaPet，5小时额度剩余 \(Int(window.remainingPercent.rounded()))%，重置还有 \(window.remainingTimeDescription(at: state.now))"
    }
}
