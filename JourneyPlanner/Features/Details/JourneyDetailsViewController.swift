//
//  JourneyDetailsViewController.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 30.03.2026.
//

import UIKit

final class JourneyDetailsViewController: UIViewController {

    private let viewModel: JourneyDetailsViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var dataSource: UITableViewDiffableDataSource<Int, Leg>!

    init(viewModel: JourneyDetailsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applySnapshot()
    }

    private func setupUI() {
        title = "Journey"
        installGradientBackground()
        view.backgroundColor = .clear

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 160
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableHeaderView = makeHeader()
        tableView.register(LegCell.self, forCellReuseIdentifier: LegCell.reuseID)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, leg in
            let cell = tableView.dequeueReusableCell(withIdentifier: LegCell.reuseID, for: indexPath) as! LegCell
            cell.configure(with: leg)
            return cell
        }
    }

    private func makeHeader() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 110))
        let title = UILabel()
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.text = viewModel.headerTitle
        title.textColor = .white
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel()
        subtitle.font = .systemFont(ofSize: 15, weight: .medium)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.6)
        subtitle.text = viewModel.headerSubtitle
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -16),
        ])
        return header
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Leg>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.legs)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
