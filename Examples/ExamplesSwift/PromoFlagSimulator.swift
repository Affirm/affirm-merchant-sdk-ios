//
//  PromoFlagSimulator.swift
//  ExamplesSwift
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

import Foundation

/// Demo only. Rewrites promo responses on their way into the SDK, so every flag value and
/// failure can be tried whatever the server sends for this merchant. Merchant apps never need
/// anything like this.
final class PromoFlagSimulator: URLProtocol {

    /// Posted on the main queue for each promo response handed to the SDK, after any rewrite.
    /// `userInfo[responseKey]` is the response as pretty-printed JSON.
    static let didDeliverResponse = Notification.Name("PromoFlagSimulatorDidDeliverResponse")
    static let responseKey = "response"

    enum Simulation: Int {
        /// Promo responses are passed through untouched.
        case off
        /// Sets `ios_sdk_migrate_native_to_html_render: true` in the promo config.
        case flagOn
        /// Sets `ios_sdk_migrate_native_to_html_render: false` in the promo config.
        case flagOff
        /// Removes `ios_sdk_migrate_native_to_html_render` from the promo config.
        case flagMissing
        /// Flag on, and unsafe markup is added to `html_ala` to show what the SDK strips.
        case unsafeMarkup
        /// Flag on, and `html_ala` is replaced with content that is empty after sanitizing.
        case brokenHTML
    }

    private static let handledKey = "PromoFlagSimulatorHandled"
    private static let registration: Void = { URLProtocol.registerClass(PromoFlagSimulator.self) }()

    static var simulation: Simulation = .off {
        didSet { _ = registration }
    }

    /// Also intercepts promo requests while `simulation` is off, to post them unchanged.
    static var reportsResponses = false {
        didSet { _ = registration }
    }

    private var dataTask: URLSessionDataTask?

    override class func canInit(with request: URLRequest) -> Bool {
        (simulation != .off || reportsResponses)
            && request.url?.path.contains("/api/promos/v2/") == true
            && URLProtocol.property(forKey: handledKey, in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let request = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return
        }
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: request)
        let simulation = Self.simulation
        dataTask = URLSession.shared.dataTask(with: request as URLRequest) { [weak self] data, response, error in
            guard let self else { return }
            if let error {
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            if let response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            let delivered = data.map { simulation == .off ? $0 : Self.rewrite($0, simulation: simulation) }
            if let delivered {
                self.client?.urlProtocol(self, didLoad: delivered)
            }
            self.client?.urlProtocolDidFinishLoading(self)
            Self.post(delivered)
        }
        dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
    }

    private static func rewrite(_ data: Data, simulation: Simulation) -> Data {
        guard var json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              var promo = json["promo"] as? [String: Any] else {
            return data
        }
        var config = promo["config"] as? [String: Any] ?? [:]
        if simulation == .flagMissing {
            config.removeValue(forKey: "ios_sdk_migrate_native_to_html_render")
        } else {
            config["ios_sdk_migrate_native_to_html_render"] = simulation != .flagOff
        }
        promo["config"] = config

        let html = promo["html_ala"] as? String ?? ""
        switch simulation {
        case .unsafeMarkup:
            promo["html_ala"] = "<script>alert('script')</script>"
                + "<img src=\"x\" onerror=\"alert('onerror')\">"
                + "<span style=\"color:red;font-size:40px\" onclick=\"alert('click')\">[inline style removed] </span>"
                + html
        case .brokenHTML:
            promo["html_ala"] = "<script>alert('nothing left after sanitizing')</script>"
        case .off, .flagOn, .flagOff, .flagMissing:
            break
        }
        json["promo"] = promo
        return (try? JSONSerialization.data(withJSONObject: json)) ?? data
    }

    private static func post(_ data: Data?) {
        var text = ""
        if let data {
            if let json = try? JSONSerialization.jsonObject(with: data),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) {
                text = String(decoding: pretty, as: UTF8.self)
            } else {
                text = String(decoding: data, as: UTF8.self)
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: didDeliverResponse, object: nil, userInfo: [responseKey: text])
        }
    }
}
