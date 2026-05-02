//
//  GlassCardView.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 12.04.2026.
//

import UIKit

// Translucent "glass" card built on top of UIVisualEffectView so the gradient
// background shows through. A subtle hairline border + inner highlight gives
// the modern frosted-glass aesthetic.
final class GlassCardView: UIView {

    let contentView = UIView()
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let tint = UIView()
    private let highlight = CAGradientLayer()

    init(cornerRadius: CGFloat = 22) {
        super.init(frame: .zero)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        clipsToBounds = false

        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.layer.cornerRadius = cornerRadius
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        addSubview(blur)

        tint.translatesAutoresizingMaskIntoConstraints = false
        tint.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        tint.layer.cornerRadius = cornerRadius
        tint.layer.cornerCurve = .continuous
        tint.layer.borderWidth = 1
        tint.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        tint.isUserInteractionEnabled = false
        addSubview(tint)

        highlight.colors = [
            UIColor.white.withAlphaComponent(0.18).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor,
        ]
        highlight.locations = [0, 1]
        highlight.startPoint = CGPoint(x: 0.5, y: 0)
        highlight.endPoint = CGPoint(x: 0.5, y: 0.6)
        highlight.cornerRadius = cornerRadius
        tint.layer.addSublayer(highlight)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        addSubview(contentView)

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 10)

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),

            tint.topAnchor.constraint(equalTo: topAnchor),
            tint.leadingAnchor.constraint(equalTo: leadingAnchor),
            tint.trailingAnchor.constraint(equalTo: trailingAnchor),
            tint.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        highlight.frame = bounds
        CATransaction.commit()
    }
}
