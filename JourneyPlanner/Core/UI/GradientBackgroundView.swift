//
//  GradientBackgroundView.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 12.04.2026.
//

import UIKit

// Reusable animated gradient backdrop used by all screens. Uses a base
// CAGradientLayer plus soft "glow" blobs to give a modern, depth-rich look.
final class GradientBackgroundView: UIView {

    private let baseLayer = CAGradientLayer()
    private let blobOne = CAGradientLayer()
    private let blobTwo = CAGradientLayer()
    private let blobThree = CAGradientLayer()
    private let grain = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0)

        baseLayer.colors = [
            UIColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1.0).cgColor,
            UIColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1.0).cgColor,
        ]
        baseLayer.locations = [0, 0.55, 1]
        baseLayer.startPoint = CGPoint(x: 0, y: 0)
        baseLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(baseLayer)

        configureBlob(blobOne, color: UIColor(red: 0.35, green: 0.30, blue: 0.55, alpha: 1.0))
        configureBlob(blobTwo, color: UIColor(red: 0.25, green: 0.40, blue: 0.55, alpha: 1.0))
        configureBlob(blobThree, color: UIColor(red: 0.45, green: 0.30, blue: 0.45, alpha: 1.0))

        grain.colors = [
            UIColor.black.withAlphaComponent(0.0).cgColor,
            UIColor.black.withAlphaComponent(0.35).cgColor,
        ]
        grain.locations = [0.5, 1]
        grain.startPoint = CGPoint(x: 0.5, y: 0)
        grain.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(grain)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func configureBlob(_ blob: CAGradientLayer, color: UIColor) {
        blob.type = .radial
        blob.colors = [
            color.withAlphaComponent(0.18).cgColor,
            color.withAlphaComponent(0.0).cgColor,
        ]
        blob.locations = [0, 1]
        blob.startPoint = CGPoint(x: 0.5, y: 0.5)
        blob.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(blob)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        baseLayer.frame = bounds
        grain.frame = bounds

        let w = bounds.width
        let h = bounds.height

        blobOne.frame = CGRect(x: -w * 0.25, y: -h * 0.05, width: w * 1.1, height: h * 0.6)
        blobTwo.frame = CGRect(x: w * 0.25, y: h * 0.35, width: w * 1.0, height: h * 0.55)
        blobThree.frame = CGRect(x: -w * 0.15, y: h * 0.55, width: w * 0.9, height: h * 0.55)
        CATransaction.commit()
    }
}

extension UIViewController {
    func installGradientBackground() {
        let bg = GradientBackgroundView()
        bg.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(bg, at: 0)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: view.topAnchor),
            bg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
