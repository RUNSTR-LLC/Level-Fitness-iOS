import UIKit

// MARK: - Grid Pattern View
class GridPatternView: UIView {
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setStrokeColor(IndustrialDesign.Colors.gridOverlay.cgColor)
        context.setLineWidth(1.0)
        context.setAlpha(1.0)
        
        let gridSpacing: CGFloat = 100.0
        
        // Draw vertical lines
        var x: CGFloat = 0
        while x <= rect.width {
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: rect.height))
            x += gridSpacing
        }
        
        // Draw horizontal lines
        var y: CGFloat = 0
        while y <= rect.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: rect.width, y: y))
            y += gridSpacing
        }
        
        context.strokePath()
    }
}

// MARK: - Rotating Gear View
class RotatingGearView: UIView {
    
    private var gearSize: CGFloat
    private var rotationAnimation: CABasicAnimation?
    
    init(size: CGFloat) {
        self.gearSize = size
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        setupGear()
        startRotation()
    }
    
    required init?(coder: NSCoder) {
        self.gearSize = 200
        super.init(coder: coder)
        setupGear()
        startRotation()
    }
    
    private func setupGear() {
        backgroundColor = .clear
        alpha = 0.02 // Very faint, as in the original design
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2.5
        let toothHeight: CGFloat = radius * 0.2
        let numberOfTeeth = 12
        
        context.setFillColor(IndustrialDesign.Colors.gearBackground.cgColor)
        context.setStrokeColor(IndustrialDesign.Colors.gearBackground.cgColor)
        context.setLineWidth(2.0)
        
        // Create gear path
        let path = createGearPath(center: center, innerRadius: radius - toothHeight, outerRadius: radius, numberOfTeeth: numberOfTeeth)
        
        context.addPath(path)
        context.fillPath()
        
        // Add inner circle (center hole)
        let innerRadius = radius * 0.3
        context.addEllipse(in: CGRect(
            x: center.x - innerRadius,
            y: center.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        ))
        context.setBlendMode(.clear)
        context.fillPath()
    }
    
    private func createGearPath(center: CGPoint, innerRadius: CGFloat, outerRadius: CGFloat, numberOfTeeth: Int) -> CGPath {
        let path = CGMutablePath()
        let angleStep = CGFloat.pi * 2 / CGFloat(numberOfTeeth)
        let toothAngle = angleStep * 0.4
        
        for i in 0..<numberOfTeeth {
            let startAngle = CGFloat(i) * angleStep
            let endAngle = startAngle + angleStep
            let toothStartAngle = startAngle + (angleStep - toothAngle) / 2
            let toothEndAngle = toothStartAngle + toothAngle
            
            // Inner arc
            if i == 0 {
                let startPoint = CGPoint(
                    x: center.x + innerRadius * cos(startAngle),
                    y: center.y + innerRadius * sin(startAngle)
                )
                path.move(to: startPoint)
            }
            
            path.addArc(
                center: center,
                radius: innerRadius,
                startAngle: startAngle,
                endAngle: toothStartAngle,
                clockwise: false
            )
            
            // Tooth
            let _ = CGPoint(
                x: center.x + innerRadius * cos(toothStartAngle),
                y: center.y + innerRadius * sin(toothStartAngle)
            )
            let toothOuterStart = CGPoint(
                x: center.x + outerRadius * cos(toothStartAngle),
                y: center.y + outerRadius * sin(toothStartAngle)
            )
            let toothOuterEnd = CGPoint(
                x: center.x + outerRadius * cos(toothEndAngle),
                y: center.y + outerRadius * sin(toothEndAngle)
            )
            let toothEnd = CGPoint(
                x: center.x + innerRadius * cos(toothEndAngle),
                y: center.y + innerRadius * sin(toothEndAngle)
            )
            
            path.addLine(to: toothOuterStart)
            path.addLine(to: toothOuterEnd)
            path.addLine(to: toothEnd)
            
            // Continue inner arc
            path.addArc(
                center: center,
                radius: innerRadius,
                startAngle: toothEndAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
        
        path.closeSubpath()
        return path
    }
    
    private func startRotation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = gearSize == 200 ? 60.0 : 90.0 // Different speeds like in HTML
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false
        
        // Reverse rotation for larger gear
        if gearSize > 250 {
            rotation.toValue = -CGFloat.pi * 2
        }
        
        layer.add(rotation, forKey: "rotationAnimation")
        self.rotationAnimation = rotation
    }
    
    override func removeFromSuperview() {
        layer.removeAllAnimations()
        super.removeFromSuperview()
    }
}

// MARK: - Animated Background Container
class IndustrialBackgroundContainer: UIView {
    
    private var gridView: GridPatternView!
    private var gears: [RotatingGearView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupIndustrialBackground()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupIndustrialBackground()
    }
    
    private func setupIndustrialBackground() {
        backgroundColor = .clear
        
        // Add grid pattern
        gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.isUserInteractionEnabled = false
        addSubview(gridView)
        
        // Add rotating gears
        let gear1 = RotatingGearView(size: 200)
        let gear2 = RotatingGearView(size: 300)
        
        gear1.translatesAutoresizingMaskIntoConstraints = false
        gear2.translatesAutoresizingMaskIntoConstraints = false
        gear1.isUserInteractionEnabled = false
        gear2.isUserInteractionEnabled = false
        
        addSubview(gear1)
        addSubview(gear2)
        
        gears = [gear1, gear2]
        
        NSLayoutConstraint.activate([
            // Grid fills entire background
            gridView.topAnchor.constraint(equalTo: topAnchor),
            gridView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Gear 1 - top right
            gear1.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            gear1.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 50),
            gear1.widthAnchor.constraint(equalToConstant: 200),
            gear1.heightAnchor.constraint(equalToConstant: 200),
            
            // Gear 2 - bottom left
            gear2.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            gear2.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -100),
            gear2.widthAnchor.constraint(equalToConstant: 300),
            gear2.heightAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    func pauseAnimations() {
        gears.forEach { $0.layer.pauseAnimation() }
    }
    
    func resumeAnimations() {
        gears.forEach { $0.layer.resumeAnimation() }
    }
}

// MARK: - CALayer Animation Extension
extension CALayer {
    func pauseAnimation() {
        let pausedTime = convertTime(CACurrentMediaTime(), from: nil)
        speed = 0.0
        timeOffset = pausedTime
    }
    
    func resumeAnimation() {
        let pausedTime = timeOffset
        speed = 1.0
        timeOffset = 0.0
        beginTime = 0.0
        let timeSincePause = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        beginTime = timeSincePause
    }
}