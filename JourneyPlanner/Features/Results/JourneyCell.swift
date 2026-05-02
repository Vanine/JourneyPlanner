//
//  JourneyCell.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 27.03.2026.
//

import UIKit

final class JourneyCell: UITableViewCell {
    static let reuseID = "JourneyCell"

    private let card = GlassCardView(cornerRadius: 22)
    private let timeLabel = UILabel()
    private let arrowLabel = UILabel()
    private let arriveLabel = UILabel()
    private let durationBadge = PaddedLabel()
    private let favoriteButton = UIButton(type: .system)
    var onToggleFavorite: (() -> Void)?
    private var isFav = false
    private let modesStack = UIStackView()
    private let transfersLabel = UILabel()
    private let liveLabel = PaddedLabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    private var departure: Date?
    private var liveTimer: Timer?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(card)

        timeLabel.font = .systemFont(ofSize: 22, weight: .bold)
        timeLabel.textColor = .white
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        arrowLabel.text = "→"
        arrowLabel.font = .systemFont(ofSize: 18, weight: .medium)
        arrowLabel.textColor = UIColor.white.withAlphaComponent(0.4)
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false

        arriveLabel.font = .systemFont(ofSize: 22, weight: .bold)
        arriveLabel.textColor = .white
        arriveLabel.translatesAutoresizingMaskIntoConstraints = false

        durationBadge.font = .systemFont(ofSize: 13, weight: .semibold)
        durationBadge.textColor = .white
        durationBadge.backgroundColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.22)
        durationBadge.layer.cornerRadius = 10
        durationBadge.layer.borderWidth = 1
        durationBadge.layer.borderColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.35).cgColor
        durationBadge.clipsToBounds = true
        durationBadge.contentInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        durationBadge.translatesAutoresizingMaskIntoConstraints = false

        var favConfig = UIButton.Configuration.plain()
        favConfig.image = UIImage(systemName: "star")
        favConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        favConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        favoriteButton.configuration = favConfig
        favoriteButton.tintColor = UIColor.white.withAlphaComponent(0.4)
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        favoriteButton.accessibilityLabel = "Add to favorites"

        let topRow = UIStackView(arrangedSubviews: [timeLabel, arrowLabel, arriveLabel, UIView(), favoriteButton, durationBadge])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 8
        topRow.translatesAutoresizingMaskIntoConstraints = false

        modesStack.axis = .horizontal
        modesStack.spacing = 6
        modesStack.alignment = .center
        modesStack.translatesAutoresizingMaskIntoConstraints = false

        transfersLabel.font = .systemFont(ofSize: 13, weight: .medium)
        transfersLabel.textColor = UIColor.white.withAlphaComponent(0.6)

        chevron.tintColor = UIColor.white.withAlphaComponent(0.4)
        chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        chevron.contentMode = .center
        chevron.translatesAutoresizingMaskIntoConstraints = false

        let bottomRow = UIStackView(arrangedSubviews: [modesStack, UIView(), transfersLabel, chevron])
        bottomRow.axis = .horizontal
        bottomRow.alignment = .center
        bottomRow.spacing = 8
        bottomRow.translatesAutoresizingMaskIntoConstraints = false

        liveLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        liveLabel.textColor = .systemGreen
        liveLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
        liveLabel.layer.cornerRadius = 8
        liveLabel.clipsToBounds = true
        liveLabel.contentInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        liveLabel.translatesAutoresizingMaskIntoConstraints = false
        liveLabel.layer.borderWidth = 1
        liveLabel.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.35).cgColor
        liveLabel.setContentHuggingPriority(.required, for: .horizontal)

        let liveRow = UIStackView(arrangedSubviews: [liveLabel, UIView()])
        liveRow.axis = .horizontal

        let stack = UIStackView(arrangedSubviews: [topRow, liveRow, bottomRow])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            stack.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { liveTimer?.invalidate() }

    override func prepareForReuse() {
        super.prepareForReuse()
        liveTimer?.invalidate()
        liveTimer = nil
    }

    func configure(with journey: Journey, isFavorite: Bool = false) {
        timeLabel.text = Formatters.time.string(from: journey.departure)
        arriveLabel.text = Formatters.time.string(from: journey.arrival)
        durationBadge.text = Formatters.duration(journey.duration)
        setFavorite(isFavorite, animated: false)
        departure = journey.departure

        modesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, leg) in journey.legs.enumerated() {
            let pill = makeTransportPill(for: leg)
            modesStack.addArrangedSubview(pill)
            if i < journey.legs.count - 1 {
                let dot = UILabel()
                dot.text = "·"
                dot.textColor = UIColor.white.withAlphaComponent(0.4)
                modesStack.addArrangedSubview(dot)
            }
        }

        transfersLabel.text = journey.transferCount == 0
            ? "Direct"
            : "\(journey.transferCount) transfer\(journey.transferCount == 1 ? "" : "s")"

        startLiveUpdates()
    }

    func setFavorite(_ favorite: Bool, animated: Bool) {
        isFav = favorite
        favoriteButton.tintColor = favorite ? UIColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 1.0) : UIColor.white.withAlphaComponent(0.4)
        favoriteButton.setImage(UIImage(systemName: favorite ? "star.fill" : "star"), for: .normal)
        favoriteButton.accessibilityLabel = favorite ? "Remove from favorites" : "Add to favorites"
        if animated {
            favoriteButton.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.6, options: []) {
                self.favoriteButton.transform = .identity
            }
        }
    }

    @objc private func favoriteTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onToggleFavorite?()
    }

    private func startLiveUpdates() {
        liveTimer?.invalidate()
        updateLiveLabel()
        liveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateLiveLabel()
        }
    }

    private func updateLiveLabel() {
        guard let departure else { liveLabel.isHidden = true; return }
        let remaining = departure.timeIntervalSinceNow
        if remaining < -60 {
            liveLabel.isHidden = true
        } else if remaining < 60 {
            liveLabel.isHidden = false
            liveLabel.text = "Departing now"
            liveLabel.textColor = .systemRed
            liveLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.18)
            liveLabel.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.4).cgColor
        } else {
            liveLabel.isHidden = false
            let minutes = Int(remaining / 60)
            liveLabel.text = "Departs in \(minutes) min"
            let color: UIColor = minutes <= 5 ? .systemOrange : .systemGreen
            liveLabel.textColor = color
            liveLabel.backgroundColor = color.withAlphaComponent(0.18)
            liveLabel.layer.borderColor = color.withAlphaComponent(0.4).cgColor
        }
    }

    private func makeTransportPill(for leg: Leg) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 4
        container.alignment = .center

        let icon = UIImageView(image: UIImage(systemName: leg.transport.symbolName))
        icon.tintColor = leg.isDelayed ? .systemOrange : .white
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        icon.contentMode = .center

        let label = UILabel()
        label.text = leg.line
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = leg.isDelayed ? .systemOrange : .white

        container.addArrangedSubview(icon)
        container.addArrangedSubview(label)
        return container
    }
}

final class PaddedLabel: UILabel {
    var contentInsets: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + contentInsets.left + contentInsets.right,
                      height: size.height + contentInsets.top + contentInsets.bottom)
    }
}
