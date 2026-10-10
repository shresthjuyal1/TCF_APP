import SwiftUI

/// The French easter eggs hidden along the path.
enum FrenchEgg: Int, CaseIterable {
    case eiffel, baguette, croissant, cheese, beret, rooster, arc, macarons
    case montSaintMichel, lighthouse, bicycle, escargot, crepe, accordion, mime

    var name: String {
        switch self {
        case .eiffel: "Eiffel Tower"
        case .baguette: "Baguette"
        case .croissant: "Croissant"
        case .cheese: "Cheese"
        case .beret: "Beret"
        case .rooster: "Rooster"
        case .arc: "Arc de Triomphe"
        case .macarons: "Macarons"
        case .montSaintMichel: "Mont-Saint-Michel"
        case .lighthouse: "Lighthouse"
        case .bicycle: "Bicycle"
        case .escargot: "Escargot"
        case .crepe: "Crêpe"
        case .accordion: "Accordion"
        case .mime: "Mime"
        }
    }
}

/// One easter egg: wiggles, bounces and spins as you tap; the 10th tap in a row
/// sets off confetti and transforms it.
struct EggView: View {
    let egg: FrenchEgg
    var size: CGFloat = 70

    @State private var taps = 0
    @State private var lastTap = Date.distantPast
    @State private var isTransformed = false
    @State private var confettiBursts: [UUID] = []

    private static let tapsForSecret = 10

    var body: some View {
        EggArt(egg: egg, isTransformed: isTransformed, size: size)
            .frame(width: size, height: size)
            .keyframeAnimator(initialValue: EggMotion(), trigger: taps) { content, motion in
                content
                    .rotationEffect(.degrees(motion.angle + motion.spin))
                    .scaleEffect(x: motion.scaleX, y: motion.scaleY, anchor: .bottom)
                    .offset(y: motion.lift)
            } keyframes: { _ in
                let (wiggle, bounce, spin) = stage
                KeyframeTrack(\.angle) {
                    SpringKeyframe(-16 * wiggle, duration: 0.08)
                    SpringKeyframe(14 * wiggle, duration: 0.1)
                    SpringKeyframe(-8 * wiggle, duration: 0.1)
                    SpringKeyframe(0, duration: 0.15)
                }
                KeyframeTrack(\.lift) {
                    SpringKeyframe(0, duration: 0.06)
                    CubicKeyframe(-46 * bounce, duration: 0.2)
                    CubicKeyframe(0, duration: 0.18)
                    SpringKeyframe(-10 * bounce, duration: 0.1)
                    SpringKeyframe(0, duration: 0.12)
                }
                KeyframeTrack(\.scaleY) {
                    SpringKeyframe(1 - 0.3 * bounce, duration: 0.06)
                    SpringKeyframe(1 + 0.15 * bounce, duration: 0.2)
                    SpringKeyframe(1 - 0.2 * bounce, duration: 0.18)
                    SpringKeyframe(1, duration: 0.2)
                }
                KeyframeTrack(\.scaleX) {
                    SpringKeyframe(1 + 0.3 * bounce, duration: 0.06)
                    SpringKeyframe(1 - 0.1 * bounce, duration: 0.2)
                    SpringKeyframe(1 + 0.2 * bounce, duration: 0.18)
                    SpringKeyframe(1, duration: 0.2)
                }
                KeyframeTrack(\.spin) {
                    CubicKeyframe(360 * spin, duration: 0.5)
                    MoveKeyframe(0)
                }
            }
            .overlay {
                ForEach(confettiBursts, id: \.self) { _ in
                    ConfettiBurst()
                        .frame(width: 340, height: 420)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: tap)
            .sensoryFeedback(.impact(weight: .light), trigger: taps)
            .accessibilityLabel(egg.name)
            .accessibilityAddTraits(.isButton)
    }

    private func tap() {
        let now = Date.now
        if now.timeIntervalSince(lastTap) > 1.5 { taps = 0 }
        lastTap = now
        taps += 1
        if taps >= Self.tapsForSecret {
            SoundFX.shared.play(.magic)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { isTransformed.toggle() }
            let burst = UUID()
            confettiBursts.append(burst)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { confettiBursts.removeAll { $0 == burst } }
            taps = 0
            lastTap = .distantPast
        } else {
            SoundFX.shared.playBoing(step: taps - 1)
        }
    }

    /// How strong each kind of motion is: taps 1–3 wiggle, 4–6 bounce, 7–9 spin.
    private var stage: (wiggle: Double, bounce: Double, spin: Double) {
        guard taps > 0 else { return (0, 0, 0) }
        switch (taps - 1) / 3 {
        case 0: return (1, 0, 0)
        case 1: return (0, 1, 0)
        default: return (0, 0, 1)
        }
    }
}

private struct EggMotion {
    var angle = 0.0
    var spin = 0.0
    var lift = 0.0
    var scaleX = 1.0
    var scaleY = 1.0
}

// MARK: - Confetti

/// A burst of blue, white and red confetti that shoots up and falls.
struct ConfettiBurst: View {
    private struct Piece {
        let velocity: CGVector
        let spin: Double
        let color: Color
        let size: CGSize
    }

    private let start = Date.now
    private let pieces: [Piece] = (0..<70).map { index in
        let angle = Double.random(in: -.pi * 0.95 ... -.pi * 0.05)
        let speed = Double.random(in: 220...520)
        let colors = [Color(hex: 0x0055A4), .white, Color(hex: 0xEF4135), Theme.gold]
        return Piece(
            velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
            spin: Double.random(in: -8...8),
            color: colors[index % colors.count],
            size: CGSize(width: Double.random(in: 6...10), height: Double.random(in: 10...16))
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                let origin = CGPoint(x: size.width / 2, y: size.height / 2)
                for piece in pieces {
                    let x = origin.x + piece.velocity.dx * t * 0.9
                    let y = origin.y + piece.velocity.dy * t + 0.5 * 900 * t * t
                    let fade = max(0, 1 - t / 2.6)
                    var pieceContext = context
                    pieceContext.opacity = fade
                    pieceContext.translateBy(x: x, y: y)
                    pieceContext.rotate(by: .radians(piece.spin * t))
                    let rect = CGRect(x: -piece.size.width / 2, y: -piece.size.height / 2,
                                      width: piece.size.width, height: piece.size.height)
                    pieceContext.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(piece.color))
                    pieceContext.stroke(Path(roundedRect: rect, cornerRadius: 2), with: .color(.black.opacity(0.08)), lineWidth: 0.5)
                }
            }
        }
    }
}

// MARK: - Artwork

/// Draws each egg, in its normal look or its secret look.
private struct EggArt: View {
    let egg: FrenchEgg
    let isTransformed: Bool
    let size: CGFloat

    var body: some View {
        switch egg {
        case .eiffel: EiffelArt(atNight: isTransformed, size: size)
        case .baguette: emoji(isTransformed ? "🥐" : "🥖")
        case .croissant: emoji("🥐").overlay(alignment: .top) { secret("👑", y: -0.38) }
        case .cheese: emoji("🧀").overlay(alignment: .bottomTrailing) { secret("🐭", x: 0.2, y: 0.1) }
        case .beret: BeretArt(tricolore: isTransformed, size: size)
        case .rooster:
            emoji("🐓").overlay(alignment: .top) {
                if isTransformed {
                    BeretArt(tricolore: false, size: size * 0.4).offset(x: -size * 0.14, y: size * 0.02)
                        .transition(.scale)
                }
            }
        case .arc: ArcArt(celebrating: isTransformed, size: size)
        case .macarons: MacaronsArt(count: isTransformed ? 6 : 3, size: size)
        case .montSaintMichel: MontSaintMichelArt(highTide: isTransformed, size: size)
        case .lighthouse: LighthouseArt(beaming: isTransformed, size: size)
        case .bicycle: emoji(isTransformed ? "🚴" : "🚲").overlay(alignment: .topTrailing) { secret("💛", x: 0.1) }
        case .escargot:
            emoji("🐌")
                .overlay(alignment: .leading) { secret("💨", x: -0.45, y: 0.12) }
                .offset(x: isTransformed ? size * 0.15 : 0)
        case .crepe: emoji(isTransformed ? "🥞" : "🫓").overlay(alignment: .top) { secret("🍓", y: -0.2) }
        case .accordion:
            emoji("🪗").overlay(alignment: .topTrailing) {
                if isTransformed {
                    Text("🎶").font(.system(size: size * 0.35))
                        .phaseAnimator([false, true]) { notes, up in notes.offset(y: up ? -size * 0.3 : -size * 0.1).opacity(up ? 0.4 : 1) }
                        animation: { _ in .easeInOut(duration: 0.9) }
                }
            }
        case .mime: MimeArt(inBox: isTransformed, size: size)
        }
    }

    private func emoji(_ text: String) -> some View {
        Text(text)
            .font(.system(size: size * 0.78))
            .shadow(color: .black.opacity(0.12), radius: 3, y: 3)
    }

    /// A small extra that appears when the egg is transformed.
    @ViewBuilder
    private func secret(_ text: String, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        if isTransformed {
            Text(text)
                .font(.system(size: size * 0.38))
                .offset(x: size * x, y: size * y)
                .transition(.scale.combined(with: .opacity))
        }
    }
}

/// Maps points drawn on a 100×100 grid into the real size.
private struct Grid {
    let rect: CGRect
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: rect.minX + x / 100 * rect.width, y: rect.minY + y / 100 * rect.height)
    }
    func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(origin: p(x, y), size: CGSize(width: w / 100 * rect.width, height: h / 100 * rect.height))
    }
}

private struct EiffelShape: Shape {
    func path(in rect: CGRect) -> Path {
        let g = Grid(rect: rect)
        var path = Path()
        // Legs with the big arch between them.
        path.move(to: g.p(16, 98))
        path.addLine(to: g.p(39, 54))
        path.addLine(to: g.p(61, 54))
        path.addLine(to: g.p(84, 98))
        path.addLine(to: g.p(69, 98))
        path.addQuadCurve(to: g.p(31, 98), control: g.p(50, 62))
        path.closeSubpath()
        path.addRoundedRect(in: g.r(28, 49, 44, 6), cornerSize: CGSize(width: 2, height: 2))
        // Middle section and second platform.
        path.move(to: g.p(40, 50))
        path.addLine(to: g.p(44.5, 27))
        path.addLine(to: g.p(55.5, 27))
        path.addLine(to: g.p(60, 50))
        path.closeSubpath()
        path.addRoundedRect(in: g.r(39, 23, 22, 5), cornerSize: CGSize(width: 1.5, height: 1.5))
        // Top and antenna.
        path.move(to: g.p(44, 24))
        path.addLine(to: g.p(50, 6))
        path.addLine(to: g.p(56, 24))
        path.closeSubpath()
        path.addRect(g.r(49, 0, 2, 8))
        return path
    }
}

private struct EiffelArt: View {
    let atNight: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            if atNight {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0x1B2A5C), Color(hex: 0x3A2C7A)], startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 1.05, height: size * 1.05)
                    .transition(.scale)
            }
            EiffelShape()
                .fill(atNight
                      ? LinearGradient(colors: [Theme.gold, Theme.orange], startPoint: .top, endPoint: .bottom)
                      : LinearGradient(colors: [Color(hex: 0xB07B48), Color(hex: 0x6E4524)], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.8, height: size * 0.9)
                .shadow(color: atNight ? Theme.gold.opacity(0.8) : .black.opacity(0.15), radius: atNight ? 8 : 2, y: atNight ? 0 : 2)
            if atNight {
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: size * 0.13, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: size * [-0.3, 0.28, -0.12, 0.18, -0.34, 0.32][index],
                                y: size * [-0.3, -0.22, -0.4, 0.05, 0.12, 0.3][index])
                        .phaseAnimator([0.2, 1]) { star, glow in star.opacity(glow).scaleEffect(glow) }
                        animation: { _ in .easeInOut(duration: 0.4 + Double(index) * 0.13) }
                }
            }
        }
    }
}

private struct BeretArt: View {
    let tricolore: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: 0x23305A))
                .frame(width: size * 0.12, height: size * 0.2)
                .offset(x: size * 0.02, y: -size * 0.2)
            Ellipse()
                .fill(tricolore
                      ? AnyShapeStyle(LinearGradient(stops: [
                          .init(color: Color(hex: 0x0055A4), location: 0), .init(color: Color(hex: 0x0055A4), location: 0.33),
                          .init(color: .white, location: 0.33), .init(color: .white, location: 0.66),
                          .init(color: Color(hex: 0xEF4135), location: 0.66), .init(color: Color(hex: 0xEF4135), location: 1),
                      ], startPoint: .leading, endPoint: .trailing))
                      : AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x34437A), Color(hex: 0x1C2648)], startPoint: .top, endPoint: .bottom)))
                .overlay(Ellipse().strokeBorder(.black.opacity(0.15), lineWidth: 1.5))
                .frame(width: size * 0.9, height: size * 0.42)
            Capsule()
                .fill(.white.opacity(0.25))
                .frame(width: size * 0.3, height: size * 0.06)
                .offset(x: -size * 0.15, y: -size * 0.09)
        }
        .rotationEffect(.degrees(-10))
        .shadow(color: .black.opacity(0.15), radius: 3, y: 3)
    }
}

private struct ArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        let g = Grid(rect: rect)
        var path = Path()
        path.addRect(g.r(14, 28, 72, 70))
        // The big central arch, cut out.
        path.move(to: g.p(38, 98))
        path.addLine(to: g.p(38, 62))
        path.addArc(center: g.p(50, 62), radius: 12 / 100 * rect.width, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: g.p(62, 98))
        path.closeSubpath()
        return path
    }
}

private struct ArcArt: View {
    let celebrating: Bool
    let size: CGFloat

    var body: some View {
        let g = size
        ZStack {
            ArcShape()
                .fill(LinearGradient(colors: [Color(hex: 0xF2E2BE), Color(hex: 0xD9BE8A)], startPoint: .top, endPoint: .bottom), style: FillStyle(eoFill: true))
            // Roof and cornice.
            Rectangle().fill(Color(hex: 0xC7A86F))
                .frame(width: g * 0.8, height: g * 0.08).offset(y: -g * 0.26)
            Rectangle().fill(Color(hex: 0xE3CB9B))
                .frame(width: g * 0.68, height: g * 0.1).offset(y: -g * 0.36)
            if celebrating {
                FlagStripes()
                    .frame(width: g * 0.2, height: g * 0.24)
                    .offset(y: g * 0.24)
                    .transition(.scale)
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "sparkles")
                        .font(.system(size: g * [0.3, 0.24, 0.2][index], weight: .bold))
                        .foregroundStyle([Color(hex: 0x0055A4), Color(hex: 0xEF4135), Theme.gold][index])
                        .offset(x: g * [-0.46, 0.46, 0.0][index], y: -g * [0.36, 0.3, 0.56][index])
                        .phaseAnimator([0.6, 1.15]) { spark, scale in spark.scaleEffect(scale) }
                        animation: { _ in .easeInOut(duration: 0.5 + Double(index) * 0.15) }
                        .transition(.scale)
                }
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.15), radius: 2, y: 2)
    }
}

/// A small French flag.
private struct FlagStripes: View {
    var body: some View {
        HStack(spacing: 0) {
            Color(hex: 0x0055A4)
            Color.white
            Color(hex: 0xEF4135)
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(.black.opacity(0.1), lineWidth: 0.5))
    }
}

private struct MacaronsArt: View {
    let count: Int
    let size: CGFloat

    private let colors: [(shell: Color, filling: Color)] = [
        (Color(hex: 0xFF8FB8), Color(hex: 0xFFF1F5)), (Color(hex: 0x9EDB8F), Color(hex: 0xF6FFF0)),
        (Color(hex: 0xB79CFF), Color(hex: 0xF6F1FF)), (Color(hex: 0xFFCF5C), Color(hex: 0xFFF8E6)),
        (Color(hex: 0x7CCBFF), Color(hex: 0xEEF8FF)),
    ]

    var body: some View {
        // Smaller macarons when the tower grows, so it still fits.
        let unit = size * (count > 3 ? 0.2 : 0.3)
        VStack(spacing: -unit * 0.12) {
            ForEach(0..<count, id: \.self) { index in
                Macaron(shell: colors[index % colors.count].shell, filling: colors[index % colors.count].filling, height: unit)
                    .offset(x: CGFloat(index % 2 == 0 ? -1 : 1) * unit * 0.12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(width: size, height: size, alignment: .bottom)
        .shadow(color: .black.opacity(0.12), radius: 2, y: 2)
    }
}

private struct Macaron: View {
    let shell: Color
    let filling: Color
    let height: CGFloat

    var body: some View {
        let width = height * 2
        VStack(spacing: 0) {
            Ellipse().fill(shell.gradient).frame(width: width, height: height * 0.5)
                .overlay(alignment: .topLeading) {
                    Capsule().fill(.white.opacity(0.45)).frame(width: width * 0.3, height: height * 0.08)
                        .offset(x: width * 0.2, y: height * 0.1)
                }
            Capsule().fill(filling).frame(width: width * 0.88, height: height * 0.2)
            Ellipse().fill(shell.gradient).frame(width: width, height: height * 0.42)
        }
    }
}

private struct MontSaintMichelArt: View {
    let highTide: Bool
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            // Rocky island with the abbey on top.
            IslandShape()
                .fill(LinearGradient(colors: [Color(hex: 0xC9B79C), Color(hex: 0x8D7B66)], startPoint: .top, endPoint: .bottom))
            Rectangle().fill(Color(hex: 0x7A6A58))
                .frame(width: size * 0.12, height: size * 0.22)
                .offset(y: -size * 0.5)
            Triangle().fill(Color(hex: 0x5F5245))
                .frame(width: size * 0.12, height: size * 0.24)
                .offset(y: -size * 0.71)
            Rectangle().fill(Theme.gold).frame(width: size * 0.02, height: size * 0.08).offset(y: -size * 0.93)
            ForEach(0..<4, id: \.self) { index in
                let x = [-0.2, 0.18, -0.08, 0.08][index]
                let y = [0.16, 0.18, 0.3, 0.32][index]
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color(hex: 0xF1E6D2))
                    .overlay(alignment: .top) { Triangle().fill(Color(hex: 0x5F5245)).frame(height: size * 0.04).offset(y: -size * 0.04) }
                    .frame(width: size * 0.09, height: size * 0.07)
                    .offset(x: size * x, y: -size * y)
            }
            // The sea comes in at high tide.
            Rectangle()
                .fill(LinearGradient(colors: [Color(hex: 0x6FC8F5).opacity(0.75), Color(hex: 0x2B8FD6).opacity(0.9)], startPoint: .top, endPoint: .bottom))
                .frame(width: size, height: size * (highTide ? 0.24 : 0.1))
                .overlay(alignment: .top) {
                    Capsule().fill(.white.opacity(0.6)).frame(width: size * 0.5, height: size * 0.025).offset(y: size * 0.02)
                }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.08))
        .shadow(color: .black.opacity(0.12), radius: 2, y: 2)
    }
}

private struct IslandShape: Shape {
    func path(in rect: CGRect) -> Path {
        let g = Grid(rect: rect)
        var path = Path()
        path.move(to: g.p(4, 100))
        path.addCurve(to: g.p(46, 42), control1: g.p(22, 88), control2: g.p(34, 52))
        path.addLine(to: g.p(54, 42))
        path.addCurve(to: g.p(96, 100), control1: g.p(66, 52), control2: g.p(78, 88))
        path.closeSubpath()
        return path
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct TowerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct LighthouseArt: View {
    let beaming: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            if beaming {
                HStack(spacing: size * 0.18) {
                    Triangle().fill(Theme.gold.opacity(0.45)).rotationEffect(.degrees(-90)).frame(width: size * 0.35, height: size * 0.6)
                    Triangle().fill(Theme.gold.opacity(0.45)).rotationEffect(.degrees(90)).frame(width: size * 0.35, height: size * 0.6)
                }
                .offset(y: -size * 0.26)
                .phaseAnimator([false, true]) { beam, on in beam.opacity(on ? 1 : 0.3) }
                animation: { _ in .easeInOut(duration: 0.6) }
            }
            VStack(spacing: 0) {
                Triangle().fill(Theme.wrong).frame(width: size * 0.3, height: size * 0.12)
                Rectangle().fill(beaming ? Theme.gold : Color(hex: 0xFFF2B8))
                    .frame(width: size * 0.2, height: size * 0.12)
                    .overlay(Rectangle().strokeBorder(Color(hex: 0x3B3B3B), lineWidth: 1.5))
                    .shadow(color: beaming ? Theme.gold : .clear, radius: 6)
                TowerShape()
                    .fill(.white)
                    .overlay {
                        VStack(spacing: size * 0.08) {
                            ForEach(0..<3, id: \.self) { _ in Rectangle().fill(Theme.wrong).frame(height: size * 0.08) }
                        }
                        .clipShape(TowerShape())
                    }
                    .frame(width: size * 0.34, height: size * 0.56)
                Capsule().fill(Color(hex: 0x8D7B66)).frame(width: size * 0.62, height: size * 0.1)
            }
            .shadow(color: .black.opacity(0.15), radius: 2, y: 2)
        }
        .frame(width: size, height: size)
    }
}

private struct MimeArt: View {
    let inBox: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: -size * 0.04) {
                ZStack {
                    Circle().fill(.white).overlay(Circle().strokeBorder(.black.opacity(0.7), lineWidth: 1.5))
                    HStack(spacing: size * 0.12) {
                        ForEach(0..<2, id: \.self) { _ in
                            VStack(spacing: size * 0.03) {
                                Capsule().fill(.black).frame(width: size * 0.09, height: size * 0.018)
                                Capsule().fill(.black).frame(width: size * 0.045, height: size * 0.07)
                            }
                        }
                    }
                    .offset(y: -size * 0.03)
                    Ellipse().fill(Theme.wrong).frame(width: size * 0.13, height: size * 0.06).offset(y: size * 0.13)
                }
                .frame(width: size * 0.5, height: size * 0.5)
                .overlay(alignment: .top) { BeretArt(tricolore: false, size: size * 0.38).offset(y: -size * 0.12) }
                RoundedRectangle(cornerRadius: size * 0.08)
                    .fill(.white)
                    .overlay {
                        VStack(spacing: size * 0.04) {
                            ForEach(0..<4, id: \.self) { _ in Rectangle().fill(.black).frame(height: size * 0.04) }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.08))
                    .frame(width: size * 0.56, height: size * 0.36)
            }
            if inBox {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Theme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    .frame(width: size * 1.05, height: size * 1.05)
                    .transition(.scale)
                Text("🖐️").font(.system(size: size * 0.28)).offset(x: -size * 0.42, y: size * 0.1).transition(.scale)
                Text("🖐️").font(.system(size: size * 0.28)).scaleEffect(x: -1).offset(x: size * 0.42, y: size * 0.1).transition(.scale)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.12), radius: 2, y: 2)
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 3), spacing: 40) {
            ForEach(FrenchEgg.allCases, id: \.self) { egg in
                VStack {
                    EggView(egg: egg)
                    Text(egg.name).font(.caption)
                }
            }
        }
        .padding(40)
    }
    .background(Theme.background)
}
