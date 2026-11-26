//
//  ExpressCheckoutViewController.swift
//  ExamplesSwift
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

import UIKit
import AffirmSDK

/// Starts an Express Checkout from `AffirmCheckoutButton`, with a button preview for every style.
final class ExpressCheckoutViewController: UIViewController {

    private static let callbackURLDefaultsKey = "ExpressCheckoutShippingAndTotalsCallbackURL"

    private let amount: NSDecimalNumber
    private let stackView = UIStackView()
    private let callbackURLTextField = UITextField()
    private let defaultButton = AffirmCheckoutButton(pageType: .product, frame: .zero)
    private let styledButton = AffirmCheckoutButton(pageType: .product, frame: .zero)
    private let styledButtonBackground = UIView()
    private var sizeControl: UISegmentedControl!
    private var themeControl: UISegmentedControl!
    private var shapeControl: UISegmentedControl!
    private var textControl: UISegmentedControl!
    private let fullWidthSwitch = UISwitch()
    private let resultLabel = UILabel()

    init(amount: NSDecimalNumber) {
        self.amount = amount
        super.init(nibName: nil, bundle: nil)
        title = "Express Checkout"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
        buildLayout()
    }

    // MARK: - Layout

    private func buildLayout() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        view.addSubview(scrollView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        scrollView.addSubview(stackView)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
        ])

        addNote("Public key: \(AffirmConfiguration.shared.publicKey)\nThe merchant must have Express Checkout enabled and a Shipping & Totals endpoint.")

        callbackURLTextField.borderStyle = .roundedRect
        callbackURLTextField.placeholder = "https://merchant.com/shipping-and-totals"
        callbackURLTextField.keyboardType = .URL
        callbackURLTextField.autocapitalizationType = .none
        callbackURLTextField.autocorrectionType = .no
        callbackURLTextField.clearButtonMode = .whileEditing
        callbackURLTextField.returnKeyType = .done
        callbackURLTextField.accessibilityLabel = "Shipping and totals URL input"
        callbackURLTextField.text = UserDefaults.standard.string(forKey: Self.callbackURLDefaultsKey)
        callbackURLTextField.delegate = self
        addTitle("Shipping & Totals URL")
        stackView.addArrangedSubview(callbackURLTextField)

        addTitle("Default button")
        defaultButton.addTarget(self, action: #selector(startExpressCheckout), for: .touchUpInside)
        stackView.addArrangedSubview(container(for: defaultButton, background: UIView()))

        addTitle("Styled button")
        sizeControl = addSegmentedControl(items: ["Small", "Medium", "Large"], selected: AffirmCheckoutButtonSize.medium.rawValue)
        themeControl = addSegmentedControl(items: ["Dark", "Light"], selected: AffirmCheckoutButtonTheme.dark.rawValue)
        shapeControl = addSegmentedControl(items: ["Sharp", "Pill", "Rounded"], selected: AffirmCheckoutButtonShape.pill.rawValue)
        textControl = addSegmentedControl(items: ["Buy now", "Checkout", "Logo"], selected: AffirmCheckoutButtonTextType.buyNow.rawValue)

        let fullWidthLabel = UILabel()
        fullWidthLabel.text = "Full width"
        fullWidthSwitch.addTarget(self, action: #selector(styleChanged), for: .valueChanged)
        stackView.addArrangedSubview(UIStackView(arrangedSubviews: [fullWidthLabel, fullWidthSwitch]))

        styledButton.addTarget(self, action: #selector(startExpressCheckout), for: .touchUpInside)
        // The light theme has no border, so it sits on a tinted background to stay visible.
        styledButtonBackground.backgroundColor = .secondarySystemBackground
        styledButtonBackground.layer.cornerRadius = 12
        stackView.addArrangedSubview(container(for: styledButton, background: styledButtonBackground))

        resultLabel.numberOfLines = 0
        resultLabel.text = "Checkout result: "
        resultLabel.accessibilityIdentifier = "express checkout result"
        stackView.addArrangedSubview(resultLabel)
    }

    private func addTitle(_ title: String) {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .headline)
        stackView.addArrangedSubview(label)
    }

    private func addNote(_ note: String) {
        let label = UILabel()
        label.text = note
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        stackView.addArrangedSubview(label)
    }

    private func addSegmentedControl(items: [String], selected: Int) -> UISegmentedControl {
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = selected
        control.addTarget(self, action: #selector(styleChanged), for: .valueChanged)
        stackView.addArrangedSubview(control)
        return control
    }

    /// Centers the button, or stretches it when it is full width, in a padded container.
    private func container(for button: AffirmCheckoutButton, background: UIView) -> UIView {
        button.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(button)
        let stretch = button.widthAnchor.constraint(equalTo: background.widthAnchor, constant: -32)
        // Below the button's content hugging, so it only stretches when it is full width.
        stretch.priority = UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: background.topAnchor, constant: 16),
            button.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -16),
            button.centerXAnchor.constraint(equalTo: background.centerXAnchor),
            button.leadingAnchor.constraint(greaterThanOrEqualTo: background.leadingAnchor, constant: 16),
            stretch,
        ])
        return background
    }

    // MARK: - Actions

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func styleChanged() {
        styledButton.size = AffirmCheckoutButtonSize(rawValue: sizeControl.selectedSegmentIndex) ?? .medium
        styledButton.theme = AffirmCheckoutButtonTheme(rawValue: themeControl.selectedSegmentIndex) ?? .dark
        styledButton.shape = AffirmCheckoutButtonShape(rawValue: shapeControl.selectedSegmentIndex) ?? .pill
        styledButton.buttonText = AffirmCheckoutButtonTextType(rawValue: textControl.selectedSegmentIndex) ?? .buyNow
        styledButton.fullWidth = fullWidthSwitch.isOn
        styledButtonBackground.backgroundColor = styledButton.theme == .light ? .systemGray4 : .secondarySystemBackground
    }

    private func setButtonsEnabled(_ enabled: Bool) {
        defaultButton.isEnabled = enabled
        styledButton.isEnabled = enabled
    }

    @objc private func startExpressCheckout() {
        view.endEditing(true)
        let callbackURL = callbackURLTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !callbackURL.isEmpty else {
            showAlert(title: "Shipping & Totals URL required", message: "Express Checkout gets shipping, tax and the total from your Shipping & Totals endpoint.")
            return
        }
        UserDefaults.standard.set(callbackURL, forKey: Self.callbackURLDefaultsKey)

        let item = AffirmItem(name: "Affirm Test Item", sku: "test_item", unitPrice: amount, quantity: 1, url: URL(string: "http://sandbox.affirm.com/item")!)
        // The subtotal of the items, in cents, as a string.
        let subtotal = amount.multiplying(byPowerOf10: 2).stringValue
        let checkout: AffirmCheckout
        do {
            checkout = try AffirmCheckout.expressCheckout(items: [item],
                                                          orderId: UUID().uuidString,
                                                          shippingAndTotalsCallbackURL: callbackURL,
                                                          metadata: ["subtotal": subtotal])
        } catch {
            showAlert(title: "Can't start Express Checkout", message: error.localizedDescription)
            return
        }

        setButtonsEnabled(false)
        let controller = AffirmCheckoutViewController.startNavigation(checkout: checkout, useVCN: false, getReasonCodes: false, delegate: self)
        present(controller, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ExpressCheckoutViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ExpressCheckoutViewController: AffirmCheckoutDelegate {

    func checkout(_ checkoutViewController: AffirmCheckoutViewController, completedWithToken checkoutToken: String) {
        // Forward the token to your server, which authorizes it with Affirm.
        resultLabel.text = "Received token:\n\(checkoutToken)"
        setButtonsEnabled(true)
        checkoutViewController.dismiss(animated: true)
    }

    func vcnCheckout(_ checkoutViewController: UIViewController, completedWith creditCard: AffirmCreditCard) {
        // Express Checkout does not support VCN.
    }

    func checkoutCancelled(_ checkoutViewController: UIViewController) {
        resultLabel.text = "Checkout was cancelled"
        setButtonsEnabled(true)
        checkoutViewController.dismiss(animated: true)
    }

    func checkoutCancelled(_ checkoutViewController: AffirmCheckoutViewController, checkoutCanceledWithReason reasonCode: AffirmReasonCode) {
        resultLabel.text = "Checkout was cancelled: \(reasonCode.reason)"
        setButtonsEnabled(true)
        checkoutViewController.dismiss(animated: true)
    }

    func checkout(_ checkoutViewController: AffirmCheckoutViewController, didFailWithError error: Error) {
        resultLabel.text = "Checkout failed:\n\(error.localizedDescription)"
        setButtonsEnabled(true)
        checkoutViewController.dismiss(animated: true)
    }
}
