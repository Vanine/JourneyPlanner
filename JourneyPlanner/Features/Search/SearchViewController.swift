//
//  SearchViewController.swift
//  JourneyPlanner
//
//  Created by Vanine Ghazaryan on 24.03.2026.
//

import UIKit

final class SearchViewController: UIViewController {

    var onSearch: ((Location, Location) -> Void)?
    var onShowFavorites: (() -> Void)?

    private let viewModel: SearchViewModel

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let cardView = GlassCardView(cornerRadius: 24)
    private let fromField = RoundedTextField(placeholder: "From", symbolName: "location.circle.fill")
    private let toField = RoundedTextField(placeholder: "To", symbolName: "mappin.circle.fill")
    private let swapButton = UIButton(type: .system)

    private let searchButton = PrimaryButton(title: "Find Routes")
    private let suggestionsTable = UITableView(frame: .zero, style: .plain)

    private let recentsHeader = UIView()
    private let recentsTitle = UILabel()
    private let recentsClearButton = UIButton(type: .system)
    private let recentsStack = UIStackView()

    private var dataSource: UITableViewDiffableDataSource<Int, Location>!
    private var suggestionsTableHeight: NSLayoutConstraint?
    // The field the currently-visible suggestion list belongs to. Captured at
    // snapshot-apply time so that picking a row can never silently mutate the
    // "other" field, even if first-responder state has shifted in the meantime.
    private var suggestionsField: SearchViewModel.Field?

    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        renderRecents()
    }

    private func setupUI() {
        title = "Plan a Journey"
        navigationItem.largeTitleDisplayMode = .always
        installGradientBackground()
        view.backgroundColor = .clear

        let favItem = UIBarButtonItem(
            image: UIImage(systemName: "star.fill"),
            style: .plain,
            target: self,
            action: #selector(favoritesTapped)
        )
        favItem.tintColor = UIColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 1.0)
        favItem.accessibilityLabel = "Favorites"
        navigationItem.rightBarButtonItem = favItem

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.backgroundColor = .clear
        // Without this, taps on the recent rows (UIControl inside the stack)
        // are delayed by the scroll view and frequently get swallowed.
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        let fieldsStack = UIStackView(arrangedSubviews: [fromField, toField])
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 10
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.contentView.addSubview(fieldsStack)

        var swapConfig = UIButton.Configuration.filled()
        swapConfig.image = UIImage(systemName: "arrow.up.arrow.down")
        swapConfig.baseBackgroundColor = UIColor.white.withAlphaComponent(0.12)
        swapConfig.baseForegroundColor = .white
        swapConfig.cornerStyle = .capsule
        swapButton.configuration = swapConfig
        swapButton.translatesAutoresizingMaskIntoConstraints = false
        swapButton.layer.borderWidth = 1
        swapButton.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        swapButton.addTarget(self, action: #selector(swapTapped), for: .touchUpInside)
        cardView.contentView.addSubview(swapButton)

        fromField.addTarget(self, action: #selector(fromChanged), for: .editingChanged)
        toField.addTarget(self, action: #selector(toChanged), for: .editingChanged)
        fromField.addTarget(self, action: #selector(fromBegan), for: .editingDidBegin)
        toField.addTarget(self, action: #selector(toBegan), for: .editingDidBegin)
        fromField.delegate = self
        toField.delegate = self

        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        searchButton.isEnabled = false

        suggestionsTable.translatesAutoresizingMaskIntoConstraints = false
        suggestionsTable.backgroundColor = UIColor.white.withAlphaComponent(0.04)
        suggestionsTable.separatorColor = UIColor.white.withAlphaComponent(0.08)
        suggestionsTable.separatorInset = UIEdgeInsets(top: 0, left: 56, bottom: 0, right: 0)
        suggestionsTable.rowHeight = 64
        suggestionsTable.delegate = self
        suggestionsTable.register(LocationCell.self, forCellReuseIdentifier: LocationCell.reuseID)
        suggestionsTable.isScrollEnabled = false
        suggestionsTable.layer.cornerRadius = 18
        suggestionsTable.layer.cornerCurve = .continuous
        suggestionsTable.layer.borderWidth = 1
        suggestionsTable.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        suggestionsTable.clipsToBounds = true

        configureDataSource()
        setupRecentsSection()

        contentStack.addArrangedSubview(cardView)
        contentStack.addArrangedSubview(searchButton)
        contentStack.addArrangedSubview(suggestionsTable)
        contentStack.addArrangedSubview(recentsHeader)
        contentStack.addArrangedSubview(recentsStack)
        contentStack.setCustomSpacing(24, after: cardView)
        contentStack.setCustomSpacing(8, after: recentsHeader)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),

            fieldsStack.topAnchor.constraint(equalTo: cardView.contentView.topAnchor, constant: 18),
            fieldsStack.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor, constant: 18),
            fieldsStack.trailingAnchor.constraint(equalTo: cardView.contentView.trailingAnchor, constant: -68),
            fieldsStack.bottomAnchor.constraint(equalTo: cardView.contentView.bottomAnchor, constant: -18),

            swapButton.centerYAnchor.constraint(equalTo: cardView.contentView.centerYAnchor),
            swapButton.trailingAnchor.constraint(equalTo: cardView.contentView.trailingAnchor, constant: -16),
            swapButton.widthAnchor.constraint(equalToConstant: 44),
            swapButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func setupRecentsSection() {
        recentsHeader.translatesAutoresizingMaskIntoConstraints = false
        recentsTitle.text = "RECENT"
        recentsTitle.font = .systemFont(ofSize: 12, weight: .heavy)
        recentsTitle.textColor = UIColor.white.withAlphaComponent(0.55)
        recentsTitle.translatesAutoresizingMaskIntoConstraints = false

        var clearConfig = UIButton.Configuration.plain()
        clearConfig.title = "Clear"
        clearConfig.baseForegroundColor = .tintColor
        clearConfig.contentInsets = .zero
        recentsClearButton.configuration = clearConfig
        recentsClearButton.translatesAutoresizingMaskIntoConstraints = false
        recentsClearButton.addTarget(self, action: #selector(clearRecentsTapped), for: .touchUpInside)

        recentsHeader.addSubview(recentsTitle)
        recentsHeader.addSubview(recentsClearButton)

        NSLayoutConstraint.activate([
            recentsTitle.leadingAnchor.constraint(equalTo: recentsHeader.leadingAnchor, constant: 4),
            recentsTitle.centerYAnchor.constraint(equalTo: recentsHeader.centerYAnchor),
            recentsClearButton.trailingAnchor.constraint(equalTo: recentsHeader.trailingAnchor, constant: -4),
            recentsClearButton.centerYAnchor.constraint(equalTo: recentsHeader.centerYAnchor),
            recentsHeader.heightAnchor.constraint(equalToConstant: 28),
        ])

        recentsStack.axis = .vertical
        recentsStack.spacing = 8
        recentsStack.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: suggestionsTable) { tableView, indexPath, location in
            let cell = tableView.dequeueReusableCell(withIdentifier: LocationCell.reuseID, for: indexPath) as! LocationCell
            cell.configure(with: location)
            return cell
        }
        applySnapshot([], for: nil)
    }

    private func applySnapshot(_ items: [Location], for field: SearchViewModel.Field?) {
        suggestionsField = items.isEmpty ? nil : field
        var snapshot = NSDiffableDataSourceSnapshot<Int, Location>()
        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true)
        let height = CGFloat(items.count) * suggestionsTable.rowHeight
        suggestionsTableHeight?.isActive = false
        let constraint = suggestionsTable.heightAnchor.constraint(equalToConstant: height)
        constraint.isActive = true
        suggestionsTableHeight = constraint
        suggestionsTable.isHidden = items.isEmpty
        renderRecents()
    }

    private func renderRecents() {
        recentsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let show = viewModel.showsRecents
        recentsHeader.isHidden = !show
        recentsStack.isHidden = !show
        guard show else { return }
        for recent in viewModel.recentSearches {
            recentsStack.addArrangedSubview(makeRecentRow(recent))
        }
    }

    private func makeRecentRow(_ recent: RecentSearch) -> UIView {
        let row = UIControl()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        row.layer.cornerRadius = 16
        row.layer.cornerCurve = .continuous
        row.layer.borderWidth = 1
        row.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor

        let icon = UIImageView(image: UIImage(systemName: "clock.arrow.circlepath"))
        icon.tintColor = UIColor.white.withAlphaComponent(0.7)
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        icon.contentMode = .center
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "\(recent.origin.name) → \(recent.destination.name)"
        title.font = .systemFont(ofSize: 15, weight: .semibold)
        title.textColor = .white
        title.numberOfLines = 1

        let subtitle = UILabel()
        subtitle.text = recent.origin.subtitle
        subtitle.font = .systemFont(ofSize: 12, weight: .regular)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.55)
        subtitle.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "arrow.up.right"))
        chevron.tintColor = UIColor.white.withAlphaComponent(0.4)
        chevron.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevron.contentMode = .center
        chevron.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(icon)
        row.addSubview(textStack)
        row.addSubview(chevron)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 56),
            icon.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),

            textStack.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            textStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])

        // Single tap recogniser. Using only one handler avoids the double-fire
        // we previously hit (UIControl action + gesture) which could swallow or
        // duplicate the tap depending on how the scroll view dispatched it.
        let tap = UITapGestureRecognizer(target: self, action: #selector(recentRowTapped(_:)))
        tap.cancelsTouchesInView = false
        row.addGestureRecognizer(tap)
        objc_setAssociatedObject(row, &Self.recentKey, recent, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return row
    }

    private func bindViewModel() {
        viewModel.onSuggestionsChanged = { [weak self] in
            guard let self else { return }
            self.applySnapshot(self.viewModel.suggestions, for: self.viewModel.activeField)
        }
        viewModel.onSelectionChanged = { [weak self] in
            guard let self else { return }
            self.fromField.text = self.viewModel.origin?.name
            self.toField.text = self.viewModel.destination?.name
            self.searchButton.isEnabled = self.viewModel.canSearch
        }
        viewModel.onRecentsChanged = { [weak self] in
            self?.renderRecents()
        }
    }

    @objc private func fromBegan() { viewModel.update(field: .from, query: fromField.text ?? "") }
    @objc private func toBegan() { viewModel.update(field: .to, query: toField.text ?? "") }
    @objc private func fromChanged() { viewModel.update(field: .from, query: fromField.text ?? "") }
    @objc private func toChanged() { viewModel.update(field: .to, query: toField.text ?? "") }

    @objc private func swapTapped() {
        viewModel.swap()
        UISelectionFeedbackGenerator().selectionChanged()
    }

    @objc private func clearRecentsTapped() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        viewModel.clearRecents()
    }

    private static var recentKey: UInt8 = 0

    @objc private func recentRowTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view,
              let recent = objc_getAssociatedObject(view, &Self.recentKey) as? RecentSearch else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        self.view.endEditing(true)
        viewModel.applyRecent(recent)
    }

    @objc private func favoritesTapped() {
        UISelectionFeedbackGenerator().selectionChanged()
        onShowFavorites?()
    }

    @objc private func searchTapped() {
        guard let from = viewModel.origin, let to = viewModel.destination else { return }
        view.endEditing(true)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onSearch?(from, to)
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        // Resolve the destination field BEFORE ending editing — resigning the
        // first responder can otherwise change which field is active and cause
        // the value to land on the wrong side.
        let field = suggestionsField ?? viewModel.activeField
        view.endEditing(true)
        viewModel.select(item, into: field)
    }
}

extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === fromField {
            _ = toField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            if viewModel.canSearch { searchTapped() }
        }
        return true
    }
}
