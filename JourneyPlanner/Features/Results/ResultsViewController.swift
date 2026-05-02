//
//  ResultsViewController.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 27.03.2026.
//

import UIKit

final class ResultsViewController: UIViewController {

    var onSelectJourney: ((Journey) -> Void)?

    private let viewModel: ResultsViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let stateView = StateView()
    private let sortControl = UISegmentedControl(items: ResultsViewModel.Sort.allCases.map(\.title))
    private let sortBar = UIView()
    private let refreshControl = UIRefreshControl()
    private var dataSource: UITableViewDiffableDataSource<Int, Journey>!

    init(viewModel: ResultsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var snapshot = dataSource.snapshot()
        if !snapshot.itemIdentifiers.isEmpty {
            snapshot.reconfigureItems(snapshot.itemIdentifiers)
            dataSource.apply(snapshot, animatingDifferences: false)
        }
    }

    private func setupUI() {
        title = "\(viewModel.origin.name) → \(viewModel.destination.name)"
        navigationItem.largeTitleDisplayMode = .never
        installGradientBackground()
        view.backgroundColor = .clear

        sortBar.translatesAutoresizingMaskIntoConstraints = false
        sortBar.backgroundColor = .clear
        sortControl.selectedSegmentIndex = viewModel.sort.rawValue
        sortControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.18)
        sortControl.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        sortControl.setTitleTextAttributes([.foregroundColor: UIColor.white.withAlphaComponent(0.6)], for: .normal)
        sortControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        sortControl.addTarget(self, action: #selector(sortChanged), for: .valueChanged)
        sortControl.translatesAutoresizingMaskIntoConstraints = false
        sortBar.addSubview(sortControl)
        view.addSubview(sortBar)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 140
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        tableView.register(JourneyCell.self, forCellReuseIdentifier: JourneyCell.reuseID)
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)

        stateView.isHidden = true
        view.addSubview(stateView)

        NSLayoutConstraint.activate([
            sortBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sortBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sortBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sortBar.heightAnchor.constraint(equalToConstant: 52),

            sortControl.leadingAnchor.constraint(equalTo: sortBar.leadingAnchor, constant: 16),
            sortControl.trailingAnchor.constraint(equalTo: sortBar.trailingAnchor, constant: -16),
            sortControl.centerYAnchor.constraint(equalTo: sortBar.centerYAnchor),

            tableView.topAnchor.constraint(equalTo: sortBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stateView.topAnchor.constraint(equalTo: sortBar.bottomAnchor),
            stateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, journey in
            let cell = tableView.dequeueReusableCell(withIdentifier: JourneyCell.reuseID, for: indexPath) as! JourneyCell
            cell.configure(with: journey, isFavorite: self?.viewModel.isFavorite(journey) ?? false)
            cell.onToggleFavorite = { [weak self, weak cell] in
                guard let self, let cell else { return }
                let nowFav = self.viewModel.toggleFavorite(journey)
                cell.setFavorite(nowFav, animated: true)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            return cell
        }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    private func render(_ state: ResultsViewModel.State) {
        refreshControl.endRefreshing()
        switch state {
        case .loading:
            tableView.isHidden = true
            sortBar.isHidden = true
            stateView.configure(.loading)
        case .loaded(let journeys):
            stateView.isHidden = true
            tableView.isHidden = false
            sortBar.isHidden = false
            var snapshot = NSDiffableDataSourceSnapshot<Int, Journey>()
            snapshot.appendSections([0])
            snapshot.appendItems(journeys)
            dataSource.apply(snapshot, animatingDifferences: true)
        case .empty:
            tableView.isHidden = true
            sortBar.isHidden = true
            stateView.configure(.empty(
                title: "No routes found",
                message: "Try a different combination of origin and destination.",
                symbolName: "tram.tunnel.fill"
            ))
        case .error(let message):
            tableView.isHidden = true
            sortBar.isHidden = true
            stateView.configure(.error(
                title: "Something went wrong",
                message: message,
                retryHandler: { [weak self] in self?.viewModel.load() }
            ))
        }
    }

    @objc private func sortChanged() {
        guard let new = ResultsViewModel.Sort(rawValue: sortControl.selectedSegmentIndex) else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        viewModel.setSort(new)
    }

    @objc private func pullToRefresh() {
        viewModel.load(showLoading: false)
    }

    private func reloadCell(for journey: Journey) {
        var snapshot = dataSource.snapshot()
        if snapshot.indexOfItem(journey) != nil {
            snapshot.reconfigureItems([journey])
            dataSource.apply(snapshot, animatingDifferences: false)
        }
    }

    private func shareJourney(_ journey: Journey) {
        let body = """
        Journey from \(viewModel.origin.name) to \(viewModel.destination.name)
        \(Formatters.time.string(from: journey.departure)) – \(Formatters.time.string(from: journey.arrival)) (\(Formatters.duration(journey.duration)))
        \(journey.transferCount == 0 ? "Direct" : "\(journey.transferCount) transfer(s)")
        """
        let vc = UIActivityViewController(activityItems: [body], applicationActivities: nil)
        present(vc, animated: true)
    }
}

extension ResultsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let journey = dataSource.itemIdentifier(for: indexPath) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onSelectJourney?(journey)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let journey = dataSource.itemIdentifier(for: indexPath) else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self else { return nil }
            let isFav = self.viewModel.isFavorite(journey)
            let favorite = UIAction(
                title: isFav ? "Remove Favorite" : "Add to Favorites",
                image: UIImage(systemName: isFav ? "star.slash" : "star")
            ) { _ in
                _ = self.viewModel.toggleFavorite(journey)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.reloadCell(for: journey)
            }
            let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { _ in
                self.shareJourney(journey)
            }
            return UIMenu(title: "", children: [favorite, share])
        }
    }
}
