//
//  AuraView.swift
//  Actifit
//
//  iOS port of the Android AuraView — concentric activity rings (steps /
//  distance / calories) with a Lottie animal companion in the centre. The
//  rings are drawn with CAShapeLayer; the animal is a Lottie animation whose
//  colour/asset comes from CompanionUtil and whose size scales with the tier.
//

import UIKit
import Lottie

final class AuraView: UIView {

    // Ring colours (match Android: distance #00C9B1, calories #FFB300).
    private let distColor = UIColor(red: 0x00 / 255.0, green: 0xC9 / 255.0, blue: 0xB1 / 255.0, alpha: 1)
    private let calColor = UIColor(red: 0xFF / 255.0, green: 0xB3 / 255.0, blue: 0x00 / 255.0, alpha: 1)

    private let stepTrack = CAShapeLayer(), stepProg = CAShapeLayer()
    private let distTrack = CAShapeLayer(), distProg = CAShapeLayer()
    private let calTrack = CAShapeLayer(), calProg = CAShapeLayer()
    /// Opaque disc painted in the card colour inside the innermost ring, so the
    /// centre content (step counter) reads on a clean surface instead of over the
    /// arcs (Android AuraView parity). Nil → no disc (unchanged look).
    private let centerFill = CAShapeLayer()
    var centerDiscColor: UIColor? { didSet { setNeedsLayout() } }
    private var animalView: LottieAnimationView?
    private var currentAsset: String?

    private var stepFrac: CGFloat = 0
    private var distFrac: CGFloat = 0
    private var calFrac: CGFloat = 0
    private var level = 0
    private var wilting = false
    private var companionIndex = 0

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = .clear
        centerFill.fillColor = UIColor.clear.cgColor
        layer.addSublayer(centerFill)   // sits inside the rings; rings never overlap it
        [calTrack, distTrack, stepTrack, calProg, distProg, stepProg].forEach {
            $0.fillColor = UIColor.clear.cgColor
            $0.lineCap = kCALineCapRound
            layer.addSublayer($0)
        }
    }

    func setCompanion(_ index: Int) {
        companionIndex = index
        let asset = CompanionUtil.lottieAsset(index)
        if asset != currentAsset {
            currentAsset = asset
            animalView?.removeFromSuperview()
            let v = LottieAnimationView(name: asset)
            v.loopMode = .loop
            v.contentMode = .scaleAspectFit
            v.backgroundBehavior = .pauseAndRestore
            addSubview(v)
            animalView = v
            v.play()
        }
        applyWilting()
        setNeedsLayout()
    }

    func setActivityRings(steps: CGFloat, distance: CGFloat, calories: CGFloat, level: Int, wilting: Bool) {
        stepFrac = clamp01(steps)
        distFrac = clamp01(distance)
        calFrac = clamp01(calories)
        self.level = level
        self.wilting = wilting
        applyWilting()
        setNeedsLayout()
    }

    private func clamp01(_ v: CGFloat) -> CGFloat { max(0, min(1, v)) }

    private func applyWilting() {
        animalView?.animationSpeed = wilting ? 0.3 : 1.0
        animalView?.alpha = wilting ? 0.55 : 1.0
    }

    private func auraColor() -> UIColor {
        let base = CompanionUtil.color(companionIndex)
        guard wilting else { return base }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        base.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s * 0.35, brightness: b * 0.85, alpha: a)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let R = min(bounds.width, bounds.height) / 2
        guard R > 0 else { return }
        let stroke = R * 0.085
        let gap = stroke * 2.3
        let outer = R - stroke * 0.7
        let middle = outer - gap
        let inner = middle - gap

        // Clean opaque centre in the card colour, filling the clear zone inside the
        // innermost ring so the overlaid counter text reads crisply.
        let discRadius = inner - stroke * 0.5
        if let disc = centerDiscColor, discRadius > 0 {
            centerFill.path = UIBezierPath(arcCenter: center, radius: discRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true).cgPath
            centerFill.fillColor = disc.cgColor
        } else {
            centerFill.path = nil
        }

        configureRing(track: stepTrack, progress: stepProg, center: center, radius: outer, stroke: stroke, color: auraColor(), fraction: stepFrac)
        configureRing(track: distTrack, progress: distProg, center: center, radius: middle, stroke: stroke, color: distColor, fraction: distFrac)
        configureRing(track: calTrack, progress: calProg, center: center, radius: inner, stroke: stroke, color: calColor, fraction: calFrac)

        // Animal sized by tier, positioned in the upper part of the ring (count sits
        // below it). Kept compact so it fits the clear centre without touching the inner ring.
        let size = R * (0.40 + CGFloat(level) * 0.05)
        let animalCenterY = center.y - R * 0.32
        animalView?.frame = CGRect(x: center.x - size / 2, y: animalCenterY - size / 2, width: size, height: size)
    }

    private func configureRing(track: CAShapeLayer, progress: CAShapeLayer, center: CGPoint, radius: CGFloat, stroke: CGFloat, color: UIColor, fraction: CGFloat) {
        guard radius > 0 else { track.path = nil; progress.path = nil; return }
        // Start at 12 o'clock (-90°), sweep clockwise.
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi / 2, endAngle: -.pi / 2 + 2 * .pi, clockwise: true).cgPath
        track.path = path
        track.strokeColor = color.withAlphaComponent(0.30).cgColor
        track.lineWidth = stroke
        track.strokeStart = 0; track.strokeEnd = 1
        progress.path = path
        progress.strokeColor = color.cgColor
        progress.lineWidth = stroke
        progress.strokeStart = 0
        progress.strokeEnd = fraction   // 0 → no arc (no stray dot)
    }
}
