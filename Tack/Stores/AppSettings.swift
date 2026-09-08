import SwiftUI
import Foundation

/// User preferences — persists in UserDefaults. Use via `@StateObject` in views.
@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    @AppStorage("app.tack.hasOnboarded")      public var hasOnboarded: Bool = false
    @AppStorage("app.tack.appearance")        public var appearanceRaw: String = "system"
    @AppStorage("app.tack.defaultListID")     public var defaultListID: String = ""   // empty = Inbox
    @AppStorage("app.tack.lastSyncMode")      public var lastSyncMode: String = "manual"
    @AppStorage("app.tack.enableCloudSync")   public var enableCloudSync: Bool = false

    public var appearance: ColorScheme? {
        switch appearanceRaw {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    public func setAppearance(_ v: Appearance) {
        appearanceRaw = v.rawValue
    }

    public enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        public var id: String { rawValue }
        public var label: String { rawValue.capitalized }
    }
}
