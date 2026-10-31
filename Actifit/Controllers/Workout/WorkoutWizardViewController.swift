//
//  WorkoutWizardViewController.swift
//  Actifit
//
//  The AI Workout Wizard (Android WorkoutWizardActivity): the user's saved workouts, and a form
//  that generates a new plan with Gemini for a 300 AFIT fee signed on the device.
//
//  Payment rules (as on Android): a fee that went through but whose plan was never generated
//  makes the next Generate free; an unconfirmed fee is settled, never paid a second time.
//

import UIKit

final class WorkoutWizardViewController: UIViewController {

    private var user = ""
    private var workouts: [WorkoutPlan] = []
    private var busy = false

    private var stack: UIStackView!
    private let savedChevron = UIImageView()
    private let savedContent = UIStackView()
    private let savedList = UIStackView()
    private let savedSpinner = UIActivityIndicatorView(activityIndicatorStyle: .medium)
    private let savedMessage = UILabel()
    private let retryButton = WorkoutUI.outlineButton(WorkoutText.retryLoading)

    private let generateChevron = UIImageView()
    private let generateContent = UIStackView()
    private let nameField = WorkoutUI.field(WorkoutText.workoutNameHint)
    private let otherField = WorkoutUI.field(WorkoutText.otherLimitationsHint)
    private let generateButton = WorkoutUI.primaryButton(WorkoutText.generate)

    private let busyOverlay = UIView()
    private let busyLabel = UILabel()

    private var request = WorkoutRequest(fitnessGoal: WorkoutOptions.fitnessGoals[0],
                                         experienceLevel: WorkoutOptions.experienceLevels[0],
                                         weeklyTime: WorkoutOptions.weeklyTimes[0],
                                         preferredWorkout: WorkoutOptions.workoutStyles[0],
                                         equipment: WorkoutOptions.equipment[0],
                                         limitations: WorkoutOptions.limitations[0],
                                         otherLimitations: "",
                                         dailyFrequency: WorkoutOptions.defaultFrequency)

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        user = arenaCurrentUser()
        buildUI()
        updateGenerateTitle()
        WorkoutLibrary.load { _ in }   // warm the library for illustrating plans
        loadWorkouts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        updateGenerateTitle()
    }

    // MARK: - Layout

    private func buildUI() {
        let browse = UIButton(type: .system)
        browse.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        browse.accessibilityLabel = WorkoutText.browseExercises
        browse.addTarget(self, action: #selector(browseTapped), for: .touchUpInside)
        let bar = WorkoutUI.header(in: self, title: WorkoutText.screenTitle, back: #selector(backTapped), trailing: browse)
        let (_, stack) = WorkoutUI.scrollStack(in: view, below: bar)
        self.stack = stack

        let browseRow = WorkoutUI.outlineButton("🔍  " + WorkoutText.browseExercises)
        browseRow.addTarget(self, action: #selector(browseTapped), for: .touchUpInside)
        stack.addArrangedSubview(browseRow)

        // Saved workouts
        let (savedCard, savedStack) = WorkoutUI.card()
        savedStack.addArrangedSubview(sectionHeader("📋  " + WorkoutText.savedWorkouts, chevron: savedChevron,
                                                    action: #selector(toggleSaved)))
        savedContent.axis = .vertical
        savedContent.spacing = 10
        savedList.axis = .vertical
        savedList.spacing = 10
        savedMessage.font = .systemFont(ofSize: 14)
        savedMessage.textColor = WorkoutUI.muted
        savedMessage.numberOfLines = 0
        savedMessage.textAlignment = .center
        retryButton.addTarget(self, action: #selector(loadWorkouts), for: .touchUpInside)
        savedSpinner.hidesWhenStopped = true
        [savedSpinner, savedMessage, retryButton, savedList].forEach(savedContent.addArrangedSubview)
        savedStack.addArrangedSubview(savedContent)
        stack.addArrangedSubview(savedCard)

        // Generate
        let (genCard, genStack) = WorkoutUI.card(spacing: 12)
        genStack.addArrangedSubview(sectionHeader("✨  " + WorkoutText.generateNew, chevron: generateChevron,
                                                  action: #selector(toggleGenerate)))
        generateContent.axis = .vertical
        generateContent.spacing = 12
        nameField.returnKeyType = .done
        nameField.addTarget(self, action: #selector(endEditing), for: .editingDidEndOnExit)
        otherField.addTarget(self, action: #selector(endEditing), for: .editingDidEndOnExit)
        generateContent.addArrangedSubview(WorkoutUI.labeled(WorkoutText.workoutName, nameField))
        addPicker(WorkoutText.fitnessGoal, WorkoutOptions.fitnessGoals, request.fitnessGoal) { [weak self] in self?.request.fitnessGoal = $0 }
        addPicker(WorkoutText.experienceLevel, WorkoutOptions.experienceLevels, request.experienceLevel) { [weak self] in self?.request.experienceLevel = $0 }
        addPicker(WorkoutText.weeklyTime, WorkoutOptions.weeklyTimes, request.weeklyTime) { [weak self] in self?.request.weeklyTime = $0 }
        addPicker(WorkoutText.frequency, WorkoutOptions.dailyFrequencies, request.dailyFrequency) { [weak self] in self?.request.dailyFrequency = $0 }
        addPicker(WorkoutText.style, WorkoutOptions.workoutStyles, request.preferredWorkout) { [weak self] in self?.request.preferredWorkout = $0 }
        addPicker(WorkoutText.equipment, WorkoutOptions.equipment, request.equipment) { [weak self] in self?.request.equipment = $0 }
        addPicker(WorkoutText.limitations, WorkoutOptions.limitations, request.limitations) { [weak self] value in
            self?.request.limitations = value
            self?.otherField.isHidden = value != WorkoutOptions.other
        }
        otherField.isHidden = true
        generateContent.addArrangedSubview(otherField)
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        generateContent.addArrangedSubview(generateButton)
        let fee = WorkoutUI.label("\(WorkoutOptions.feeAfit) AFIT · Gemini AI", size: 12, color: WorkoutUI.muted)
        fee.textAlignment = .center
        generateContent.addArrangedSubview(fee)
        genStack.addArrangedSubview(generateContent)
        stack.addArrangedSubview(genCard)

        // Busy overlay (paying or generating can take a minute)
        busyOverlay.translatesAutoresizingMaskIntoConstraints = false
        busyOverlay.backgroundColor = UIColor(white: 0, alpha: 0.45)
        busyOverlay.isHidden = true
        view.addSubview(busyOverlay)
        let box = UIView()
        box.translatesAutoresizingMaskIntoConstraints = false
        box.backgroundColor = .white
        box.layer.cornerRadius = 16
        busyOverlay.addSubview(box)
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .large)
        spinner.color = WorkoutUI.red
        spinner.startAnimating()
        busyLabel.font = .systemFont(ofSize: 15, weight: .medium)
        busyLabel.textColor = WorkoutUI.ink
        busyLabel.numberOfLines = 0
        busyLabel.textAlignment = .center
        let boxStack = UIStackView(arrangedSubviews: [spinner, busyLabel])
        boxStack.axis = .vertical
        boxStack.spacing = 14
        boxStack.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(boxStack)
        NSLayoutConstraint.activate([
            busyOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            busyOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            busyOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            busyOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            box.centerXAnchor.constraint(equalTo: busyOverlay.centerXAnchor),
            box.centerYAnchor.constraint(equalTo: busyOverlay.centerYAnchor),
            box.widthAnchor.constraint(equalTo: busyOverlay.widthAnchor, multiplier: 0.75),
            boxStack.topAnchor.constraint(equalTo: box.topAnchor, constant: 24),
            boxStack.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -24),
            boxStack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 20),
            boxStack.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -20)
        ])

        showSection(saved: true)
    }

    private func sectionHeader(_ title: String, chevron: UIImageView, action: Selector) -> UIView {
        let label = WorkoutUI.label(title, size: 17, weight: .bold)
        chevron.image = UIImage(systemName: "chevron.down")
        chevron.tintColor = WorkoutUI.red
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [label, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.isUserInteractionEnabled = true
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
        row.accessibilityTraits = UIAccessibilityTraitButton
        row.isAccessibilityElement = true
        row.accessibilityLabel = title
        return row
    }

    private func addPicker(_ caption: String, _ options: [String], _ selected: String, _ onChange: @escaping (String) -> Void) {
        generateContent.addArrangedSubview(WorkoutUI.labeled(caption, WorkoutUI.picker(options, selected: selected, onChange: onChange)))
    }

    /// One section open at a time (Android's accordion).
    private func showSection(saved: Bool) {
        savedContent.isHidden = !saved
        generateContent.isHidden = saved
        savedChevron.transform = saved ? CGAffineTransform(rotationAngle: .pi) : .identity
        generateChevron.transform = saved ? .identity : CGAffineTransform(rotationAngle: .pi)
    }

    @objc private func toggleSaved() { showSection(saved: savedContent.isHidden) }
    @objc private func toggleGenerate() { showSection(saved: !generateContent.isHidden) }
    @objc private func endEditing() { view.endEditing(true) }
    @objc private func backTapped() { navigationController?.popViewController(animated: true) }

    @objc private func browseTapped() {
        let vc = ExerciseSearchViewController(mode: .browse)
        vc.onSaved = { [weak self] in
            self?.showSection(saved: true)
            self?.loadWorkouts()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func updateGenerateTitle() {
        let paid = !user.isEmpty && GadgetService.workoutPaid(user: user)
        generateButton.setTitle(paid ? WorkoutText.regenerateFree : WorkoutText.generate, for: .normal)
    }

    private func setBusy(_ text: String?) {
        busy = text != nil
        busyLabel.text = text
        busyOverlay.isHidden = text == nil
    }

    // MARK: - Saved workouts

    @objc private func loadWorkouts() {
        guard !user.isEmpty else { return showSavedMessage(WorkoutText.loginFirst, retry: false) }
        savedSpinner.startAnimating()
        savedMessage.isHidden = true
        retryButton.isHidden = true
        WorkoutService.fetch(user: user) { [weak self] result in
            guard let self = self else { return }
            self.savedSpinner.stopAnimating()
            switch result {
            case .success(let list):
                self.workouts = list.sorted { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }
                self.renderSaved()
                // Open the form when there is nothing saved yet (as on Android).
                if self.workouts.isEmpty { self.showSection(saved: false) }
            case .failure(let error):
                self.showSavedMessage(WorkoutText.loadFailed(error.text), retry: true)
            }
        }
    }

    private func showSavedMessage(_ text: String, retry: Bool) {
        savedList.arrangedSubviews.forEach { $0.removeFromSuperview() }
        savedMessage.text = text
        savedMessage.isHidden = false
        retryButton.isHidden = !retry
    }

    private func renderSaved() {
        savedList.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !workouts.isEmpty else { return showSavedMessage(WorkoutText.noSavedWorkouts, retry: false) }
        savedMessage.isHidden = true
        retryButton.isHidden = true
        let df = DateFormatter()
        df.locale = Copy.locale
        df.dateStyle = .medium
        df.timeStyle = .short
        for (i, w) in workouts.enumerated() {
            savedList.addArrangedSubview(savedRow(w, index: i, dateText: w.timestamp.map(df.string(from:))))
        }
    }

    private func savedRow(_ w: WorkoutPlan, index: Int, dateText: String?) -> UIView {
        let row = UIControl()
        row.backgroundColor = WorkoutUI.fill
        row.layer.cornerRadius = 12
        row.tag = index
        // A tap anywhere but the buttons opens the plan (the inner stack would swallow a
        // control's own touch tracking).
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(savedTapped(_:))))

        let name = WorkoutUI.label(w.workoutName.isEmpty ? WorkoutText.screenTitle : w.workoutName, size: 16, weight: .semibold)
        var info = "\(w.exercises.count) " + WorkoutText.exercises.lowercased()
        if let d = dateText { info += "  ·  " + d }
        let meta = WorkoutUI.label(info, size: 12, color: WorkoutUI.muted)
        let text = UIStackView(arrangedSubviews: [name, meta])
        text.axis = .vertical
        text.spacing = 3
        text.isUserInteractionEnabled = false

        let edit = UIButton(type: .system)
        edit.setImage(UIImage(systemName: "pencil"), for: .normal)
        edit.tintColor = WorkoutUI.red
        edit.tag = index
        edit.accessibilityLabel = WorkoutText.edit + " " + w.workoutName
        edit.addTarget(self, action: #selector(editTapped(_:)), for: .touchUpInside)
        let delete = UIButton(type: .system)
        delete.setImage(UIImage(systemName: "trash"), for: .normal)
        delete.tintColor = WorkoutUI.muted
        delete.tag = index
        delete.accessibilityLabel = WorkoutText.delete + " " + w.workoutName
        delete.addTarget(self, action: #selector(deleteTapped(_:)), for: .touchUpInside)
        [edit, delete].forEach {
            $0.widthAnchor.constraint(equalToConstant: 36).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 36).isActive = true
        }

        let h = UIStackView(arrangedSubviews: [text, edit, delete])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 4
        h.translatesAutoresizingMaskIntoConstraints = false
        h.isLayoutMarginsRelativeArrangement = true
        h.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 6)
        row.addSubview(h)
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: row.topAnchor),
            h.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            h.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            h.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])
        row.accessibilityLabel = w.workoutName
        row.accessibilityTraits = UIAccessibilityTraitButton
        return row
    }

    @objc private func savedTapped(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag, workouts.indices.contains(tag) else { return }
        openPlan(workouts[tag])
    }

    @objc private func editTapped(_ sender: UIButton) {
        guard workouts.indices.contains(sender.tag) else { return }
        openEditor(workouts[sender.tag])
    }

    private func openPlan(_ plan: WorkoutPlan) {
        let vc = WorkoutPlanViewController(plan: plan)
        vc.onEdit = { [weak self] p in self?.openEditor(p) }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openEditor(_ plan: WorkoutPlan) {
        let vc = EditWorkoutViewController(plan: plan)
        vc.onSaved = { [weak self] in self?.loadWorkouts() }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func deleteTapped(_ sender: UIButton) {
        guard workouts.indices.contains(sender.tag) else { return }
        let w = workouts[sender.tag]
        let a = UIAlertController(title: WorkoutText.deleteTitle, message: WorkoutText.deleteMessage(w.workoutName), preferredStyle: .alert)
        a.addAction(UIAlertAction(title: WorkoutText.cancel, style: .cancel))
        a.addAction(UIAlertAction(title: WorkoutText.delete, style: .destructive) { [weak self] _ in self?.delete(w) })
        present(a, animated: true)
    }

    private func delete(_ w: WorkoutPlan) {
        guard let id = w.id, !id.isEmpty else { return }
        WorkoutService.delete(user: user, id: id) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.workouts.removeAll { $0.id == id }
                self.renderSaved()
                WorkoutUI.toast(self, WorkoutText.deleted(w.workoutName))
            case .failure(let error):
                WorkoutUI.alert(self, title: nil, message: WorkoutText.deleteFailed(error.text))
            }
        }
    }

    // MARK: - Generate

    @objc private func generateTapped() {
        view.endEditing(true)
        guard !busy else { return }
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            nameField.becomeFirstResponder()
            return WorkoutUI.toast(self, WorkoutText.nameRequired)
        }
        guard !user.isEmpty else { return WorkoutUI.alert(self, title: nil, message: WorkoutText.loginFirst) }
        request.otherLimitations = request.limitations == WorkoutOptions.other
            ? (otherField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines) : ""

        // Read fresh: a payment started earlier may have finished since.
        if GadgetService.workoutPaid(user: user) {
            runGeneration(name)
        } else if GadgetService.hasPendingWorkout(user: user) {
            pay(name)   // an earlier fee's result is unknown: settle it, never pay twice
        } else {
            checkBalanceThenConfirm(name)
        }
    }

    private func checkBalanceThenConfirm(_ name: String) {
        setBusy(" ")
        let user = self.user
        Task { [weak self] in
            let result = await HTTPClient().getAfitBalance(username: user)
            await MainActor.run {
                guard let self = self else { return }
                self.setBusy(nil)
                switch result {
                case .success(let model):
                    let balance = Double(model.tokens ?? "") ?? 0
                    if balance < Double(WorkoutOptions.feeAfit) {
                        WorkoutUI.alert(self, title: WorkoutText.insufficientTitle, message: WorkoutText.insufficientMessage(Int(balance)))
                    } else {
                        self.confirmPayment(name)
                    }
                case .failure(let error):
                    WorkoutUI.alert(self, title: nil, message: WorkoutText.balanceFailed(error.localizedDescription))
                }
            }
        }
    }

    private func confirmPayment(_ name: String) {
        let a = UIAlertController(title: WorkoutText.confirmTitle, message: WorkoutText.confirmMessage, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: WorkoutText.cancel, style: .cancel))
        a.addAction(UIAlertAction(title: WorkoutText.proceed, style: .default) { [weak self] _ in self?.pay(name) })
        present(a, animated: true)
    }

    private func pay(_ name: String) {
        // The fee route needs the session: don't sign a payment it would refuse.
        guard !UserDefaults.standard.authToken.isEmpty else {
            return WorkoutUI.alert(self, title: nil, message: GadgetText.sessionExpired)
        }
        setBusy(WorkoutText.paying)
        GadgetService.payWorkout(user: user) { [weak self] ok, message in
            guard let self = self else { return }
            self.updateGenerateTitle()
            if ok {
                self.runGeneration(name)
            } else {
                self.setBusy(nil)
                WorkoutUI.alert(self, title: nil, message: message ?? GadgetText.failed)
            }
        }
    }

    private func runGeneration(_ name: String) {
        setBusy(WorkoutText.generating)
        let user = self.user
        WorkoutService.generate(request) { [weak self] result in
            switch result {
            case .success(let out):
                GadgetService.clearWorkoutPaid(user: user)   // the paid-for plan is generated
                var plan = out.plan
                plan.workoutName = name
                plan.explanation = out.explanation
                // Saved with the library's pictures and muscles, as Android does.
                plan.exercises = WorkoutLibrary.illustrate(plan.exercises)
                WorkoutService.save(user: user, plan: plan) { saved in
                    guard let self = self else { return }
                    self.setBusy(nil)
                    self.updateGenerateTitle()
                    self.nameField.text = ""
                    switch saved {
                    case .success:
                        WorkoutUI.toast(self, WorkoutText.planSaved)
                        self.loadWorkouts()
                        self.showSection(saved: true)
                    case .failure(let error):
                        WorkoutUI.alert(self, title: nil, message: WorkoutText.saveFailed(error.text))
                    }
                    // Shown either way: the plan was generated and paid for.
                    self.openPlan(plan)
                }
            case .failure(let error):
                guard let self = self else { return }
                self.setBusy(nil)
                self.updateGenerateTitle()
                WorkoutUI.alert(self, title: nil, message: WorkoutText.generationFailed(error.text))
            }
        }
    }
}
