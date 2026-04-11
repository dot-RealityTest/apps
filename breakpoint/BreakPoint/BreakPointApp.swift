import AppKit
import SwiftUI

@MainActor
final class BreakPointAppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private let settings = AppSettings()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let popoverViewModel = PopoverViewModel(settings: settings)
        let propertiesViewModel = PropertiesViewModel(settings: settings)
        menuBarController = MenuBarController(
            viewModel: popoverViewModel,
            propertiesViewModel: propertiesViewModel
        )
    }
}

@main
struct DoomApp: App {
    @NSApplicationDelegateAdaptor(BreakPointAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
