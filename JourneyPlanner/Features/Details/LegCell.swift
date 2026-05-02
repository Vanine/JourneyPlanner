//
//  LegCell.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 31.03.2026.
//

import UIKit

final class LegCell: UITableViewCell {
    static let reuseID = "LegCell"

    private let timelineLine = UIView()
    private let timelineDotTop = UIView()
    private let timelineDotBottom = UIView()

    private let card = UIView()
    private let iconBadge = UIView()
    private let iconView = UIImageView()
    private let lineLabel = UILabel()
    private let platformLabel = UILabel()

    private let depTimeLabel = UILabel()
    private let depPlaceLabel = UILabel()
    private let arrTimeLabel = UILabel()
    private let arrPlaceLabel = UILabel()
    private let delayPill = PaddedLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        timelineLine.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        timelineLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timelineLine)

        [timelineDotTop, timelineDotBottom].forEach {
            $0.backgroundColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 1.0)
            $0.layer.cornerRadius = 5
            $0.layer.borderWidth = 2
            $0.layer.borderColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.3).cgColor
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        card.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        card.layer.cornerRadius = 18
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        iconBadge.backgroundColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.22)
        iconBadge.layer.cornerRadius = 10
        iconBadge.layer.borderWidth = 1
        iconBadge.layer.borderColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.35).cgColor
        iconBadge.translatesAutoresizingMaskIntoConstraints = false

        iconView.tintColor = .white
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBadge.addSubview(iconView)

        lineLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        lineLabel.textColor = .white

        platformLabel.font = .systemFont(ofSize: 13, weight: .medium)
        platformLabel.textColor = UIColor.white.withAlphaComponent(0.6)

        let titleStack = UIStackView(arrangedSubviews: [lineLabel, platformLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 2

        delayPill.font = .systemFont(ofSize: 12, weight: .bold)
        delayPill.textColor = .systemOrange
        delayPill.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
        delayPill.layer.cornerRadius = 8
        delayPill.layer.borderWidth = 1
        delayPill.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.4).cgColor
        delayPill.clipsToBounds = true
        delayPill.contentInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        delayPill.setContentHuggingPriority(.required, for: .horizontal)

        let headerRow = UIStackView(arrangedSubviews: [iconBadge, titleStack, UIView(), delayPill])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 12

        depTimeLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        depTimeLabel.textColor = .white
        arrTimeLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        arrTimeLabel.textColor = .white
        depPlaceLabel.font = .systemFont(ofSize: 14)
        depPlaceLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        depPlaceLabel.numberOfLines = 0
        arrPlaceLabel.font = .systemFont(ofSize: 14)
        arrPlaceLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        arrPlaceLabel.numberOfLines = 0

        let depRow = makeStopRow(time: depTimeLabel, place: depPlaceLabel)
        let arrRow = makeStopRow(time: arrTimeLabel, place: arrPlaceLabel)

        let body = UIStackView(arrangedSubviews: [headerRow, depRow, arrRow])
        body.axis = .vertical
        body.spacing = 12
        body.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(body)

        NSLayoutConstraint.activate([
            timelineLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 27),
            timelineLine.widthAnchor.constraint(equalToConstant: 2),
            timelineLine.topAnchor.constraint(equalTo: contentView.topAnchor),
            timelineLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            timelineDotTop.centerXAnchor.constraint(equalTo: timelineLine.centerXAnchor),
            timelineDotTop.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            timelineDotTop.widthAnchor.constraint(equalToConstant: 10),
            timelineDotTop.heightAnchor.constraint(equalToConstant: 10),

            timelineDotBottom.centerXAnchor.constraint(equalTo: timelineLine.centerXAnchor),
            timelineDotBottom.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            timelineDotBottom.widthAnchor.constraint(equalToConstant: 10),
            timelineDotBottom.heightAnchor.constraint(equalToConstant: 10),

            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 50),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            body.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            body.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            body.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            body.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),

            iconBadge.widthAnchor.constraint(equalToConstant: 38),
            iconBadge.heightAnchor.constraint(equalToConstant: 38),
            iconView.centerXAnchor.constraint(equalTo: iconBadge.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBadge.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func makeStopRow(time: UILabel, place: UILabel) -> UIStackView {
        time.setContentHuggingPriority(.required, for: .horizontal)
        time.widthAnchor.constraint(equalToConstant: 56).isActive = true
        let row = UIStackView(arrangedSubviews: [time, place])
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 12
        return row
    }

    func configure(with leg: Leg) {
        iconView.image = UIImage(systemName: leg.transport.symbolName)
        lineLabel.text = "\(leg.transport.displayName) · \(leg.line)"

        if let platform = leg.platform {
            platformLabel.text = "Platform \(platform)"
            platformLabel.isHidden = false
        } else {
            platformLabel.isHidden = true
        }

        depTimeLabel.text = Formatters.time.string(from: leg.departure)
        arrTimeLabel.text = Formatters.time.string(from: leg.arrival)
        depPlaceLabel.text = leg.from
        arrPlaceLabel.text = leg.to

        if leg.isDelayed {
            delayPill.isHidden = false
            delayPill.text = "+\(leg.delayMinutes) MIN"
            iconBadge.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.22)
            iconBadge.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.4).cgColor
            iconView.tintColor = .systemOrange
            depTimeLabel.textColor = .systemOrange
        } else {
            delayPill.isHidden = true
            iconBadge.backgroundColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.22)
            iconBadge.layer.borderColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.35).cgColor
            iconView.tintColor = .white
            depTimeLabel.textColor = .white
        }
    }
}
