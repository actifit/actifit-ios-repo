//
//  AccordionCardView.swift
//  Actifit
//
//  Reusable collapsible "accordion" card matching the Android wallet design.
//  A white rounded card with a tappable header (icon + title + optional action
//  icons + chevron) and a collapsible content area. Reuse across screens.
//

import UIKit

final class AccordionCardView: UIView, UIGestureRecognizerDelegate {

    static var brandRed: UIColor { UIColor(named: "primaryRed") ?? UIColor(red: 0.90, green: 0.11, blue: 0.20, alpha: 1) }

    private let outerStack = UIStackView()
    private let headerStack = UIStackView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let actionsStack = UIStackView()
    private let chevron = UIImageView()
    private let separator = UIView()
    private let contentContainer = UIView()

    private(set) var isExpanded = false
    var onToggle: ((Bool) -> Void)?

    init(title: String, systemIcon: String) {
        super.init(frame: .zero)
        setup(title: title, icon: UIImage(systemName: systemIcon))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup(title: String, icon: UIImage?) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 2)

        iconView.image = icon
        iconView.tintColor = AccordionCardView.brandRed
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.widthAnchor.constraint(equalToConstant: 26).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 26).isActive = true

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = UIColor(white: 0.15, alpha: 1)
        titleLabel.numberOfLines = 0
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        actionsStack.axis = .horizontal
        actionsStack.spacing = 16
        actionsStack.alignment = .center
        actionsStack.setContentHuggingPriority(.required, for: .horizontal)

        chevron.image = UIImage(systemName: "chevron.down")
        chevron.tintColor = AccordionCardView.brandRed
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.widthAnchor.constraint(equalToConstant: 18).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 18).isActive = true

        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .center
        headerStack.isLayoutMarginsRelativeArrangement = true
        headerStack.layoutMargins = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        [iconView, titleLabel, actionsStack, chevron].forEach { headerStack.addArrangedSubview($0) }
        headerStack.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggle))
        tap.delegate = self
        tap.cancelsTouchesInView = false
        headerStack.addGestureRecognizer(tap)

        separator.backgroundColor = UIColor(white: 0.92, alpha: 1)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true

        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        let contentWrap = UIStackView(arrangedSubviews: [separator, contentContainer])
        contentWrap.axis = .vertical
        contentWrap.isHidden = true

        outerStack.axis = .vertical
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        outerStack.addArrangedSubview(headerStack)
        outerStack.addArrangedSubview(contentWrap)
        self.collapsibleWrap = contentWrap

        addSubview(outerStack)
        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: topAnchor),
            outerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            outerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            outerStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private var collapsibleWrap: UIStackView?

    /// Adds a header action icon (e.g. refresh) to the right of the title.
    @discardableResult
    func addHeaderAction(systemIcon: String, handler: @escaping () -> Void) -> UIButton {
        let btn = ClosureButton(type: .system)
        btn.setImage(UIImage(systemName: systemIcon), for: .normal)
        btn.tintColor = AccordionCardView.brandRed
        btn.onTap = handler
        btn.addTarget(btn, action: #selector(ClosureButton.fire), for: .touchUpInside)
        btn.widthAnchor.constraint(equalToConstant: 24).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 24).isActive = true
        actionsStack.addArrangedSubview(btn)
        return btn
    }

    func setContent(_ view: UIView) {
        contentContainer.subviews.forEach { $0.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
    }

    // Let header action buttons (refresh, etc.) receive their own taps instead of
    // the header's expand/collapse gesture swallowing them.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is UIControl)
    }

    @objc func toggle() { setExpanded(!isExpanded, animated: true) }

    func setExpanded(_ expanded: Bool, animated: Bool) {
        isExpanded = expanded
        let apply = {
            self.collapsibleWrap?.isHidden = !expanded
            self.chevron.image = UIImage(systemName: expanded ? "chevron.up" : "chevron.down")
        }
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                apply(); self.superview?.superview?.layoutIfNeeded()
            })
        } else { apply() }
        onToggle?(expanded)
    }
}

/// Small helper so header actions can use closures instead of target/selector plumbing.
final class ClosureButton: UIButton {
    var onTap: (() -> Void)?
    @objc func fire() { onTap?() }
}
