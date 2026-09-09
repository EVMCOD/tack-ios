import Foundation
import Combine
import SwiftUI

/// Global app-level commands bus. Drives menu-bar items (File → New, Edit
/// → Find, Tack → Settings) and any in-app keyboard shortcuts. macOS-only;
/// iOS ignores this singleton.
@MainActor
public final class AppCommandBus: ObservableObject {
    public static let shared = AppCommandBus()

    /// Bumped each time the user requests the Quick Add sheet via menu or
    /// keyboard shortcut. RootView observes and presents the sheet.
    @Published public var quickAddRequestToken: Int = 0

    /// Bumped when the user wants to focus the search field.
    @Published public var searchRequestToken: Int = 0

    /// Tab selection index: 0=Today, 1=Inbox, 2=Lists, 3=Stats, 4=Settings.
    @Published public var selectedTab: Int = 0

    public func requestQuickAdd() { quickAddRequestToken &+= 1 }
    public func requestSearch()   { searchRequestToken   &+= 1 }
    public func selectTab(_ idx: Int) { selectedTab = idx }
}
