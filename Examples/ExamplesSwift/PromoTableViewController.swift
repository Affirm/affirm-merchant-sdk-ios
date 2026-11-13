//
//  PromoTableViewController.swift
//  ExamplesSwift
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

import UIKit
import AffirmSDK

private final class PromoTableCell: UITableViewCell {

    static let identifier = "PromoCell"

    let serial: Int
    var reuseCount = 0
    let promoButton: AffirmPromotionalButton
    let titleLabel = UILabel()
    let cellLabel = UILabel()
    let statusLabel = UILabel()

    init(serial: Int, presenter: UIViewController & AffirmPrequalDelegate) {
        self.serial = serial
        // Created once with the cell; reuse configures this same button again.
        promoButton = AffirmPromotionalButton(showCTA: true, pageType: .product, presentingViewController: presenter,
                                              frame: CGRect(x: 0, y: 0, width: 315, height: 40))
        super.init(style: .default, reuseIdentifier: Self.identifier)
        selectionStyle = .none
        clipsToBounds = true

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        cellLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        cellLabel.textColor = .systemOrange
        cellLabel.textAlignment = .right
        statusLabel.font = .preferredFont(forTextStyle: .caption1)
        statusLabel.textColor = .secondaryLabel

        for view in [titleLabel, cellLabel, statusLabel, promoButton] as [UIView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }
        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: margins.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            cellLabel.firstBaselineAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor),
            cellLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            cellLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            promoButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            promoButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            promoButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            statusLabel.topAnchor.constraint(equalTo: promoButton.bottomAnchor, constant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            statusLabel.bottomAnchor.constraint(lessThanOrEqualTo: margins.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reuseCount += 1
    }
}

/// AffirmPromotionalButton inside reused table view cells: one button per cell, created with the
/// cell and configured again with each row's amount when the cell is reused.
final class PromoTableViewController: UIViewController {

    // Internal SDK diagnostics, read here only to explain what the demo shows. Not a supported API.
    private static let renderDidFinish = Notification.Name("AffirmPromoRenderDidFinish")
    private static let rowCount = 100

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let statsLabel = UILabel()
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    /// Promo button → its cell, to route render results to the row on screen.
    private let cellsByButton = NSMapTable<AffirmPromotionalButton, PromoTableCell>.weakToWeakObjects()
    private var observer: NSObjectProtocol?
    private var createdCount = 0
    private var reusedCount = 0
    private var configureCount = 0
    private var finishedCount = 0
    private var supersededCount = 0

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Promos in a table view"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))

        let renderControl = UISegmentedControl(items: ["Native", "HTML (flag on)"])
        renderControl.selectedSegmentIndex = 1
        renderControl.addTarget(self, action: #selector(renderModeChanged(_:)), for: .valueChanged)

        statsLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        statsLabel.textColor = .secondaryLabel
        statsLabel.numberOfLines = 0

        let note = UILabel()
        note.font = .preferredFont(forTextStyle: .footnote)
        note.textColor = .secondaryLabel
        note.numberOfLines = 0
        note.text = "Each row has its own amount. Only the cells on screen exist; scrolling reuses them, and each reused cell configures its one promo button again. A render still in flight for the old row is superseded, and its late reply is ignored."

        let header = UIStackView(arrangedSubviews: [renderControl, note, statsLabel])
        header.axis = .vertical
        header.spacing = 8
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        // A fixed height keeps scrolling steady while promos finish at different times.
        tableView.rowHeight = 132
        view.addSubview(tableView)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: safe.topAnchor, constant: 12),
            header.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            header.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20),
            tableView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        observer = NotificationCenter.default.addObserver(forName: Self.renderDidFinish, object: nil, queue: .main) { [weak self] note in
            self?.renderDidFinish(note)
        }
        PromoFlagSimulator.simulation = .flagOn
        updateStats()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            PromoFlagSimulator.simulation = .off
        }
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func renderModeChanged(_ control: UISegmentedControl) {
        PromoFlagSimulator.simulation = control.selectedSegmentIndex == 1 ? .flagOn : .off
        tableView.reloadData()
    }

    private func amount(forRow row: Int) -> NSDecimalNumber {
        NSDecimalNumber(value: 100 + row * 45)
    }

    private func renderDidFinish(_ note: Notification) {
        guard let button = note.object as? AffirmPromotionalButton,
              let cell = cellsByButton.object(forKey: button),
              let operation = note.userInfo?["operation"] as? NSObject,
              let state = operation.value(forKey: "terminalState") as? String else {
            return
        }
        if state == "T9" {
            // The cell was reused before this render finished; the new row's render owns the button now.
            supersededCount += 1
        } else {
            finishedCount += 1
            let shown = ["T1": "native text", "T2": "HTML", "T3": "native text (HTML failed)"][state] ?? "hidden"
            if let reason = (operation.value(forKey: "fallbackReason") ?? operation.value(forKey: "reason")) as? String {
                cell.statusLabel.text = "Shown as \(shown) (\(state)), \(reason)"
            } else {
                cell.statusLabel.text = "Shown as \(shown) (\(state))"
            }
        }
        updateStats()
    }

    private func updateStats() {
        statsLabel.text = "Cells created: \(createdCount)   Reused: \(reusedCount)\n"
            + "Configure calls: \(configureCount)   Finished: \(finishedCount)   Superseded: \(supersededCount)"
    }
}

extension PromoTableViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Self.rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PromoTableCell
        if let reused = tableView.dequeueReusableCell(withIdentifier: PromoTableCell.identifier) as? PromoTableCell {
            reusedCount += 1
            cell = reused
        } else {
            createdCount += 1
            cell = PromoTableCell(serial: createdCount, presenter: self)
            cellsByButton.setObject(cell, forKey: cell.promoButton)
        }

        let amount = amount(forRow: indexPath.row)
        let price = currencyFormatter.string(from: amount) ?? "\(amount)"
        cell.titleLabel.text = "Row \(indexPath.row) · \(price)"
        cell.cellLabel.text = cell.reuseCount == 0 ? "cell #\(cell.serial) · new" : "cell #\(cell.serial) · reused \(cell.reuseCount)×"
        cell.statusLabel.text = "Loading \(price)…"

        configureCount += 1
        cell.promoButton.configure(amount: amount, affirmLogoType: .name, affirmColor: .blue,
                                   font: .systemFont(ofSize: 15), textColor: .gray)
        updateStats()
        return cell
    }
}

extension PromoTableViewController: AffirmPrequalDelegate {

    func webViewController(_ webViewController: AffirmBaseWebViewController?, didFailWithError error: Error) {
        print("Prequal failed with error: \(error.localizedDescription)")
        webViewController?.dismiss(animated: true)
    }
}
