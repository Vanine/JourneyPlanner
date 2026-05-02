//
//  FavoritesViewController.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 07.04.2026.
//

import UIKit

final class FavoritesViewController: UIViewController {

    var onSelect: ((FavoriteJourney) -> Void)?

    private let viewModel: FavoritesViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let stateView = StateView()
    private var dataSource: UITableViewDiffableDataSource<Int, FavoriteJourney>!

    init(viewModel: FavoritesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.onChange = { [weak self] in self?.render() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    private func setupUI() {
        title = "Favorites"
        navigationItem.largeTitleDisplayMode = .always
        installGradientBackground()
        view.backgroundColor = .clear

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 130
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        tableView.register(FavoriteJourneyCell.self, forCellReuseIdentifier: FavoriteJourneyCell.reuseID)
        view.addSubview(tableView)

        stateView.isHidden = true
        view.addSubview(stateView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: FavoriteJourneyCell.reuseID, for: indexPath) as! FavoriteJourneyCell
            cell.configure(with: item)
            return cell
        }
    }

    private func render() {
        let items = viewModel.items
        if items.isEmpty {
            tableView.isHidden = true
            stateView.configure(.empty(
                title: "No favorites yet",
                message: "Tap the star on any route to save it here for quick access.",
                symbolName: "star"
            ))
        } else {
            stateView.isHidden = true
            tableView.isHidden = false
            var snapshot = NSDiffableDataSourceSnapshot<Int, FavoriteJourney>()
            snapshot.appendSections([0])
            snapshot.appendItems(items)
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
}

extension FavoritesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onSelect?(item)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
        let remove = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            self?.viewModel.remove(item)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            completion(true)
        }
        remove.image = UIImage(systemName: "star.slash.fill")
        return UISwipeActionsConfiguration(actions: [remove])
    }
}
