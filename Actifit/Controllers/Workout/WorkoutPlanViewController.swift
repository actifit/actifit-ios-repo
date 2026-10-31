//
//  WorkoutPlanViewController.swift
//  Actifit
//
//  A workout plan (Android's plan panel in WorkoutWizardActivity) and one exercise's details
//  (Android ExerciseDetailActivity).
//

import UIKit

final class WorkoutPlanViewController: UIViewController {

    private let plan: WorkoutPlan
    var onEdit: ((WorkoutPlan) -> Void)?

    init(plan: WorkoutPlan) {
        // Saved plans keep the pictures they were saved with; fill in any that are missing.
        var p = plan
        p.exercises = p.exercises.map { ($0.images ?? []).isEmpty ? WorkoutLibrary.illustrate([$0])[0] : $0 }
        self.plan = p
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        var edit: UIButton?
        if plan.id != nil {
            let b = UIButton(type: .system)
            b.setImage(UIImage(systemName: "pencil"), for: .normal)
            b.accessibilityLabel = WorkoutText.edit
            b.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
            edit = b
        }
        let title = plan.workoutName.isEmpty ? WorkoutText.overview : plan.workoutName
        let bar = WorkoutUI.header(in: self, title: title, back: #selector(backTapped), trailing: edit)
        let (_, stack) = WorkoutUI.scrollStack(in: view, below: bar)

        let (overview, o) = WorkoutUI.card(spacing: 8)
        o.addArrangedSubview(WorkoutUI.label(WorkoutText.overview, size: 17, weight: .bold))
        if !plan.description.isEmpty { o.addArrangedSubview(WorkoutUI.label(plan.description, size: 15)) }
        if !plan.explanation.isEmpty && plan.explanation != plan.description {
            o.addArrangedSubview(WorkoutUI.label(plan.explanation, size: 14, color: WorkoutUI.muted))
        }
        stack.addArrangedSubview(overview)

        stack.addArrangedSubview(WorkoutUI.label(WorkoutText.exercises + " (\(plan.exercises.count))", size: 17, weight: .bold))
        for e in plan.exercises {
            let row = WorkoutExerciseRow(e)
            row.addTarget(self, action: #selector(exerciseTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(row)
        }
    }

    @objc private func backTapped() { navigationController?.popViewController(animated: true) }

    @objc private func editTapped() {
        guard let onEdit = onEdit else { return }
        let nav = navigationController
        nav?.popViewController(animated: false)
        onEdit(plan)
    }

    @objc private func exerciseTapped(_ sender: WorkoutExerciseRow) {
        navigationController?.pushViewController(ExerciseDetailViewController(exercise: sender.exercise), animated: true)
    }
}

final class ExerciseDetailViewController: UIViewController {

    private let exercise: WorkoutExercise

    init(exercise: WorkoutExercise) {
        self.exercise = exercise
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.97, alpha: 1)
        let bar = WorkoutUI.header(in: self, title: exercise.name, back: #selector(backTapped))
        let (_, stack) = WorkoutUI.scrollStack(in: view, below: bar)

        // Start and end positions side by side.
        let images = UIStackView(arrangedSubviews: [imageView(exercise.startImageURL), imageView(exercise.endImageURL)])
        images.axis = .horizontal
        images.spacing = 10
        images.distribution = .fillEqually
        stack.addArrangedSubview(images)

        let (card, c) = WorkoutUI.card(spacing: 10)
        c.addArrangedSubview(WorkoutUI.label(exercise.name, size: 20, weight: .bold))
        let summary = exercise.summary
        if !summary.isEmpty { c.addArrangedSubview(WorkoutUI.label(summary, size: 15, weight: .semibold, color: WorkoutUI.red)) }
        let chips = [exercise.level, exercise.category, exercise.equipment].compactMap { $0 }.filter { !$0.isEmpty }
        if !chips.isEmpty { c.addArrangedSubview(WorkoutUI.label(chips.map { $0.capitalized }.joined(separator: "  ·  "), size: 13, color: WorkoutUI.muted)) }
        addFact(c, WorkoutText.equipment.replacingOccurrences(of: ":", with: ""), exercise.equipment)
        addFact(c, WorkoutText.primaryMuscles, exercise.primaryMuscles?.joined(separator: ", "))
        addFact(c, WorkoutText.secondaryMuscles, exercise.secondaryMuscles?.joined(separator: ", "))
        addFact(c, WorkoutText.days, exercise.days?.joined(separator: ", "))
        stack.addArrangedSubview(card)

        if let steps = exercise.instructions, !steps.isEmpty {
            let (ic, i) = WorkoutUI.card(spacing: 10)
            i.addArrangedSubview(WorkoutUI.label(WorkoutText.instructions, size: 17, weight: .bold))
            for (n, step) in steps.enumerated() {
                i.addArrangedSubview(WorkoutUI.label("\(n + 1). " + step, size: 15))
            }
            stack.addArrangedSubview(ic)
        }
    }

    private func addFact(_ stack: UIStackView, _ title: String, _ value: String?) {
        guard let v = value, !v.isEmpty else { return }
        let t = WorkoutUI.label(title, size: 12, weight: .semibold, color: WorkoutUI.muted)
        let s = UIStackView(arrangedSubviews: [t, WorkoutUI.label(v.capitalized, size: 15)])
        s.axis = .vertical
        s.spacing = 2
        stack.addArrangedSubview(s)
    }

    private func imageView(_ url: URL?) -> UIImageView {
        let v = UIImageView(image: UIImage(systemName: "photo"))
        v.tintColor = UIColor(white: 0.8, alpha: 1)
        v.contentMode = .center
        v.backgroundColor = .white
        v.clipsToBounds = true
        v.layer.cornerRadius = 12
        v.heightAnchor.constraint(equalTo: v.widthAnchor, multiplier: 0.8).isActive = true
        if let url = url {
            WorkoutImages.load(url) { [weak v] image in
                guard let image = image else { return }
                v?.contentMode = .scaleAspectFill
                v?.image = image
            }
        }
        return v
    }

    @objc private func backTapped() { navigationController?.popViewController(animated: true) }
}
