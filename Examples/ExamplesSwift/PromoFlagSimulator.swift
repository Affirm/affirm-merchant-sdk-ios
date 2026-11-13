//
//  PromoFlagSimulator.swift
//  ExamplesSwift
//
//  Copyright © 2026 Affirm, Inc. All rights reserved.
//

import Foundation

/// Demo only. The sandbox does not send the render migration flag yet, so this rewrites promo
/// responses on their way into the SDK. Merchant apps never need anything like this.
final class PromoFlagSimulator: URLProtocol {

    enum Simulation: Int {
        /// Promo responses are passed through untouched.
        case off
        /// Adds `ios_sdk_migrate_native_to_html_render: true` to the promo config.
        case flagOn
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

    private var dataTask: URLSessionDataTask?

    override class func canInit(with request: URLRequest) -> Bool {
        simulation != .off
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
            if let data {
                self.client?.urlProtocol(self, didLoad: Self.rewrite(data, simulation: simulation))
            }
            self.client?.urlProtocolDidFinishLoading(self)
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
        config["ios_sdk_migrate_native_to_html_render"] = true
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
        case .off, .flagOn:
            break
        }
        json["promo"] = promo
        return (try? JSONSerialization.data(withJSONObject: json)) ?? data
    }
}
