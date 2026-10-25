import Foundation
import MapLibre

/// Shared credentials for the private map_kit package.
/// Both CocoaPods and SwiftPM compile this source into the plugin.
enum NeshanConfiguration {
    static let apiKey = "mobile.3f93ce5520af4fb8af2d905df9e70170"

    static func configure() throws {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MapPayloadError(message: "The package Neshan API key is empty")
        }
        // The SDK requires the key before the first style request / map creation.
        MLNSettings.apiKey = apiKey
        // Neshan's resourceURL() reads MLNApiKey from Bundle.main directly for
        // its private tile scheme, bypassing MLNSettings.apiKey. Authenticate
        // requests as well so this private package needs no host plist entry.
        NeshanNetworkDelegate.shared.install()
    }
}
