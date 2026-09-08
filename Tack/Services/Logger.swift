import Foundation
import os

public enum TKLog {
    public static let app = Logger(subsystem: "app.tack.ios", category: "app")
    public static let notion = Logger(subsystem: "app.tack.ios", category: "notion")
    public static let obsidian = Logger(subsystem: "app.tack.ios", category: "obsidian")
    public static let widget = Logger(subsystem: "app.tack.ios", category: "widget")
    public static let fail = Logger(subsystem: "app.tack.ios", category: "fail")
}
