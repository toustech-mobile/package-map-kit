import Foundation
import MapLibre

/// Keeps package credentials on Neshan HTTPS requests only. MapLibre's network
/// delegate is weak, so the package retains this process-wide instance.
final class NeshanNetworkDelegate: NSObject, MLNNetworkConfigurationDelegate {
    static let shared = NeshanNetworkDelegate()
    private weak var upstream: MLNNetworkConfigurationDelegate?
    private let errorLock = NSLock()
    private var reportedFailures = Set<String>()

    func install() {
        let network = MLNNetworkConfiguration.sharedManager
        if network.delegate !== self {
            upstream = network.delegate
            network.delegate = self
        }
    }

    static func isNeshanURL(_ url: URL?) -> Bool {
        guard let url = url, url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased() else { return false }
        return host == "neshan.org" || host.hasSuffix(".neshan.org")
    }

    static func authenticate(_ request: NSMutableURLRequest, key: String, bundleID: String?) -> NSMutableURLRequest {
        guard isNeshanURL(request.url), let url = request.url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return request }
        var items = (components.queryItems ?? []).filter { $0.name.lowercased() != "key" }
        items.append(URLQueryItem(name: "key", value: key))
        components.queryItems = items
        if let authenticatedURL = components.url { request.url = authenticatedURL }
        if let bundleID = bundleID, !bundleID.isEmpty {
            request.setValue(bundleID, forHTTPHeaderField: "bundle")
        }
        return request
    }

    // Explicit selectors are important: these SDK delegate methods are optional.
    @objc(willSendRequest:)
    func willSend(_ request: NSMutableURLRequest) -> NSMutableURLRequest {
        let forwarded = upstream?.willSend?(request) ?? request
        return Self.authenticate(forwarded, key: NeshanConfiguration.apiKey,
                                 bundleID: Bundle.main.bundleIdentifier)
    }

    @objc(didReceiveResponse:)
    func didReceive(_ response: MLNNetworkResponse) -> MLNNetworkResponse {
        let forwarded = upstream?.didReceive?(response) ?? response
        if let http = forwarded.response as? HTTPURLResponse,
           Self.isNeshanURL(http.url), http.statusCode >= 400 {
            let host = http.url?.host ?? "neshan.org"
            let signature = "\(host):\(http.statusCode)"
            errorLock.lock()
            let shouldReport = reportedFailures.insert(signature).inserted
            errorLock.unlock()
            if shouldReport {
                // Never log URL queries, response bodies or credential values.
                NSLog("[map_kit] Neshan resource failed: HTTP %ld; host=%@; path=%@; iOS bundle=%@. Check key permissions for this iOS bundle and service/network availability.",
                      http.statusCode, host, http.url?.path ?? "", Bundle.main.bundleIdentifier ?? "unknown")
            }
        }
        return forwarded
    }

    // Preserve an existing delegate's optional session configuration hooks.
    override func responds(to selector: Selector!) -> Bool {
        super.responds(to: selector) || upstream?.responds(to: selector) == true
    }

    override func forwardingTarget(for selector: Selector!) -> Any? {
        if upstream?.responds(to: selector) == true { return upstream }
        return super.forwardingTarget(for: selector)
    }
}
