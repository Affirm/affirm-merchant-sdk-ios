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

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var promoIDTextField: UITextField!
    @IBOutlet weak var publicKeyTextfield: UITextField!
    @IBOutlet weak var caasTextfield: UITextField!
    @IBOutlet weak var resultLabel: UILabel!

    var promotionalButton: AffirmPromotionalButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Using AffirmPromotionalButton for first button (See more in configurPromotionalMessage)
        promotionalButton = AffirmPromotionalButton(promoID: nil, showCTA: true, pageType: .product, presentingViewController: self, frame: CGRect(x: 0, y: 0, width: 315, height: 34))
        stackView.insertArrangedSubview(promotionalButton, at: 0)

        // Configure Textfields
        publicKeyTextfield.text = AffirmConfiguration.shared.publicKey
        configureTextField()
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

    @IBAction func checkout(sender: Any) {
        let dollarPrice = NSDecimalNumber(string: self.amountTextField.text)
        let item = AffirmItem(name: "Affirm Test Item", sku: "test_item", unitPrice: dollarPrice, quantity: 1, url: URL(string: "http://sandbox.affirm.com/item")!)
        let shipping = AffirmShippingDetail.shippingDetail(name: "Chester Cheetah", line1: "633 Folsom Street", line2: "", city: "San Francisco", state: "CA", zipCode: "94107", countryCode: "USA")

        // Checkout
        let checkout = AffirmCheckout(items: [item], shipping: shipping, taxAmount: NSDecimalNumber.zero, shippingAmount: NSDecimalNumber.zero, discounts: nil, metadata: nil, financingProgram: nil, orderId: "JKLMO4321")

        // CAAS
        if let caas = caasTextfield.text, !caas.isEmpty {
            checkout.caas = caas
        }

        let controller = AffirmCheckoutViewController.start(checkout: checkout, delegate: self)
        present(controller, animated: true, completion: nil)
    }

    @IBAction func showFailedCheckout(sender: Any) {
        let dollarPrice = NSDecimalNumber(string: self.amountTextField.text)
        let item = AffirmItem(name: "Affirm Test Item", sku: "test_item", unitPrice: dollarPrice, quantity: 1, url: URL(string: "http://sandbox.affirm.com/item")!)
        let shipping = AffirmShippingDetail(name: "Test Tester", email: "testtester@test.com", phoneNumber: "1111111111", line1: "633 Folsom Street", line2: "", city: "San Francisco", state: "CA", zipCode: "94107", countryCode: "USA")

        // Checkout
        let checkout = AffirmCheckout.checkout(items: [item], shipping: shipping, payoutAmount: dollarPrice.toIntegerCents())

        // CAAS
        if let caas = caasTextfield.text, !caas.isEmpty {
            checkout.caas = caas
        }

        let controller = AffirmCheckoutViewController.start(checkout: checkout, delegate: self)
        present(controller, animated: true, completion: nil)
    }

    @IBAction func vcnCheckout(sender: Any) {
        let dollarPrice = NSDecimalNumber(string: self.amountTextField.text)
        let item = AffirmItem(name: "Affirm Test Item", sku: "test_item", unitPrice: dollarPrice, quantity: 1, url: URL(string: "http://sandbox.affirm.com/item")!)
        let shipping = AffirmShippingDetail(name: "Chester Cheetah", email: nil, phoneNumber: nil, line1: "633 Folsom Street", line2: "", city: "San Francisco", state: "CA", zipCode: "94107", countryCode: "USA")

        // Checkout
        let checkout = AffirmCheckout.checkout(items: [item], shipping: shipping, payoutAmount: dollarPrice.toIntegerCents())

        // CAAS
        if let caas = caasTextfield.text, !caas.isEmpty {
            checkout.caas = caas
        }

        let controller = AffirmCheckoutViewController.start(checkout: checkout, useVCN: true, delegate: self)
        present(controller, animated: true, completion: nil)
    }

    @IBAction func trackOrderConfirmation(sender: UIButton) {
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

    @IBAction func clearCookies(sender: UIButton) {
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
            AffirmConfiguration.shared.configure(publicKey: text, environment: .sandbox)
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

    func vcnCheckout(_ checkoutViewController: AffirmCheckoutViewController, completedWith creditCard: AffirmCreditCard) {
        if let cardholderName = creditCard.cardholderName,
            let number = creditCard.number,
            let cvv = creditCard.cvv,
            let expiration = creditCard.expiration {
            resultLabel.text = "Received credit card:\ncredit card id: \(creditCard.creditCardId)\ncheckout token: \(creditCard.checkoutToken)\ncard holder name: \(cardholderName)\nnumber:\(number)\ncvv: \(cvv)\nexpiration: \(expiration)\ncallback id: \(creditCard.callbackId)"
        }
        checkoutViewController.dismiss(animated: true, completion: nil)
    }

    func checkoutCancelled(_ checkoutViewController: AffirmCheckoutViewController) {
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
