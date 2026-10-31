//
//  ExerciseSearchViewController.swift
//  Actifit
//
//  Browse the bundled exercise library (Android ExerciseSearchActivity): search by name, filter
//  by level, equipment, category and muscle, pick exercises. In browse mode the picks are saved
//  as a new workout; in select mode (from Edit Workout) they are handed back.
//

import UIKit

final class ExerciseSearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    enum Mode { case browse, select }

    private let mode: Mode
    /// Browse mode: a workout was saved.
    var onSaved: (() -> Void)?
    /// Select mode: the picked exercises.
    var onSelect: (([WorkoutExercise]) -> Void)?

    private var library: [WorkoutExercise] = []
    private var shown: [WorkoutExercise] = []
    /// Picked exercises in the order they were picked.
    private var picked: [WorkoutExercise] = []

    private var level: String?, equipment: String?, category: String?, muscle: String?

    private let search = UISearchBar()
    private let filters = UIStackView()
    private let table = UITableView(frame: .zero, style: .plain)
    private let empty = UILabel()
    private let spinner = UIActivityIndicatorView(activityIndicatorStyle: .large)
    private let actionButton = WorkoutUI.primaryButton("")

    init(mode: Mode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let bar = WorkoutUI.header(in: self, title: WorkoutText.searchTitle, back: #selector(backTapped))

        search.placeholder = WorkoutText.searchHint
        search.searchBarStyle = .minimal
        search.delegate = self
        search.autocapitalizationType = .none
        search.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(search)

        let filterScroll = UIScrollView()
        filterScroll.showsHorizontalScrollIndicator = false
        filterScroll.translatesAutoresizingMaskIntoConstraints = false
        filters.axis = .horizontal
        filters.spacing = 8
        filters.translatesAutoresizingMaskIntoConstraints = false
        filterScroll.addSubview(filters)
        view.addSubview(filterScroll)

        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        table.rowHeight = 84
        table.separatorInset = UIEdgeInsets(top: 0, left: 92, bottom: 0, right: 0)
        table.keyboardDismissMode = .onDrag
        table.register(ExerciseCell.self, forCellReuseIdentifier: ExerciseCell.id)
        table.contentInset.bottom = 90
        view.addSubview(table)

        empty.text = WorkoutText.noExercisesFound
        empty.textColor = WorkoutUI.muted
        empty.font = .systemFont(ofSize: 15)
        empty.numberOfLines = 0
        empty.textAlignment = .center
        empty.isHidden = true
        empty.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(empty)

        spinner.color = WorkoutUI.red
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.isHidden = true
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        actionButton.layer.shadowColor = UIColor.black.cgColor
        actionButton.layer.shadowOpacity = 0.2
        actionButton.layer.shadowRadius = 6
        actionButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            search.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 4),
            search.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            search.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            filterScroll.topAnchor.constraint(equalTo: search.bottomAnchor),
            filterScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterScroll.heightAnchor.constraint(equalToConstant: 44),
            filters.topAnchor.constraint(equalTo: filterScroll.contentLayoutGuide.topAnchor, constant: 4),
            filters.bottomAnchor.constraint(equalTo: filterScroll.contentLayoutGuide.bottomAnchor, constant: -4),
            filters.leadingAnchor.constraint(equalTo: filterScroll.contentLayoutGuide.leadingAnchor, constant: 16),
            filters.trailingAnchor.constraint(equalTo: filterScroll.contentLayoutGuide.trailingAnchor, constant: -16),
            filters.heightAnchor.constraint(equalTo: filterScroll.frameLayoutGuide.heightAnchor, constant: -8),
            table.topAnchor.constraint(equalTo: filterScroll.bottomAnchor, constant: 4),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            empty.centerYAnchor.constraint(equalTo: table.centerYAnchor),
            empty.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            empty.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            spinner.centerXAnchor.constraint(equalTo: table.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: table.centerYAnchor),
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        spinner.startAnimating()
        WorkoutLibrary.load { [weak self] list in
            guard let self = self else { return }
            self.spinner.stopAnimating()
            self.library = list
            self.buildFilters()
            self.applyFilters()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Filters

    private func buildFilters() {
        filters.arrangedSubviews.forEach { $0.removeFromSuperview() }
        filters.addArrangedSubview(filterChip(WorkoutText.filterLevel, ExerciseLibrary.values(library) { [$0.level ?? ""] }) { [weak self] in self?.level = $0 })
        filters.addArrangedSubview(filterChip(WorkoutText.filterEquipment, ExerciseLibrary.values(library) { [$0.equipment ?? ""] }) { [weak self] in self?.equipment = $0 })
        filters.addArrangedSubview(filterChip(WorkoutText.filterCategory, ExerciseLibrary.values(library) { [$0.category ?? ""] }) { [weak self] in self?.category = $0 })
        filters.addArrangedSubview(filterChip(WorkoutText.filterMuscle, ExerciseLibrary.values(library) { $0.primaryMuscles ?? [] }) { [weak self] in self?.muscle = $0 })
    }

    /// A chip like "Level: All" whose menu picks one value (or All).
    private func filterChip(_ caption: String, _ values: [String], set: @escaping (String?) -> Void) -> UIButton {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        b.layer.cornerRadius = 16
        b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        let name = caption.replacingOccurrences(of: ":", with: "")
        func render(_ value: String?) {
            b.setTitle(name + ": " + (value?.capitalized ?? WorkoutText.filterAll) + " ▾", for: .normal)
            b.backgroundColor = value == nil ? WorkoutUI.fill : WorkoutUI.red
            b.setTitleColor(value == nil ? WorkoutUI.ink : .white, for: .normal)
            let all = UIAction(title: WorkoutText.filterAll, state: value == nil ? .on : .off) { [weak self] _ in
                set(nil); render(nil); self?.applyFilters()
            }
            b.menu = UIMenu(title: name, children: [all] + values.map { v in
                UIAction(title: v.capitalized, state: v == value ? .on : .off) { [weak self] _ in
                    set(v); render(v); self?.applyFilters()
                }
            })
        }
        render(nil)
        b.showsMenuAsPrimaryAction = true
        return b
    }

    private func applyFilters() {
        shown = ExerciseLibrary.filter(library, text: search.text ?? "", level: level, equipment: equipment,
                                       category: category, muscle: muscle)
        table.reloadData()
        empty.isHidden = !shown.isEmpty || library.isEmpty
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { applyFilters() }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchBar.resignFirstResponder() }

    // MARK: - Table

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return shown.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ExerciseCell.id, for: indexPath) as! ExerciseCell
        let e = shown[indexPath.row]
        cell.configure(e, picked: isPicked(e))
        cell.onToggle = { [weak self] in self?.toggle(e) }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let e = shown[indexPath.row]
        if mode == .select {
            toggle(e)
        } else {
            navigationController?.pushViewController(ExerciseDetailViewController(exercise: e), animated: true)
        }
    }

    private func isPicked(_ e: WorkoutExercise) -> Bool {
        return picked.contains { $0.id == e.id && $0.name == e.name }
    }

    private func toggle(_ e: WorkoutExercise) {
        if isPicked(e) {
            picked.removeAll { $0.id == e.id && $0.name == e.name }
        } else {
            picked.append(e)
        }
        if let row = shown.firstIndex(of: e) {
            table.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
        }
        let n = picked.count
        actionButton.isHidden = n == 0
        actionButton.setTitle(mode == .select ? WorkoutText.selectedDone(n) : WorkoutText.saveWorkout + " (\(n))", for: .normal)
    }

    // MARK: - Actions

    @objc private func backTapped() { navigationController?.popViewController(animated: true) }

    @objc private func actionTapped() {
        guard !picked.isEmpty else { return }
        if mode == .select {
            onSelect?(picked)
            navigationController?.popViewController(animated: true)
        } else {
            askNameAndSave()
        }
    }

    private func askNameAndSave() {
        let names = picked.map { "• " + $0.name }.sorted().joined(separator: "\n")
        let a = UIAlertController(title: WorkoutText.newWorkoutTitle, message: names, preferredStyle: .alert)
        a.addTextField { $0.placeholder = WorkoutText.titleHint; $0.autocapitalizationType = .sentences }
        a.addTextField { $0.placeholder = WorkoutText.descriptionHint; $0.autocapitalizationType = .sentences }
        a.addAction(UIAlertAction(title: WorkoutText.cancel, style: .cancel))
        a.addAction(UIAlertAction(title: WorkoutText.saveWorkout, style: .default) { [weak self, weak a] _ in
            let title = (a?.textFields?[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            var desc = (a?.textFields?[1].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard let self = self else { return }
            guard !title.isEmpty else { return WorkoutUI.toast(self, WorkoutText.enterTitle) }
            if desc.isEmpty { desc = WorkoutText.noDescription }
            self.save(WorkoutPlan(workoutName: title, description: desc, explanation: desc, exercises: self.picked))
        })
        present(a, animated: true)
    }

    private func save(_ plan: WorkoutPlan) {
        let user = arenaCurrentUser()
        guard !user.isEmpty else { return WorkoutUI.alert(self, title: nil, message: WorkoutText.loginFirst) }
        actionButton.isEnabled = false
        WorkoutService.save(user: user, plan: plan) { [weak self] result in
            guard let self = self else { return }
            self.actionButton.isEnabled = true
            switch result {
            case .success:
                self.onSaved?()
                if let presenter = self.navigationController?.viewControllers.dropLast().last {
                    WorkoutUI.toast(presenter, WorkoutText.saved(plan.workoutName))
                }
                self.navigationController?.popViewController(animated: true)
            case .failure(let error):
                WorkoutUI.alert(self, title: nil, message: WorkoutText.saveFailed(error.text))
            }
        }
    }
}

/// A library row: picture, name, level · equipment, and a pick toggle.
private final class ExerciseCell: UITableViewCell {
    static let id = "ExerciseCell"
    var onToggle: (() -> Void)?

    private let thumb = UIImageView()
    private let name = UILabel()
    private let detail = UILabel()
    private let check = UIButton(type: .system)
    private var imageURL: URL?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        thumb.contentMode = .scaleAspectFill
        thumb.clipsToBounds = true
        thumb.layer.cornerRadius = 8
        thumb.backgroundColor = WorkoutUI.fill
        thumb.translatesAutoresizingMaskIntoConstraints = false
        name.font = .systemFont(ofSize: 15, weight: .semibold)
        name.textColor = WorkoutUI.ink
        name.numberOfLines = 2
        detail.font = .systemFont(ofSize: 12)
        detail.textColor = WorkoutUI.muted
        detail.numberOfLines = 1
        let text = UIStackView(arrangedSubviews: [name, detail])
        text.axis = .vertical
        text.spacing = 3
        text.translatesAutoresizingMaskIntoConstraints = false
        check.translatesAutoresizingMaskIntoConstraints = false
        check.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        contentView.addSubview(thumb)
        contentView.addSubview(text)
        contentView.addSubview(check)
        NSLayoutConstraint.activate([
            thumb.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumb.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumb.widthAnchor.constraint(equalToConstant: 64),
            thumb.heightAnchor.constraint(equalToConstant: 64),
            text.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12),
            text.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            text.trailingAnchor.constraint(equalTo: check.leadingAnchor, constant: -8),
            check.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            check.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            check.widthAnchor.constraint(equalToConstant: 44),
            check.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ e: WorkoutExercise, picked: Bool) {
        name.text = e.name
        detail.text = [e.level, e.equipment, e.primaryMuscles?.first].compactMap { $0 }.filter { !$0.isEmpty }
            .map { $0.capitalized }.joined(separator: " · ")
        check.setImage(UIImage(systemName: picked ? "checkmark.circle.fill" : "plus.circle"), for: .normal)
        check.tintColor = picked ? WorkoutUI.red : WorkoutUI.muted
        check.accessibilityLabel = (picked ? "Remove " : "Add ") + e.name
        thumb.image = nil
        imageURL = e.startImageURL
        if let url = imageURL {
            WorkoutImages.load(url) { [weak self] image in
                guard let self = self, self.imageURL == url else { return }   // the cell was reused
                self.thumb.image = image
            }
        }
    }

    @objc private func toggleTapped() { onToggle?() }
}
