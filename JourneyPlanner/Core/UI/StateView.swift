//
//  StateView.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 21.03.2026.
//

import UIKit

// Reusable empty / error / loading view used by Results and Details screens.
final class StateView: UIView {

    enum State {
        case loading
        case empty(title: String, message: String, symbolName: String)
        case error(title: String, message: String, retryHandler: (() -> Void)?)
    }

    private let stack = UIStackView()
    private let symbolView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let activity = UIActivityIndicatorView(style: .large)
    private let retryButton = PrimaryButton(title: "Try Again")
    private var retryHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        symbolView.tintColor = UIColor.white.withAlphaComponent(0.5)
        symbolView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)
        symbolView.contentMode = .center

        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.font = .systemFont(ofSize: 15, weight: .regular)
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        stack.addArrangedSubview(activity)
        stack.addArrangedSubview(symbolView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(messageLabel)
        stack.addArrangedSubview(retryButton)
        stack.setCustomSpacing(20, after: symbolView)
        stack.setCustomSpacing(8, after: titleLabel)
        stack.setCustomSpacing(24, after: messageLabel)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
            retryButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ state: State) {
        isHidden = false
        switch state {
        case .loading:
            activity.isHidden = false
            activity.color = .white
        activity.startAnimating()
            symbolView.isHidden = true
            titleLabel.isHidden = true
            messageLabel.isHidden = true
            retryButton.isHidden = true
        case .empty(let title, let message, let symbol):
            activity.stopAnimating()
            activity.isHidden = true
            symbolView.isHidden = false
            symbolView.image = UIImage(systemName: symbol)
            titleLabel.isHidden = false
            titleLabel.text = title
            messageLabel.isHidden = false
            messageLabel.text = message
            retryButton.isHidden = true
        case .error(let title, let message, let handler):
            activity.stopAnimating()
            activity.isHidden = true
            symbolView.isHidden = false
            symbolView.image = UIImage(systemName: "wifi.exclamationmark")
            titleLabel.isHidden = false
            titleLabel.text = title
            messageLabel.isHidden = false
            messageLabel.text = message
            retryButton.isHidden = handler == nil
            retryHandler = handler
        }
    }

    @objc private func retryTapped() { retryHandler?() }
}
