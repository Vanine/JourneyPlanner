//
//  PrimaryButton.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 21.03.2026.
//

import UIKit

final class PrimaryButton: UIButton {

    private let gradientLayer = CAGradientLayer()

    init(title: String) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        var attr = AttributeContainer()
        attr.font = .systemFont(ofSize: 17, weight: .semibold)
        config.attributedTitle = AttributedString(title, attributes: attr)
        self.configuration = config
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true

        gradientLayer.colors = [
            UIColor(red: 0.40, green: 0.55, blue: 1.00, alpha: 1.0).cgColor,
            UIColor(red: 0.65, green: 0.40, blue: 1.00, alpha: 1.0).cgColor,
            UIColor(red: 0.95, green: 0.45, blue: 0.85, alpha: 1.0).cgColor,
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = 18
        gradientLayer.cornerCurve = .continuous
        layer.insertSublayer(gradientLayer, at: 0)
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor(red: 0.55, green: 0.45, blue: 1.0, alpha: 1.0).cgColor
        layer.shadowOpacity = 0.45
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 8)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }

    override var isEnabled: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.gradientLayer.opacity = self.isEnabled ? 1.0 : 0.35
                self.layer.shadowOpacity = self.isEnabled ? 0.45 : 0.0
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            }
        }
    }

    func setLoading(_ isLoading: Bool) {
        configuration?.showsActivityIndicator = isLoading
        isEnabled = !isLoading
    }
}
