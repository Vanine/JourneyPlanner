//
//  FavoriteJourneyCell.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 07.04.2026.
//

import UIKit

final class FavoriteJourneyCell: UITableViewCell {
    static let reuseID = "FavoriteJourneyCell"

    private let card = GlassCardView(cornerRadius: 22)
    private let routeLabel = UILabel()
    private let timeLabel = UILabel()
    private let durationBadge = PaddedLabel()
    private let modesStack = UIStackView()
    private let savedAtLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(card)

        let star = UIImageView(image: UIImage(systemName: "star.fill"))
        star.tintColor = UIColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 1.0)
        star.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        star.contentMode = .center
        star.setContentHuggingPriority(.required, for: .horizontal)

        routeLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        routeLabel.textColor = .white
        routeLabel.numberOfLines = 1
        routeLabel.lineBreakMode = .byTruncatingMiddle

        let titleRow = UIStackView(arrangedSubviews: [star, routeLabel])
        titleRow.axis = .horizontal
        titleRow.spacing = 6
        titleRow.alignment = .center

        timeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.6)

        durationBadge.font = .systemFont(ofSize: 12, weight: .semibold)
        durationBadge.textColor = .white
        durationBadge.backgroundColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.22)
        durationBadge.layer.cornerRadius = 8
        durationBadge.layer.borderWidth = 1
        durationBadge.layer.borderColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.35).cgColor
        durationBadge.clipsToBounds = true
        durationBadge.contentInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
        durationBadge.setContentHuggingPriority(.required, for: .horizontal)

        let middleRow = UIStackView(arrangedSubviews: [timeLabel, UIView(), durationBadge])
        middleRow.axis = .horizontal
        middleRow.alignment = .center
        middleRow.spacing = 8

        modesStack.axis = .horizontal
        modesStack.spacing = 6
        modesStack.alignment = .center

        savedAtLabel.font = .systemFont(ofSize: 12, weight: .regular)
        savedAtLabel.textColor = UIColor.white.withAlphaComponent(0.45)

        chevron.tintColor = UIColor.white.withAlphaComponent(0.4)
        chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevron.contentMode = .center

        let bottomRow = UIStackView(arrangedSubviews: [modesStack, UIView(), savedAtLabel, chevron])
        bottomRow.axis = .horizontal
        bottomRow.alignment = .center
        bottomRow.spacing = 6

        let stack = UIStackView(arrangedSubviews: [titleRow, middleRow, bottomRow])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            stack.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -14),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: FavoriteJourney) {
        routeLabel.text = "\(item.origin.name) → \(item.destination.name)"
        timeLabel.text = "\(Formatters.time.string(from: item.journey.departure)) – \(Formatters.time.string(from: item.journey.arrival))"
        durationBadge.text = Formatters.duration(item.journey.duration)
        savedAtLabel.text = Formatters.relative(item.savedAt)

        modesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, leg) in item.journey.legs.enumerated() {
            let icon = UIImageView(image: UIImage(systemName: leg.transport.symbolName))
            icon.tintColor = UIColor.white.withAlphaComponent(0.7)
            icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            icon.contentMode = .center
            let label = UILabel()
            label.text = leg.line
            label.font = .systemFont(ofSize: 12, weight: .semibold)
            label.textColor = UIColor.white.withAlphaComponent(0.7)
            let pill = UIStackView(arrangedSubviews: [icon, label])
            pill.spacing = 3
            pill.alignment = .center
            modesStack.addArrangedSubview(pill)
            if i < item.journey.legs.count - 1 {
                let dot = UILabel()
                dot.text = "·"
                dot.textColor = UIColor.white.withAlphaComponent(0.4)
                modesStack.addArrangedSubview(dot)
            }
        }
    }
}
