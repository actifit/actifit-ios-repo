//
//  EditWorkoutViewController.swift
//  Actifit
//
//  Edit a saved workout (Android EditWorkoutActivity): rename it, change its description and
//  explanation, remove exercises or add more from the library, then save with PUT /workouts/:id.
//

import UIKit

final class EditWorkoutViewController: UIViewController {

    private let original: WorkoutPlan
    private var exercises: [WorkoutExercise]
    var onSaved: (() -> Void)?

    private let nameField: UITextField
    private let descriptionView: UITextView
    private let explanationView: UITextView
    private let list = UIStackView()
    private let emptyLabel = WorkoutUI.label(WorkoutText.noExercisesInWorkout, size: 14, color: WorkoutUI.muted)
    private let saveButton = WorkoutUI.primaryButton(WorkoutText.saveChanges)

    init(plan: WorkoutPlan) {
        original = plan
        exercises = plan.exercises
        nameField = WorkoutUI.field(WorkoutText.nameField, text: plan.workoutName)
        descriptionView = WorkoutUI.textView(plan.description)
        explanationView = WorkoutUI.textView(plan.explanation)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        let bar = WorkoutUI.header(in: self, title: WorkoutText.editTitle, back: #selector(backTapped))
        let (_, stack) = WorkoutUI.scrollStack(in: view, below: bar)

        let (details, d) = WorkoutUI.card(spacing: 12)
        d.addArrangedSubview(WorkoutUI.labeled(WorkoutText.nameField, nameField))
        d.addArrangedSubview(WorkoutUI.labeled(WorkoutText.descriptionField, descriptionView))
        d.addArrangedSubview(WorkoutUI.labeled(WorkoutText.explanationField, explanationView))
        stack.addArrangedSubview(details)

        let add = WorkoutUI.outlineButton("＋  " + WorkoutText.addExercises)
        add.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        let header = UIStackView(arrangedSubviews: [WorkoutUI.label(WorkoutText.currentExercises, size: 17, weight: .bold), add])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        stack.addArrangedSubview(header)

        list.axis = .vertical
        list.spacing = 10
        stack.addArrangedSubview(emptyLabel)
        stack.addArrangedSubview(list)

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        stack.addArrangedSubview(saveButton)
        renderList()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func renderList() {
        list.arrangedSubviews.forEach { $0.removeFromSuperview() }
        emptyLabel.isHidden = !exercises.isEmpty
        for (i, e) in exercises.enumerated() {
            let remove = UIButton(type: .system)
            remove.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
            remove.tintColor = WorkoutUI.red
            remove.tag = i
            remove.accessibilityLabel = WorkoutText.remove + " " + e.name
            remove.addTarget(self, action: #selector(removeTapped(_:)), for: .touchUpInside)
            remove.widthAnchor.constraint(equalToConstant: 40).isActive = true
            remove.heightAnchor.constraint(equalToConstant: 40).isActive = true
            list.addArrangedSubview(WorkoutExerciseRow(e, trailing: remove))
        }
    }

    @objc private func backTapped() { navigationController?.popViewController(animated: true) }

    @objc private func addTapped() {
        let vc = ExerciseSearchViewController(mode: .select)
        vc.onSelect = { [weak self] picked in
            guard let self = self else { return }
            var added = 0
            for e in picked {
                // Skip ones already in the workout (same library id, as on Android).
                if let id = e.id, self.exercises.contains(where: { $0.id == id }) { continue }
                self.exercises.append(e)
                added += 1
            }
            self.renderList()
            if added > 0 { WorkoutUI.toast(self, Copy.text("exercise_added_toast", "Exercise added.")) }
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func removeTapped(_ sender: UIButton) {
        guard exercises.indices.contains(sender.tag) else { return }
        let e = exercises[sender.tag]
        let a = UIAlertController(title: WorkoutText.removeTitle, message: WorkoutText.removeMessage(e.name), preferredStyle: .alert)
        a.addAction(UIAlertAction(title: WorkoutText.cancel, style: .cancel))
        a.addAction(UIAlertAction(title: WorkoutText.remove, style: .destructive) { [weak self] _ in
            guard let self = self, let i = self.exercises.firstIndex(of: e) else { return }
            self.exercises.remove(at: i)
            self.renderList()
        })
        present(a, animated: true)
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            nameField.becomeFirstResponder()
            return WorkoutUI.toast(self, WorkoutText.enterTitle)
        }
        guard !exercises.isEmpty else { return WorkoutUI.toast(self, WorkoutText.noExercisesInWorkout) }
        var desc = descriptionView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        var expl = explanationView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if desc.isEmpty { desc = WorkoutText.noDescription }
        if expl.isEmpty { expl = WorkoutText.noExplanation }
        let user = arenaCurrentUser()
        guard !user.isEmpty else { return WorkoutUI.alert(self, title: nil, message: WorkoutText.loginFirst) }

        let updated = WorkoutPlan(id: original.id, workoutName: name, description: desc, explanation: expl,
                                  exercises: exercises, timestamp: original.timestamp)
        saveButton.isEnabled = false
        WorkoutService.update(user: user, plan: updated) { [weak self] result in
            guard let self = self else { return }
            self.saveButton.isEnabled = true
            switch result {
            case .success:
                self.onSaved?()
                if let presenter = self.navigationController?.viewControllers.dropLast().last {
                    WorkoutUI.toast(presenter, WorkoutText.updated(name))
                }
                self.navigationController?.popViewController(animated: true)
            case .failure(let error):
                WorkoutUI.alert(self, title: nil, message: WorkoutText.updateFailed(error.text))
            }
        }
    }
}
