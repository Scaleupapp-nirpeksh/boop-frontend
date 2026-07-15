import SwiftUI

struct OnboardingIntroView: View {
    @Binding var isFinished: Bool
    @State private var currentPage = 0
    @State private var appeared = false

    /// Production style is 4 — "Signature": focus-pull phrases + waveform ripple
    /// on page 1, word-by-word rise + chemistry pulse on page 2.
    /// Other styles (0 static, 1 carousel, 2 cascade, 3 chips) remain
    /// launch-selectable via BOOP_INTRO_STYLE for design review.
    private var animStyle: Int {
        Int(ProcessInfo.processInfo.environment["BOOP_INTRO_STYLE"] ?? "") ?? 4
    }

    private let pages: [IntroPage] = [
        IntroPage(
            eyebrow: "How it works",
            mark: .waveform,
            title: "Personality before pixels",
            subtitle: "On UnMutee, photos stay blurred until you both feel ready. Your voice, your words, and who you really are come first.",
            lead: "Photos stay blurred until you both feel ready.",
            phrases: ["Your voice comes first", "Your words come first", "The real you comes first"],
            pointers: [
                IntroPointer(icon: "waveform", text: "Your voice"),
                IntroPointer(icon: "text.quote", text: "Your words"),
                IntroPointer(icon: "person.crop.circle", text: "Who you really are"),
            ],
            chips: [
                IntroPointer(icon: "mic.fill", text: "Your voice"),
                IntroPointer(icon: "text.quote", text: "Your words"),
                IntroPointer(icon: "heart.fill", text: "The real you"),
            ]
        ),
        IntroPage(
            eyebrow: "No swiping",
            mark: .orbit,
            title: "Real connection, not a race",
            subtitle: "No swiping. Each day, we handpick a few people who truly match your personality. Play games, chat, and let chemistry build naturally.",
            lead: "No swiping. No endless grids.",
            phrases: ["Handpicked people, daily", "Games break the ice", "Chats go deeper", "Chemistry builds naturally"],
            pointers: [
                IntroPointer(icon: "sparkles", text: "A few handpicked people, every day"),
                IntroPointer(icon: "gamecontroller", text: "Games that break the ice"),
                IntroPointer(icon: "bubble.left.and.bubble.right", text: "Chats that build real chemistry"),
            ],
            chips: [
                IntroPointer(icon: "sparkles", text: "Handpicked daily"),
                IntroPointer(icon: "gamecontroller.fill", text: "Play games"),
                IntroPointer(icon: "bubble.left.and.bubble.right.fill", text: "Real chats"),
                IntroPointer(icon: "flame.fill", text: "Natural chemistry"),
            ]
        ),
    ]

    var body: some View {
        ZStack {
            BoopColors.ground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button {
                        withAnimation { isFinished = true }
                    } label: {
                        Text("SKIP")
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                            .foregroundStyle(BoopColors.textMuted)
                            .padding(.horizontal, BoopSpacing.md)
                            .padding(.vertical, BoopSpacing.xs)
                    }
                }
                .padding(.horizontal, BoopSpacing.md)
                .padding(.top, BoopSpacing.xs)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        introPageView(pages[index], index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                // Bottom section
                VStack(spacing: BoopSpacing.xl) {
                    // Hairline tick indicator — thin coral mark for current page
                    HStack(spacing: BoopSpacing.xs) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Rectangle()
                                .fill(index == currentPage ? BoopColors.accentColor : BoopColors.hairline)
                                .frame(width: index == currentPage ? 28 : 14, height: 2)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    BoopButton(
                        title: currentPage < pages.count - 1 ? "Continue" : "Let's go"
                    ) {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            withAnimation { isFinished = true }
                        }
                    }
                    .padding(.horizontal, BoopSpacing.xl)
                }
                .padding(.bottom, BoopSpacing.huge)
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Page View (per style)

    @ViewBuilder
    private func introPageView(_ page: IntroPage, index: Int) -> some View {
        let isActive = index == currentPage
        switch animStyle {
        case 1: CarouselIntroPage(page: page, isActive: isActive)
        case 2: CascadeIntroPage(page: page, isActive: isActive)
        case 3: ChipsIntroPage(page: page, isActive: isActive)
        case 4: SignatureIntroPage(page: page, isActive: isActive)
        default: staticPage(page)
        }
    }

    @ViewBuilder
    private func staticPage(_ page: IntroPage) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xl) {
            Spacer()

            Image(systemName: page.mark == .waveform ? "waveform" : "circle.grid.cross")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(BoopColors.accentColor)

            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: page.eyebrow)

                Text(page.title)
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                AccentRule()

                Text(page.subtitle)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xxl)
    }
}

// MARK: - Model

private struct IntroPage {
    let eyebrow: String
    let mark: IntroMark
    let title: String
    let subtitle: String
    let lead: String
    let phrases: [String]
    let pointers: [IntroPointer]
    let chips: [IntroPointer]
}

private struct IntroPointer: Identifiable {
    let icon: String
    let text: String
    var id: String { icon + text }
}

private enum IntroMark {
    case waveform, orbit
}

// MARK: - Animated marks

/// Live equalizer — the waveform bars breathe like a voice speaking.
private struct WaveformMark: View {
    let isActive: Bool
    @State private var animate = false
    private let base: [CGFloat] = [16, 32, 50, 68, 50, 32, 16]

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<base.count, id: \.self) { i in
                Capsule()
                    .fill(BoopColors.accentColor)
                    .frame(width: 3.5, height: animate ? base[(i + 3) % base.count] : base[i])
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.07),
                        value: animate
                    )
            }
        }
        .frame(height: 72, alignment: .center)
        .onAppear { if isActive { animate = true } }
        .onChange(of: isActive) { _, active in if active { animate = true } }
    }
}

/// Four thin circles in a slow orbit — people circling toward each other.
private struct OrbitMark: View {
    let isActive: Bool
    @State private var rotate = false

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(BoopColors.accentColor, lineWidth: 2)
                    .frame(width: 26, height: 26)
                    .offset(y: -27)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
        }
        .frame(width: 80, height: 80)
        .rotationEffect(.degrees(rotate ? 360 : 0))
        .animation(.linear(duration: 16).repeatForever(autoreverses: false), value: rotate)
        .onAppear { if isActive { rotate = true } }
        .onChange(of: isActive) { _, active in if active { rotate = true } }
    }
}

@ViewBuilder
private func animatedMark(_ mark: IntroMark, isActive: Bool) -> some View {
    switch mark {
    case .waveform: WaveformMark(isActive: isActive)
    case .orbit: OrbitMark(isActive: isActive)
    }
}

// MARK: - Style 1 · Phrase carousel

private struct CarouselIntroPage: View {
    let page: IntroPage
    let isActive: Bool
    @State private var idx = 0
    private let timer = Timer.publish(every: 2.4, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xl) {
            Spacer()

            animatedMark(page.mark, isActive: isActive)

            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: page.eyebrow)

                Text(page.title)
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                AccentRule()

                Text(page.lead)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                // Rotating pointer — one thought at a time, in the accent voice
                ZStack(alignment: .topLeading) {
                    Text(page.phrases[idx])
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(BoopColors.accentColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .id(idx)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
                .frame(height: 60, alignment: .topLeading)
                .clipped()
                .padding(.top, BoopSpacing.xs)

                // Tiny phrase ticks
                HStack(spacing: 6) {
                    ForEach(0..<page.phrases.count, id: \.self) { i in
                        Capsule()
                            .fill(i == idx ? BoopColors.accentColor : BoopColors.hairline)
                            .frame(width: i == idx ? 18 : 8, height: 2)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: idx)
                    }
                }
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xxl)
        .onReceive(timer) { _ in
            guard isActive else { return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                idx = (idx + 1) % page.phrases.count
            }
        }
    }
}

// MARK: - Style 2 · Staggered cascade

private struct CascadeIntroPage: View {
    let page: IntroPage
    let isActive: Bool
    @State private var step = 0

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xl) {
            Spacer()

            animatedMark(page.mark, isActive: isActive)
                .opacity(step >= 1 ? 1 : 0)
                .offset(y: step >= 1 ? 0 : 16)

            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: page.eyebrow)
                    .opacity(step >= 2 ? 1 : 0)

                Text(page.title)
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(step >= 3 ? 1 : 0)
                    .offset(y: step >= 3 ? 0 : 12)

                AccentRule(width: step >= 4 ? 44 : 0)

                Text(page.lead)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(step >= 5 ? 1 : 0)

                VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                    ForEach(Array(page.pointers.enumerated()), id: \.element.id) { i, p in
                        HStack(spacing: BoopSpacing.sm) {
                            Image(systemName: p.icon)
                                .font(.system(size: 15, weight: .thin))
                                .foregroundStyle(BoopColors.accentColor)
                                .frame(width: 24)
                            Text(p.text)
                                .font(BoopTypography.cineBody)
                                .foregroundStyle(BoopColors.textPrimary)
                        }
                        .opacity(step >= 6 + i ? 1 : 0)
                        .offset(x: step >= 6 + i ? 0 : -18)
                    }
                }
                .padding(.top, BoopSpacing.sm)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xxl)
        .onAppear { if isActive { run() } }
        .onChange(of: isActive) { _, active in
            if active { run() } else { step = 0 }
        }
    }

    private func run() {
        step = 0
        let total = 5 + page.pointers.count
        for s in 1...total {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + 0.15 * Double(s - 1)) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    if step < s { step = s }
                }
            }
        }
    }
}

// MARK: - Style 3 · Kinetic chips

private struct ChipsIntroPage: View {
    let page: IntroPage
    let isActive: Bool
    @State private var shown = false
    @State private var pulseIdx = -1
    private let pulseTimer = Timer.publish(every: 1.4, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xl) {
            Spacer()

            animatedMark(page.mark, isActive: isActive)

            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: page.eyebrow)

                Text(page.title)
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                AccentRule()

                Text(page.lead)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                // Chips pop in with a spring, then take turns pulsing
                FlowChips(chips: page.chips, shown: shown, pulseIdx: pulseIdx)
                    .padding(.top, BoopSpacing.sm)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xxl)
        .onAppear { if isActive { shown = true } }
        .onChange(of: isActive) { _, active in
            if active { shown = true } else { shown = false; pulseIdx = -1 }
        }
        .onReceive(pulseTimer) { _ in
            guard isActive, shown else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                pulseIdx = (pulseIdx + 1) % page.chips.count
            }
        }
    }
}

private struct FlowChips: View {
    let chips: [IntroPointer]
    let shown: Bool
    let pulseIdx: Int

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 150), spacing: BoopSpacing.sm, alignment: .leading)],
            alignment: .leading,
            spacing: BoopSpacing.sm
        ) {
            ForEach(Array(chips.enumerated()), id: \.element.id) { i, chip in
                HStack(spacing: 8) {
                    Image(systemName: chip.icon)
                        .font(.system(size: 13, weight: .regular))
                        .scaleEffect(pulseIdx == i ? 1.3 : 1)
                    Text(chip.text)
                        .font(BoopTypography.cineBody)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(BoopColors.accentColor)
                .padding(.horizontal, BoopSpacing.md)
                .padding(.vertical, 10)
                .overlay(
                    Capsule().stroke(
                        BoopColors.accentColor.opacity(pulseIdx == i ? 0.9 : 0.45),
                        lineWidth: 1
                    )
                )
                .opacity(shown ? 1 : 0)
                .scaleEffect(shown ? 1 : 0.7)
                .animation(
                    .spring(response: 0.45, dampingFraction: 0.65).delay(0.35 + Double(i) * 0.12),
                    value: shown
                )
            }
        }
    }
}

// MARK: - Style 4 · Signature — a distinct, meaningful transition per page.
// Page 1 (waveform): phrases arrive blurred and PULL INTO FOCUS — the app's
// blur-to-reveal mechanic told through type — while a ripple travels through
// the waveform as if the words were just spoken.
// Page 2 (orbit): phrases build WORD BY WORD with springs while the orbiting
// circles pull inward and pulse — chemistry gathering on every beat.

private struct SignatureIntroPage: View {
    let page: IntroPage
    let isActive: Bool
    @State private var idx = 0
    @State private var beat = 0
    private let timer = Timer.publish(every: 2.7, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xl) {
            Spacer()

            Group {
                switch page.mark {
                case .waveform: RippleWaveformMark(isActive: isActive, rippleTrigger: beat)
                case .orbit: PulsingOrbitMark(isActive: isActive, pulseTrigger: beat)
                }
            }

            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: page.eyebrow)

                Text(page.title)
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                AccentRule()

                Text(page.lead)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                ZStack(alignment: .topLeading) {
                    if page.mark == .waveform {
                        // Focus pull: blurred → sharp, like the photo reveal
                        Text(page.phrases[idx])
                            .font(BoopTypography.cineTitle)
                            .foregroundStyle(BoopColors.accentColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .id(idx)
                            .transition(.asymmetric(insertion: .focusIn, removal: .focusOut))
                    } else {
                        // Kinetic type: the phrase assembles word by word
                        WordRisePhrase(text: page.phrases[idx])
                            .id(idx)
                            .transition(.asymmetric(
                                insertion: .identity,
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                    }
                }
                .frame(height: 56, alignment: .topLeading)
                .padding(.top, BoopSpacing.xs)

                HStack(spacing: 6) {
                    ForEach(0..<page.phrases.count, id: \.self) { i in
                        Capsule()
                            .fill(i == idx ? BoopColors.accentColor : BoopColors.hairline)
                            .frame(width: i == idx ? 18 : 8, height: 2)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: idx)
                    }
                }
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xxl)
        .sensoryFeedback(.impact(weight: .light), trigger: idx)
        .onReceive(timer) { _ in
            guard isActive else { return }
            beat &+= 1
            withAnimation(.easeInOut(duration: 0.55)) {
                idx = (idx + 1) % page.phrases.count
            }
        }
    }
}

/// Focus-pull transition: text resolves from a blur, echoing the photo reveal.
private struct FocusModifier: ViewModifier {
    let blur: CGFloat
    let opacity: Double
    let scale: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .opacity(opacity)
            .scaleEffect(scale, anchor: .leading)
            .offset(y: y)
    }
}

private extension AnyTransition {
    static var focusIn: AnyTransition {
        .modifier(
            active: FocusModifier(blur: 14, opacity: 0, scale: 1.06, y: 8),
            identity: FocusModifier(blur: 0, opacity: 1, scale: 1, y: 0)
        )
    }

    static var focusOut: AnyTransition {
        .modifier(
            active: FocusModifier(blur: 10, opacity: 0, scale: 0.97, y: -8),
            identity: FocusModifier(blur: 0, opacity: 1, scale: 1, y: 0)
        )
    }
}

/// The phrase assembles itself one word at a time, each with a small spring.
private struct WordRisePhrase: View {
    let text: String
    @State private var shown = false

    var body: some View {
        HStack(spacing: 7) {
            ForEach(Array(text.split(separator: " ").enumerated()), id: \.offset) { i, word in
                Text(String(word))
                    .font(BoopTypography.cineTitle)
                    .foregroundStyle(BoopColors.accentColor)
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown ? 0 : 18)
                    .rotationEffect(.degrees(shown ? 0 : 5), anchor: .bottomLeading)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.72).delay(Double(i) * 0.08),
                        value: shown
                    )
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .onAppear { shown = true }
    }
}

/// Waveform that breathes continuously and RIPPLES when a phrase lands —
/// the wave travels bar-by-bar, like the words were just spoken aloud.
private struct RippleWaveformMark: View {
    let isActive: Bool
    let rippleTrigger: Int
    @State private var animate = false
    @State private var rippling = false
    private let base: [CGFloat] = [16, 32, 50, 68, 50, 32, 16]

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<base.count, id: \.self) { i in
                Capsule()
                    .fill(BoopColors.accentColor)
                    .frame(width: 3.5, height: animate ? base[(i + 3) % base.count] : base[i])
                    .scaleEffect(y: rippling ? 1.45 : 1)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.07),
                        value: animate
                    )
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.5).delay(Double(i) * 0.05),
                        value: rippling
                    )
            }
        }
        .frame(height: 76, alignment: .center)
        .onAppear { if isActive { animate = true } }
        .onChange(of: isActive) { _, active in if active { animate = true } }
        .onChange(of: rippleTrigger) { _, _ in
            rippling = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { rippling = false }
        }
    }
}

/// Orbiting circles that PULL TOWARD EACH OTHER and pulse on every beat —
/// chemistry gathering, then settling back into a slow orbit.
private struct PulsingOrbitMark: View {
    let isActive: Bool
    let pulseTrigger: Int
    @State private var rotate = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(BoopColors.accentColor, lineWidth: pulse ? 2.6 : 2)
                    .frame(width: 26, height: 26)
                    .offset(y: pulse ? -19 : -27)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
        }
        .frame(width: 80, height: 80)
        .rotationEffect(.degrees(rotate ? 360 : 0))
        .animation(.linear(duration: 16).repeatForever(autoreverses: false), value: rotate)
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: pulse)
        .onAppear { if isActive { rotate = true } }
        .onChange(of: isActive) { _, active in if active { rotate = true } }
        .onChange(of: pulseTrigger) { _, _ in
            pulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { pulse = false }
        }
    }
}

#Preview {
    OnboardingIntroView(isFinished: .constant(false))
}
