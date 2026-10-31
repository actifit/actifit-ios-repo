//
//  WorkoutUI.swift
//  Actifit
//
//  Shared pieces for the Workout screens: the red header bar, cards, option pickers, the
//  exercise row and a small cached image loader.
//

import UIKit

enum WorkoutUI {
    static var red: UIColor { return UIColor.primaryRedColor() }
    static let ink = UIColor(white: 0.13, alpha: 1)
    static let muted = UIColor(white: 0.42, alpha: 1)
    static let fill = UIColor(white: 0.96, alpha: 1)

    /// A red bar with a back chevron and a title, pinned under the status bar. Returns the bar;
    /// lay content below its bottom.
    @discardableResult
    static func header(in vc: UIViewController, title: String, back: Selector, trailing: UIButton? = nil) -> UIView {
        let bar = UIView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = red
        vc.view.addSubview(bar)
        let backBtn = UIButton(type: .system)
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backBtn.tintColor = .white
        backBtn.accessibilityLabel = "Back"
        backBtn.addTarget(vc, action: back, for: .touchUpInside)
        bar.addSubview(backBtn)
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        bar.addSubview(label)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: vc.view.topAnchor),
            bar.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 50),
            backBtn.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 8),
            backBtn.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -6),
            backBtn.widthAnchor.constraint(equalToConstant: 38),
            backBtn.heightAnchor.constraint(equalToConstant: 38),
            label.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 4),
            label.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor)
        ])
        if let t = trailing {
            t.translatesAutoresizingMaskIntoConstraints = false
            t.tintColor = .white
            bar.addSubview(t)
            NSLayoutConstraint.activate([
                t.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -10),
                t.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
                t.widthAnchor.constraint(greaterThanOrEqualToConstant: 38),
                t.heightAnchor.constraint(equalToConstant: 38),
                label.trailingAnchor.constraint(lessThanOrEqualTo: t.leadingAnchor, constant: -8)
            ])
        } else {
            label.trailingAnchor.constraint(lessThanOrEqualTo: bar.trailingAnchor, constant: -16).isActive = true
        }
        return bar
    }

    /// A scroll view holding a vertical stack, laid out under `top`.
    static func scrollStack(in view: UIView, below top: UIView) -> (UIScrollView, UIStackView) {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .interactive
        view.addSubview(scroll)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 32, right: 16)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: top.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])
        return (scroll, stack)
    }

    /// A white rounded card around a vertical stack; returns (card, inner stack).
    static func card(spacing: CGFloat = 10) -> (UIView, UIStackView) {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius = 5
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return (card, stack)
    }

    static func label(_ text: String, size: CGFloat = 15, weight: UIFont.Weight = .regular, color: UIColor = ink) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size, weight: weight)
        l.textColor = color
        l.numberOfLines = 0
        return l
    }

    static func field(_ placeholder: String, text: String = "") -> UITextField {
        let f = UITextField()
        f.placeholder = placeholder
        f.text = text
        f.font = .systemFont(ofSize: 15)
        f.textColor = ink
        f.backgroundColor = fill
        f.layer.cornerRadius = 10
        f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        f.leftViewMode = .always
        f.clearButtonMode = .whileEditing
        f.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return f
    }

    static func textView(_ text: String) -> UITextView {
        let t = UITextView()
        t.text = text
        t.font = .systemFont(ofSize: 15)
        t.textColor = ink
        t.backgroundColor = fill
        t.layer.cornerRadius = 10
        t.isScrollEnabled = false
        t.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        t.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        return t
    }

    static func primaryButton(_ title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        b.titleLabel?.numberOfLines = 0
        b.titleLabel?.textAlignment = .center
        b.backgroundColor = red
        b.layer.cornerRadius = 24
        b.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
        return b
    }

    static func outlineButton(_ title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(red, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.layer.borderColor = red.cgColor
        b.layer.borderWidth = 1.5
        b.layer.cornerRadius = 10
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        return b
    }

    /// A button showing the chosen option; tapping it opens a menu of the options.
    static func picker(_ options: [String], selected: String, onChange: @escaping (String) -> Void) -> UIButton {
        let b = UIButton(type: .system)
        b.contentHorizontalAlignment = .leading
        b.titleLabel?.font = .systemFont(ofSize: 15)
        b.titleLabel?.numberOfLines = 0
        b.setTitleColor(ink, for: .normal)
        b.backgroundColor = fill
        b.layer.cornerRadius = 10
        b.contentEdgeInsets = UIEdgeInsets(top: 11, left: 12, bottom: 11, right: 34)
        b.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        let chevron = UIImageView(image: UIImage(systemName: "chevron.up.chevron.down"))
        chevron.tintColor = muted
        chevron.translatesAutoresizingMaskIntoConstraints = false
        b.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: -12),
            chevron.centerYAnchor.constraint(equalTo: b.centerYAnchor)
        ])
        func build(_ current: String) {
            b.setTitle(current, for: .normal)
            b.menu = UIMenu(children: options.map { option in
                UIAction(title: option, state: option == current ? .on : .off) { _ in
                    build(option)
                    onChange(option)
                }
            })
        }
        build(selected)
        b.showsMenuAsPrimaryAction = true
        return b
    }

    /// A caption above a control.
    static func labeled(_ caption: String, _ control: UIView) -> UIView {
        let s = UIStackView(arrangedSubviews: [label(caption, size: 13, weight: .semibold, color: muted), control])
        s.axis = .vertical
        s.spacing = 6
        return s
    }

    static func toast(_ vc: UIViewController, _ message: String) {
        // The default toast is 200 pt wide; these messages are longer.
        vc.showToast(message: message, width: min(vc.view.bounds.width - 40, 340), height: 80)
    }

    static func alert(_ vc: UIViewController, title: String?, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: WorkoutText.ok, style: .default))
        vc.present(a, animated: true)
    }
}

/// One exercise: picture, name, sets × reps, days. Optional trailing control.
final class WorkoutExerciseRow: UIControl {
    let exercise: WorkoutExercise
    private let thumb = UIImageView()

    init(_ exercise: WorkoutExercise, subtitle: String? = nil, trailing: UIView? = nil) {
        self.exercise = exercise
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        layer.borderWidth = 1

        thumb.contentMode = .scaleAspectFill
        thumb.clipsToBounds = true
        thumb.layer.cornerRadius = 8
        thumb.backgroundColor = WorkoutUI.fill
        thumb.image = UIImage(systemName: "figure.strengthtraining.traditional") ?? UIImage(systemName: "figure.walk")
        thumb.tintColor = UIColor(white: 0.75, alpha: 1)
        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.widthAnchor.constraint(equalToConstant: 64).isActive = true
        thumb.heightAnchor.constraint(equalToConstant: 64).isActive = true
        if let url = exercise.startImageURL {
            WorkoutImages.load(url) { [weak self] image in
                guard let image = image else { return }
                self?.thumb.contentMode = .scaleAspectFill
                self?.thumb.image = image
            }
        }

        let name = WorkoutUI.label(exercise.name, size: 15, weight: .semibold)
        var lines: [UIView] = [name]
        let info = subtitle ?? exercise.summary
        if !info.isEmpty { lines.append(WorkoutUI.label(info, size: 13, color: WorkoutUI.red)) }
        if subtitle == nil, let days = exercise.days, !days.isEmpty {
            lines.append(WorkoutUI.label(days.joined(separator: ", "), size: 12, color: WorkoutUI.muted))
        }
        let text = UIStackView(arrangedSubviews: lines)
        text.axis = .vertical
        text.spacing = 3
        text.isUserInteractionEnabled = false

        var parts: [UIView] = [thumb, text]
        if let t = trailing {
            t.setContentHuggingPriority(.required, for: .horizontal)
            t.setContentCompressionResistancePriority(.required, for: .horizontal)
            parts.append(t)
        }
        let row = UIStackView(arrangedSubviews: parts)
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 10)
        thumb.isUserInteractionEnabled = false
        // Without a trailing control the whole row is the button, so the stack must not take
        // the touch from it.
        row.isUserInteractionEnabled = trailing != nil
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        isAccessibilityElement = trailing == nil
        accessibilityLabel = exercise.name
        accessibilityTraits = UIAccessibilityTraitButton
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? WorkoutUI.fill : .white }
    }
}

/// Exercise pictures (GitHub raw files), cached in memory for the session.
enum WorkoutImages {
    private static let cache = NSCache<NSURL, UIImage>()

    static func load(_ url: URL, done: @escaping (UIImage?) -> Void) {
        if let hit = cache.object(forKey: url as NSURL) { return done(hit) }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            let image = data.flatMap(UIImage.init(data:))
            if let image = image { cache.setObject(image, forKey: url as NSURL) }
            DispatchQueue.main.async { done(image) }
        }.resume()
    }
}

/// The bundled exercises.json, decoded once.
enum WorkoutLibrary {
    private static var loaded: [WorkoutExercise]?
    private static let lock = NSLock()

    static var all: [WorkoutExercise] {
        lock.lock(); defer { lock.unlock() }
        if let l = loaded { return l }
        let list = Bundle.main.url(forResource: "exercises", withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }
            .map(ExerciseLibrary.decode) ?? []
        loaded = list
        return list
    }

    /// Loads off the main thread (about 1 MB), then calls back on main.
    static func load(done: @escaping ([WorkoutExercise]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let list = all
            DispatchQueue.main.async { done(list) }
        }
    }

    /// AI exercises get the library's pictures, muscles and instructions.
    static func illustrate(_ exercises: [WorkoutExercise]) -> [WorkoutExercise] {
        let lib = all
        return exercises.map { $0.enriched(from: ExerciseLibrary.match($0.name, in: lib)) }
    }
}
