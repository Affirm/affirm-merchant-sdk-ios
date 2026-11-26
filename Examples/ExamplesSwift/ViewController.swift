//
//  ViewController.swift
//  ExamplesSwift
//
//  Created by Victor Zhu on 2019/4/1.
//  Copyright © 2019 Affirm, Inc. All rights reserved.
//

import UIKit
import AffirmSDK

class ViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var amountTextField: UITextField!
    private var promoIDTextField: UITextField!
    private var publicKeyTextfield: UITextField!
    private var caasTextfield: UITextField!
    private let resultLabel = UILabel()

    var promotionalButton: AffirmPromotionalButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()

        // Configure Textfields
        publicKeyTextfield.text = AffirmConfiguration.shared.publicKey
        configureTextField()
        
        async {
            await getPromoMessage()
        }
    }

    // MARK: - Layout

    private func buildLayout() {
        view.backgroundColor = .white

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .white
        scrollView.addSubview(contentView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 15
        contentView.addSubview(stackView)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 100),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
        ])

        // Using AffirmPromotionalButton for first button (See more in configurPromotionalMessage)
        promotionalButton = AffirmPromotionalButton(promoID: nil, showCTA: true, pageType: .product, presentingViewController: self, frame: CGRect(x: 0, y: 0, width: 315, height: 34))
        stackView.addArrangedSubview(promotionalButton)

        let publicKeyLabel: UILabel
        (publicKeyLabel, publicKeyTextfield) = addTextFieldRow(title: "PublicKey:   ", accessibilityLabel: "public API key input")
        // The other rows line their text fields up with this one, so this title gives way first.
        publicKeyLabel.setContentCompressionResistancePriority(UILayoutPriority(749), for: .horizontal)
        (_, amountTextField) = addTextFieldRow(title: "Amount:   ", accessibilityLabel: "price input")
        amountTextField.text = "4000"
        amountTextField.keyboardType = .decimalPad
        (_, promoIDTextField) = addTextFieldRow(title: "PromoID:  ", accessibilityLabel: "promo ID input")
        (_, caasTextfield) = addTextFieldRow(title: "CAAS:", accessibilityLabel: nil)
        NSLayoutConstraint.activate([amountTextField, promoIDTextField, caasTextfield].map {
            $0.leadingAnchor.constraint(equalTo: publicKeyTextfield.leadingAnchor)
        })

        addButton(title: "Native → HTML render demo", action: #selector(showRenderMigrationDemo))
        addButton(title: "Promos in a table view", action: #selector(showPromoTableDemo))
        addButton(title: "Buy with Affirm", action: #selector(checkout(sender:)))
        addButton(title: "Failed Checkout", action: #selector(showFailedCheckout(sender:)))
        addButton(title: "Express Checkout demo", action: #selector(showExpressCheckoutDemo))
        addButton(title: "VCN Checkout", action: #selector(vcnCheckout(sender:)))
        addButton(title: "Track Order Confirmation", action: #selector(trackOrderConfirmation(sender:)))
        addButton(title: "Clear Cookies", action: #selector(clearCookies(sender:)))

        resultLabel.text = "Checkout result: "
        resultLabel.font = .systemFont(ofSize: 17)
        resultLabel.numberOfLines = 0
        stackView.addArrangedSubview(resultLabel)
    }

    private func addTextFieldRow(title: String, accessibilityLabel: String?) -> (UILabel, UITextField) {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17)
        label.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)

        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.minimumFontSize = 17
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.accessibilityLabel = accessibilityLabel
        textField.delegate = self

        stackView.addArrangedSubview(UIStackView(arrangedSubviews: [label, textField]))
        return (label, textField)
    }

    private func addButton(title: String, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        configurPromotionalMessage()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillChangeFrame(notification: Notification) {
        if let rectValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: rectValue.height, right: 0)
        }
    }

    @objc func keyboardWillBeHidden(notification: Notification) {
        self.scrollView.contentInset = .zero
    }

    @objc func showRenderMigrationDemo() {
        let amount = NSDecimalNumber(string: amountTextField.text)
        let viewController = RenderMigrationViewController(amount: amount == .notANumber ? NSDecimalNumber(string: "500") : amount)
        present(UINavigationController(rootViewController: viewController), animated: true)
    }

    @objc func showExpressCheckoutDemo() {
        let amount = NSDecimalNumber(string: amountTextField.text)
        let viewController = ExpressCheckoutViewController(amount: amount == .notANumber ? NSDecimalNumber(string: "500") : amount)
        present(UINavigationController(rootViewController: viewController), animated: true)
    }

    @objc func showPromoTableDemo() {
        present(UINavigationController(rootViewController: PromoTableViewController()), animated: true)
    }

    @objc func checkout(sender: Any) {
        let dollarPrice = NSDecimalNumber(string: self.amountTextField.text)
        let item = AffirmItem(name: "Affirm Test Item", sku: "test_item", unitPrice: dollarPrice, quantity: 1, url: URL(string: "http://sandbox.affirm.com/item")!)
        let shipping = AffirmShippingDetail.shippingDetail(name: "Chester Cheetah", line1: "633 Folsom Street", line2: "", city: "San Francisco", state: "CA", zipCode: "94107", countryCode: "USA")

        // Checkout
        let checkout = AffirmCheckout(items: [item], shipping: shipping, taxAmount: NSDecimalNumber.zero, shippingAmount: NSDecimalNumber.zero, discounts: nil, metadata: nil, financingProgram: nil, orderId: "JKLMO4321")
        
        // Billing
        let billing = AffirmBillingDetail(name: "Chester Cheetah", email: "testtester@test.com", phoneNumber: nil, line1: "633 Folsom Street", line2: "", city: "San Francisco", state: "CA", zipCode: "94107", countryCode: "USA")
        checkout.billing = billing

        // CAAS
        if let caas = caasTextfield.text, !caas.isEmpty {
            checkout.caas = caas
        }

        let controller = AffirmCheckoutViewController.start(checkout: checkout, delegate: self)
        present(controller, animated: true, completion: nil)
    }

    @objc func showFailedCheckout(sender: Any) {
        let dollarPrice = NSDecimalNumber(string: self.amountTextField.text)
        let item = AffirmItem(name: "Affirm Test Item", sku: "test_item", unitPrice: dollarPrice, quantity: 1, url: URL(string: "http://sandbox.affirm.com/item")!)
        let shipping = AffirmShippingDetail(name: "Test Tester", email: "testtester@test.com", phoneNumber: "1111111111", line1: "633 Folsom Street", line2: "", city: "San Francisco", state: "CA", zipCode: "94107", countryCode: "USA")

        // Checkout
        let checkout = AffirmCheckout.checkout(items: [item], shipping: shipping, payoutAmount: dollarPrice)

        // CAAS
        if let caas = caasTextfield.text, !caas.isEmpty {
            checkout.caas = caas
        }

        let controller = AffirmCheckoutViewController.start(checkout: checkout, delegate: self)
        present(controller, animated: true, completion: nil)
    }

    @objc func vcnCheckout(sender: Any) {
        let dollarPrice = NSDecimalNumber(string: self.amountTextField.text)
        let item = AffirmItem(name: "Affirm Test Item", sku: "test_item", unitPrice: dollarPrice, quantity: 1, url: URL(string: "http://sandbox.affirm.com/item")!)
        let shipping = AffirmShippingDetail(name: "Chester Cheetah", email: nil, phoneNumber: nil, line1: "633 Folsom Street", line2: "", city: "San Francisco", state: "CA", zipCode: "94107", countryCode: "USA")

        // Checkout
        let checkout = AffirmCheckout.checkout(items: [item], shipping: shipping, payoutAmount: dollarPrice)

        // CAAS
        if let caas = caasTextfield.text, !caas.isEmpty {
            checkout.caas = caas
        }

        let controller = AffirmCheckoutViewController.start(checkout: checkout, useVCN: true, delegate: self)
        present(controller, animated: true, completion: nil)
    }

    @objc func trackOrderConfirmation(sender: UIButton) {
        sender.titleLabel?.layer.backgroundColor = sender.tintColor.cgColor
        UIView.animate(withDuration: 0.2) {
            sender.titleLabel?.layer.backgroundColor = UIColor.clear.cgColor
        }

        let order = AffirmOrder(storeName: "Affirm Store", checkoutId: nil, coupon: "SUMMER2018", currency: "USD", discount: .zero, orderId: "T12345", paymentMethod: "Visa", revenue: NSDecimalNumber(string: "2920"), shipping: NSDecimalNumber(string: "534"), shippingMethod: "Fedex", tax: NSDecimalNumber(string: "285"), total: NSDecimalNumber(string: "3739"))
        let product0 = AffirmProduct(brand: "Affirm", category: "Apparel", coupon: "SUMMER2018", name: "Affirm T-Shirt", price: NSDecimalNumber(string: "730"), productId: "SKU-1234", quantity: 1, variant: "Black", currency: nil)
        let product1 = AffirmProduct(brand: "Affirm", category: "Apparel", coupon: "SUMMER2018", name: "Affirm Turtleneck Sweater", price: NSDecimalNumber(string: "2190"), productId: "SKU-5678", quantity: 1, variant: "Black", currency: nil)
        AffirmOrderTrackerViewController.track(order: order, products: [product0, product1])

        let alertController = UIAlertController(title: nil, message: "Track successfully", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alertController, animated: true, completion: nil)
    }

    @objc func clearCookies(sender: UIButton) {
        AffirmConfiguration.deleteAffirmCookies()
        configurPromotionalMessage()

        let alertController = UIAlertController(title: nil, message: "Clear successfully", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alertController, animated: true, completion: nil)
    }

    func configureTextField() {
        let _ = [self.publicKeyTextfield, self.amountTextField, self.promoIDTextField].map { textField in
            let toolbar = UIToolbar()
            let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: textField, action: #selector(UIResponder.resignFirstResponder))
            toolbar.items = [flexibleItem, doneItem];
            toolbar.sizeToFit()
            textField?.inputAccessoryView = toolbar
        }
    }

    func configurPromotionalMessage() {
        let amountText = self.amountTextField.text
        self.promotionalButton.configure(amount: NSDecimalNumber(string: amountText),
                                         affirmLogoType: .name,
                                         affirmColor: .blueBlack,
                                         font: UIFont.italicSystemFont(ofSize: 15),
                                         textColor: .gray)
    }
    
    func getPromoMessage() async {
        guard let affirmData = try? await AffirmDataHandler.getPromoMessage(promoID: nil, amount: NSDecimalNumber(string: "4000.00"), showCTA: true, pageType: .product, logoType: .name, colorType: .blueBlack, font: .systemFont(ofSize: 15), textColor: .gray, presentingViewController: self, withNavigation: true, withHtmlValue: true) else {
            return
        }
        
        let html = affirmData.1
        let afirmViewController = affirmData.2
    }
}

extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }

        if textField == self.publicKeyTextfield {
            let configuration = AffirmConfiguration.shared
            configuration.configure(publicKey: text, environment: configuration.environment, merchantName: configuration.merchantName)
        } else if textField == self.promoIDTextField {
            self.promotionalButton.promoID = text
        }
        configurPromotionalMessage()
    }
}

extension ViewController: AffirmPrequalDelegate {

    func webViewController(_ webViewController: AffirmBaseWebViewController?, didFailWithError error: Error) {
        print("Prequal failed with error: \(error.localizedDescription)")
        if let webViewController = webViewController {
            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                webViewController.dismiss(animated: true, completion: nil)
            }))
            webViewController.present(alertController, animated: true, completion: nil)
        }
    }
}

extension ViewController: AffirmCheckoutDelegate {

    func checkout(_ checkoutViewController: AffirmCheckoutViewController, completedWithToken checkoutToken: String) {
        resultLabel.text = "Received token:\n\(checkoutToken)"
        checkoutViewController.dismiss(animated: true, completion: nil)
    }

    func vcnCheckout(_ checkoutViewController: UIViewController, completedWith creditCard: AffirmCreditCard) {
        if let cardholderName = creditCard.cardholderName,
            let number = creditCard.number,
            let cvv = creditCard.cvv,
            let expiration = creditCard.expiration {
            resultLabel.text = "Received credit card:\ncredit card id: \(creditCard.creditCardId)\ncheckout token: \(creditCard.checkoutToken)\ncard holder name: \(cardholderName)\nnumber:\(number)\ncvv: \(cvv)\nexpiration: \(expiration)\ncallback id: \(creditCard.callbackId)"
        }
        checkoutViewController.dismiss(animated: true, completion: nil)
    }

    func checkoutCancelled(_ checkoutViewController: UIViewController) {
        print("Checkout was cancelled")
        checkoutViewController.dismiss(animated: true, completion: nil)
    }

    func checkoutCancelled(_ checkoutViewController: AffirmCheckoutViewController, checkoutCanceledWithReason reasonCode: AffirmReasonCode) {
        print("Checkout canceled with a reason: \(reasonCode.reason)")
        resultLabel.text = "Checkout canceled \n reason: \(reasonCode.reason), \n checkout_token: \(reasonCode.checkout_token)"
        checkoutViewController.dismiss(animated: true, completion: nil)
    }

    func checkout(_ checkoutViewController: AffirmCheckoutViewController, didFailWithError error: Error) {
        print("Checkout failed with error: \(error.localizedDescription)")
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            checkoutViewController.dismiss(animated: true, completion: nil)
        }))
        checkoutViewController.present(alertController, animated: true, completion: nil)
    }
}
