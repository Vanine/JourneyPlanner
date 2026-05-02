//
//  RoundedTextField.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 21.03.2026.
//

import UIKit

final class RoundedTextField: UITextField {

    private let iconView = UIImageView()
    private let horizontalInset: CGFloat = 16
    private let iconSize: CGFloat = 20
    private let iconTextSpacing: CGFloat = 12

    init(placeholder: String, symbolName: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.45)]
        )
        font = .systemFont(ofSize: 17, weight: .regular)
        textColor = .white
        backgroundColor = UIColor.white.withAlphaComponent(0.06)
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        autocorrectionType = .no
        autocapitalizationType = .words
        clearButtonMode = .whileEditing
        returnKeyType = .search
        keyboardAppearance = .dark

        let config = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .medium)
        iconView.image = UIImage(systemName: symbolName, withConfiguration: config)
        iconView.tintColor = UIColor.white.withAlphaComponent(0.7)
        iconView.contentMode = .scaleAspectFit
        leftView = iconView
        leftViewMode = .always

        heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(
            x: bounds.minX + horizontalInset,
            y: bounds.midY - iconSize / 2,
            width: iconSize,
            height: iconSize
        )
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let leftPadding = horizontalInset + iconSize + iconTextSpacing
        return CGRect(
            x: bounds.minX + leftPadding,
            y: bounds.minY,
            width: bounds.width - leftPadding - horizontalInset,
            height: bounds.height
        )
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }

    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.clearButtonRect(forBounds: bounds)
        return rect.offsetBy(dx: -(horizontalInset - 8), dy: 0)
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        UIView.animate(withDuration: 0.2) {
            self.layer.borderColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.6).cgColor
            self.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        UIView.animate(withDuration: 0.2) {
            self.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
            self.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        }
        return result
    }
}
