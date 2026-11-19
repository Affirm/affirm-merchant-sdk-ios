//
//  RenderMigrationViewController.swift
//  ExamplesSwift
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

import UIKit
import AffirmSDK

/// Shows the native-to-HTML promo render migration: the same native configure call rendered as
/// native text or as HTML, with the promo response it was rendered from.
final class RenderMigrationViewController: UIViewController {

    // Internal SDK diagnostics, read here only to explain what the demo shows. Not a supported API.
    private static let renderDidFinish = Notification.Name("AffirmPromoRenderDidFinish")

    private static let stateDescriptions = [
        "T1": "native text",
        "T2": "HTML",
        "T3": "native text, after the HTML failed",
        "T4": "hidden, request failed",
        "T5": "hidden, HTML failed",
        "T6": "hidden, HTML failed and no native text",
        "T7": "hidden, no content",
        "T8": "hidden, native text failed",
    ]

    private let amount: NSDecimalNumber
    private let stackView = UIStackView()
    private var sourceControl: UISegmentedControl!
    private var mockControl: UISegmentedControl!
    private let optOutSwitch = UISwitch()
    private var fontControl: UISegmentedControl!
    private var colorControl: UISegmentedControl!
    private var nativeAPIButton: AffirmPromotionalButton!
    private var nativeAPIStatus: UILabel!
    private let responseLabel = UILabel()
    private var observers: [NSObjectProtocol] = []

    init(amount: NSDecimalNumber) {
        self.amount = amount
        super.init(nibName: nil, bundle: nil)
        title = "Native → HTML render"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
        buildLayout()
        observers = [
            NotificationCenter.default.addObserver(forName: Self.renderDidFinish, object: nil, queue: .main) { [weak self] note in
                self?.renderDidFinish(note)
            },
            NotificationCenter.default.addObserver(forName: PromoFlagSimulator.didDeliverResponse, object: nil, queue: .main) { [weak self] note in
                self?.responseLabel.text = note.userInfo?[PromoFlagSimulator.responseKey] as? String
            },
        ]
        PromoFlagSimulator.reportsResponses = true
        reload()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            // Leave the rest of the example app talking to the real API.
            PromoFlagSimulator.simulation = .off
            PromoFlagSimulator.reportsResponses = false
            AffirmConfiguration.shared.useLegacyNativeRendering = false
        }
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    // MARK: - Layout

    private func buildLayout() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
        ])

        addHeader("Server response",
                  note: "Real API uses the promo response as the server sends it, including its ios_sdk_migrate_native_to_html_render value. Mock rewrites the response to try each case.")
        sourceControl = addSegments(["Real API", "Mock"], selected: 0)
        mockControl = addSegments(["Flag on", "Flag off", "Missing", "Unsafe", "HTML fails"], selected: 0)

        let optOutRow = UIStackView(arrangedSubviews: [label("useLegacyNativeRendering (opt out)", style: .body), optOutSwitch])
        optOutRow.spacing = 8
        optOutSwitch.addTarget(self, action: #selector(reload), for: .valueChanged)
        stackView.addArrangedSubview(optOutRow)

        addHeader("Native style",
                  note: "Only the system, serif and monospaced designs (regular, bold, italic, bold italic) map to HTML. Other fonts stay native.")
        fontControl = addSegments(["System", "Serif italic", "Marker Felt (stays native)"], selected: 0)
        fontControl.apportionsSegmentWidthsByContent = true
        colorControl = addSegments(["Gray", "Indigo", "Label"], selected: 0)

        addHeader("configure(amount:affirmLogoType:affirmColor:font:textColor:)",
                  note: "Native API. Shown as HTML when the flag is on, with this font, size and color, a transparent background and no margins. Falls back to native text if the HTML fails.")
        nativeAPIButton = newPromoButton()
        nativeAPIStatus = addCard(with: nativeAPIButton)

        addHeader("API response",
                  note: "The promo response the SDK received for the button above, after any mock changes.")
        responseLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        responseLabel.textColor = .secondaryLabel
        responseLabel.numberOfLines = 0
        responseLabel.accessibilityIdentifier = "api-response"
        stackView.addArrangedSubview(responseLabel)
    }

    private func addHeader(_ title: String, note: String) {
        let titleLabel = label(title, style: .headline)
        stackView.addArrangedSubview(titleLabel)
        stackView.setCustomSpacing(4, after: titleLabel)
        let noteLabel = label(note, style: .footnote)
        noteLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(noteLabel)
    }

    private func addSegments(_ titles: [String], selected: Int) -> UISegmentedControl {
        let control = UISegmentedControl(items: titles)
        control.selectedSegmentIndex = selected
        control.addTarget(self, action: #selector(reload), for: .valueChanged)
        stackView.addArrangedSubview(control)
        return control
    }

    private func label(_ text: String, style: UIFont.TextStyle) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }

    private func newPromoButton() -> AffirmPromotionalButton {
        let button = AffirmPromotionalButton(promoID: nil, showCTA: true, pageType: .product, presentingViewController: self,
                                             frame: CGRect(x: 0, y: 0, width: 315, height: 40))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    /// The tinted card shows whether the promo's background is transparent.
    private func addCard(with button: AffirmPromotionalButton) -> UILabel {
        let card = UIView()
        card.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.2)
        card.layer.cornerRadius = 10
        let status = label("", style: .caption1)
        status.textColor = .secondaryLabel
        status.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(button)
        card.addSubview(status)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            button.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            button.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            status.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 12),
            status.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            status.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            status.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
        ])
        stackView.addArrangedSubview(card)
        return status
    }

    // MARK: - Rendering

    private var selectedFont: UIFont {
        switch fontControl.selectedSegmentIndex {
        case 1:
            let serif = UIFont.systemFont(ofSize: 16).fontDescriptor.withDesign(.serif)?.withSymbolicTraits(.traitItalic)
            return serif.map { UIFont(descriptor: $0, size: 16) } ?? .italicSystemFont(ofSize: 16)
        case 2:
            return UIFont(name: "MarkerFelt-Thin", size: 15) ?? .systemFont(ofSize: 15)
        default:
            return .systemFont(ofSize: 15)
        }
    }

    private var selectedColor: UIColor {
        switch colorControl.selectedSegmentIndex {
        case 1: return .systemIndigo
        case 2: return .label
        default: return .gray
        }
    }

    @objc private func reload() {
        let mock = sourceControl.selectedSegmentIndex == 1
        mockControl.isHidden = !mock
        // Mock segments follow `.off` in declaration order.
        PromoFlagSimulator.simulation = mock ? PromoFlagSimulator.Simulation(rawValue: mockControl.selectedSegmentIndex + 1) ?? .off : .off
        AffirmConfiguration.shared.useLegacyNativeRendering = optOutSwitch.isOn
        nativeAPIStatus.text = "Loading…"
        responseLabel.text = "Loading…"

        nativeAPIButton.configure(amount: amount, affirmLogoType: .name, affirmColor: .blue,
                                  font: selectedFont, textColor: selectedColor)
    }

    private func renderDidFinish(_ note: Notification) {
        guard let button = note.object as? AffirmPromotionalButton,
              button === nativeAPIButton,
              let status = nativeAPIStatus,
              let operation = note.userInfo?["operation"] as? NSObject,
              let state = operation.value(forKey: "terminalState") as? String,
              // T9: a newer configure call replaced this render; its own result follows.
              state != "T9" else {
            return
        }
        var lines = ["Shown as: \(Self.stateDescriptions[state] ?? "unknown") (\(state))"]
        if let decision = operation.value(forKey: "decisionReason") as? String {
            lines.append("Decision: \(decision)")
        }
        if let failure = (operation.value(forKey: "fallbackReason") ?? operation.value(forKey: "reason")) as? String {
            lines.append("Reason: \(failure)")
        }
        if !button.isHidden {
            lines.append("VoiceOver: \"\(button.accessibilityLabel ?? "")\" (button)")
        }
        status.text = lines.joined(separator: "\n")
    }
}

extension RenderMigrationViewController: AffirmPrequalDelegate {

    func webViewController(_ webViewController: AffirmBaseWebViewController?, didFailWithError error: Error) {
        print("Prequal failed with error: \(error.localizedDescription)")
        webViewController?.dismiss(animated: true)
    }
}
