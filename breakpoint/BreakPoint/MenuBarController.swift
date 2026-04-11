import AppKit
import Carbon
import Observation
import OSLog
import SwiftUI

@MainActor
@Observable
final class PopoverViewModel {
    private struct ExportResult {
        let fileURL: URL?
        let statusMessage: String
    }

    var doomsStatus: DoomsMomentStatus = .idle
    var latestGeneratedFileURL: URL?
    var isPiecesAvailable = false
    var hasCheckedPiecesAvailability = false

    private let settings: AppSettings
    private let doomsMomentService: DoomsMomentService
    var onStatusChanged: (() -> Void)?

    init(
        settings: AppSettings,
        doomsMomentService: DoomsMomentService = DoomsMomentService()
    ) {
        self.settings = settings
        self.doomsMomentService = doomsMomentService
    }

    var generationModeDisplayName: String {
        settings.generationMode.displayName
    }

    var exportPresetDisplayName: String {
        settings.exportPreset.displayName
    }

    var exportDirectoryURL: URL {
        settings.exportDirectoryURL
    }

    var supportsLatestFileActions: Bool {
        settings.exportPreset.includesFileExport
    }

    var isGenerating: Bool {
        if case .generating = doomsStatus {
            return true
        }
        return false
    }

    func refreshPiecesAvailability() {
        Task {
            let available = await doomsMomentService.isPiecesAvailable(
                baseURLString: settings.piecesBaseURLString
            )
            await MainActor.run {
                self.isPiecesAvailable = available
                self.hasCheckedPiecesAvailability = true
                self.onStatusChanged?()
            }
        }
    }

    func refreshLatestGeneratedFileURLFromDisk() {
        guard settings.exportPreset.includesFileExport else {
            latestGeneratedFileURL = nil
            return
        }

        let directoryURL = settings.exportDirectoryURL
        let latestFile = Self.findLatestGeneratedFile(in: directoryURL)
        latestGeneratedFileURL = latestFile
    }

    func triggerDoomsMoment() {
        guard isGenerating == false else { return }

        doomsStatus = .generating
        onStatusChanged?()

        Task {
            let captureDate = Date()
            do {
                let data = try await doomsMomentService.gatherContext(
                    at: captureDate,
                    piecesBaseURLString: settings.piecesBaseURLString
                )
                let result = await doomsMomentService.generate(
                    data: data,
                    usePieces: settings.usePiecesForGeneration,
                    piecesBaseURL: settings.piecesBaseURLString,
                    ollamaBaseURL: settings.ollamaBaseURLString,
                    ollamaModel: settings.ollamaModel,
                    mode: settings.generationMode,
                    userTagsString: settings.userTagsString
                )

                switch result {
                case .success(let markdown):
                    do {
                        let exportResult = try await exportGeneratedMarkdown(markdown, captureDate: captureDate)
                        latestGeneratedFileURL = exportResult.fileURL
                        doomsStatus = .success(message: exportResult.statusMessage)

                        // Send notifications
                        await doomsMomentService.sendNotifications(
                            title: "Doom's Moment Captured",
                            message: String(markdown.prefix(500))
                        )
                    } catch {
                        doomsStatus = .error(message: "Save failed: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    doomsStatus = .error(message: error.localizedDescription)
                }
            } catch {
                doomsStatus = .error(message: error.localizedDescription)
            }

            onStatusChanged?()
        }
    }

    private func exportGeneratedMarkdown(_ markdown: String, captureDate: Date) async throws -> ExportResult {
        let noteTitle = Self.noteTitle(for: captureDate)

        switch settings.exportPreset {
        case .file:
            let fileURL = try doomsMomentService.save(
                markdown: markdown,
                to: settings.exportDirectoryURL,
                fileDate: captureDate
            )
            return ExportResult(
                fileURL: fileURL,
                statusMessage: "Saved \(fileURL.lastPathComponent) in \(Self.displayPath(for: fileURL.deletingLastPathComponent()))"
            )
        case .notes:
            try await AppleNotesService.createNote(markdown: markdown, title: noteTitle)
            return ExportResult(fileURL: nil, statusMessage: "Saved to Apple Notes only")
        case .fileAndNotes:
            let fileURL = try doomsMomentService.save(
                markdown: markdown,
                to: settings.exportDirectoryURL,
                fileDate: captureDate
            )
            do {
                try await AppleNotesService.createNote(markdown: markdown, title: noteTitle)
                return ExportResult(
                    fileURL: fileURL,
                    statusMessage: "Saved \(fileURL.lastPathComponent) in \(Self.displayPath(for: fileURL.deletingLastPathComponent())) and Apple Notes"
                )
            } catch {
                return ExportResult(
                    fileURL: fileURL,
                    statusMessage: "Saved \(fileURL.lastPathComponent) in \(Self.displayPath(for: fileURL.deletingLastPathComponent())). Notes export failed: \(error.localizedDescription)"
                )
            }
        }
    }

    private static func noteTitle(for captureDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "DoomsMoment \(formatter.string(from: captureDate))"
    }

    private static func displayPath(for directoryURL: URL) -> String {
        let path = directoryURL.path
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        guard path.hasPrefix(homePath) else { return path }

        let relativePath = String(path.dropFirst(homePath.count))
        return "~" + relativePath
    }

    private static func findLatestGeneratedFile(in directoryURL: URL) -> URL? {
        let fileManager = FileManager.default
        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        return fileURLs
            .filter { $0.pathExtension.lowercased() == "md" && $0.lastPathComponent.hasPrefix("DoomsMoment_") }
            .max { lhs, rhs in
                let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhsDate < rhsDate
            }
    }
}

@MainActor
final class MenuBarController: NSObject {
    private let logger = Logger(subsystem: "com.kika.Doom", category: "MenuBar")
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let viewModel: PopoverViewModel
    private let propertiesViewModel: PropertiesViewModel
    private lazy var contextMenu = makeContextMenu()
    private lazy var propertiesWindowController = makePropertiesWindowController()

    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyHandlerRef: EventHandlerRef?
    private var pulseTimer: Timer?
    private var popoverAutoCloseTask: Task<Void, Never>?
    private var showGeneratingIcon = false
    private var isPresentingContextMenu = false

    init(viewModel: PopoverViewModel, propertiesViewModel: PropertiesViewModel) {
        self.viewModel = viewModel
        self.propertiesViewModel = propertiesViewModel
        super.init()
        configureStatusItem()
        configurePopover()
        registerGlobalHotKey()
        viewModel.refreshLatestGeneratedFileURLFromDisk()
        viewModel.refreshPiecesAvailability()

        viewModel.onStatusChanged = { [weak self] in
            self?.handleStatusChange()
        }
    }

    deinit {
        pulseTimer?.invalidate()
        popoverAutoCloseTask?.cancel()

        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let hotKeyHandlerRef {
            RemoveEventHandler(hotKeyHandlerRef)
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        setIdleIcon()
        button.action = #selector(handleStatusItemClick(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        let hostingController = NSHostingController(rootView: DoomStatusView(viewModel: viewModel))
        hostingController.sizingOptions = .preferredContentSize
        popover.contentViewController = hostingController
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func closePopover() {
        popover.performClose(nil)
    }

    private func handleStatusChange() {
        popoverAutoCloseTask?.cancel()

        switch viewModel.doomsStatus {
        case .generating:
            startIconPulse()
            if isPresentingContextMenu == false {
                showPopover()
            }
        case .success, .error:
            stopIconPulse()
            guard isPresentingContextMenu == false else {
                closePopover()
                return
            }

            showPopover()
            popoverAutoCloseTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(5))
                guard let self else { return }
                guard self.isPresentingContextMenu == false else { return }
                self.closePopover()
            }
        case .idle:
            stopIconPulse()
            closePopover()
        }
    }

    private func startIconPulse() {
        guard let button = statusItem.button else { return }

        showGeneratingIcon = false
        applyThinkingIcon(to: button)
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let button = self.statusItem.button else { return }
                self.showGeneratingIcon.toggle()
                self.applyThinkingIcon(to: button)
            }
        }
    }

    private func stopIconPulse() {
        pulseTimer?.invalidate()
        pulseTimer = nil

        guard let button = statusItem.button else { return }
        button.alphaValue = 1.0
        showGeneratingIcon = false
        setIdleIcon()
    }

    private func setIdleIcon() {
        guard let button = statusItem.button else { return }

        let icon = NSImage(named: "MenuBarIconGenerating")
        icon?.size = NSSize(width: 18, height: 18)
        icon?.isTemplate = false
        button.image = icon
    }

    private func applyThinkingIcon(to button: NSStatusBarButton) {
        let iconName = showGeneratingIcon ? "MenuBarIconGenerating" : "MenuBarIcon"
        let icon = NSImage(named: iconName)
        icon?.size = NSSize(width: 18, height: 18)
        icon?.isTemplate = false
        button.image = icon
        button.alphaValue = 1.0
    }

    private func makePropertiesWindowController() -> NSWindowController {
        let hostingController = NSHostingController(rootView: PropertiesView(viewModel: propertiesViewModel))
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Doom Properties"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 460, height: 580))
        window.center()
        return NSWindowController(window: window)
    }

    private func registerGlobalHotKey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let callback: EventHandlerUPP = { _, eventRef, userData in
            guard let userData else { return noErr }

            let controller = Unmanaged<MenuBarController>.fromOpaque(userData).takeUnretainedValue()
            controller.handleHotKey(eventRef)
            return noErr
        }

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &hotKeyHandlerRef
        )

        guard installStatus == noErr else {
            logger.error("Failed to install hotkey handler: \(installStatus)")
            return
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x444F4F4D), id: UInt32(1))
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_Escape),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            logger.error("Failed to register global hotkey: \(registerStatus)")
        }
    }

    private func handleHotKey(_ eventRef: EventRef?) {
        viewModel.triggerDoomsMoment()
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()

        let modeItem = NSMenuItem(title: "Mode: \(viewModel.generationModeDisplayName)", action: nil, keyEquivalent: "")
        modeItem.isEnabled = false

        let exportItem = NSMenuItem(title: "Export: \(viewModel.exportPresetDisplayName)", action: nil, keyEquivalent: "")
        exportItem.isEnabled = false

        let piecesLabel = viewModel.hasCheckedPiecesAvailability
            ? (viewModel.isPiecesAvailable ? "Connected" : "Offline")
            : "Checking..."
        let piecesItem = NSMenuItem(title: "Pieces: \(piecesLabel)", action: nil, keyEquivalent: "")
        piecesItem.isEnabled = false

        let doomsTitle = viewModel.isGenerating ? "Generating..." : "Doom's Moment"
        let doomsItem = NSMenuItem(title: doomsTitle, action: #selector(handleDoomsMomentMenuItem(_:)), keyEquivalent: "")
        doomsItem.target = self
        doomsItem.isEnabled = viewModel.isGenerating == false
        configureMenuItemIcon(doomsItem, symbolName: viewModel.isGenerating ? "sparkles" : "bolt.circle")

        let latestItemTitle = (viewModel.supportsLatestFileActions && viewModel.latestGeneratedFileURL != nil)
            ? "Open Latest Doom's Moment"
            : "Open Latest Doom's Moment (No captures yet)"
        let latestItem = NSMenuItem(title: latestItemTitle, action: #selector(handleOpenLatestDoomsMomentMenuItem(_:)), keyEquivalent: "")
        latestItem.target = self
        latestItem.isEnabled = viewModel.latestGeneratedFileURL != nil && viewModel.supportsLatestFileActions
        configureMenuItemIcon(latestItem, symbolName: "doc.text")

        let revealExportFolderItem = NSMenuItem(title: "Reveal Export Folder", action: #selector(handleRevealExportFolderMenuItem(_:)), keyEquivalent: "")
        revealExportFolderItem.target = self
        configureMenuItemIcon(revealExportFolderItem, symbolName: "folder")

        let openNotesItem = NSMenuItem(title: "Open Doom Moments in Notes", action: #selector(handleOpenNotesMenuItem(_:)), keyEquivalent: "")
        openNotesItem.target = self
        configureMenuItemIcon(openNotesItem, symbolName: "note.text")

        let copyPathTitle = (viewModel.supportsLatestFileActions && viewModel.latestGeneratedFileURL != nil)
            ? "Copy Last Output Path"
            : "Copy Last Output Path (No captures yet)"
        let copyPathItem = NSMenuItem(title: copyPathTitle, action: #selector(handleCopyLastOutputPathMenuItem(_:)), keyEquivalent: "")
        copyPathItem.target = self
        copyPathItem.isEnabled = viewModel.latestGeneratedFileURL != nil && viewModel.supportsLatestFileActions
        configureMenuItemIcon(copyPathItem, symbolName: "link")

        let propertiesItem = NSMenuItem(title: "Properties", action: #selector(handlePropertiesMenuItem(_:)), keyEquivalent: "")
        propertiesItem.target = self
        configureMenuItemIcon(propertiesItem, symbolName: "slider.horizontal.3")

        let aboutItem = NSMenuItem(title: "About BreakPoint", action: #selector(handleAboutMenuItem(_:)), keyEquivalent: "")
        aboutItem.target = self
        configureMenuItemIcon(aboutItem, symbolName: "info.circle")

        let closeAppItem = NSMenuItem(title: "Close App", action: #selector(handleCloseAppMenuItem(_:)), keyEquivalent: "")
        closeAppItem.target = self
        configureMenuItemIcon(closeAppItem, symbolName: "xmark.circle")

        menu.items = [
            modeItem,
            exportItem,
            piecesItem,
            NSMenuItem.separator(),
            doomsItem,
            latestItem,
            revealExportFolderItem,
            openNotesItem,
            copyPathItem,
            NSMenuItem.separator(),
            aboutItem,
            propertiesItem,
            closeAppItem
        ]
        return menu
    }

    private func configureMenuItemIcon(_ item: NSMenuItem, symbolName: String) {
        let configuration = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular, scale: .medium)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: item.title)?
            .withSymbolConfiguration(configuration)
        image?.isTemplate = true
        item.image = image
    }

    @objc
    private func handleStatusItemClick(_ sender: AnyObject?) {
        guard isPresentingContextMenu == false else { return }

        guard let currentEvent = NSApp.currentEvent else {
            showContextMenu()
            return
        }

        if currentEvent.type == .rightMouseUp {
            showContextMenu()
        } else {
            // Left click triggers Doom's Moment directly
            viewModel.triggerDoomsMoment()
        }
    }

    private func showContextMenu() {
        guard isPresentingContextMenu == false else { return }
        guard let button = statusItem.button else { return }

        viewModel.refreshLatestGeneratedFileURLFromDisk()
        viewModel.refreshPiecesAvailability()
        popoverAutoCloseTask?.cancel()
        closePopover()
        contextMenu = makeContextMenu()
        contextMenu.delegate = self
        isPresentingContextMenu = true
        let menuOrigin = NSPoint(x: 0, y: button.bounds.maxY + 4)
        contextMenu.popUp(positioning: nil, at: menuOrigin, in: button)
    }

    @objc
    private func handleDoomsMomentMenuItem(_ sender: AnyObject?) {
        viewModel.triggerDoomsMoment()
    }

    @objc
    private func handleOpenLatestDoomsMomentMenuItem(_ sender: AnyObject?) {
        guard let fileURL = viewModel.latestGeneratedFileURL else { return }
        NSWorkspace.shared.open(fileURL)
    }

    @objc
    private func handleRevealExportFolderMenuItem(_ sender: AnyObject?) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: viewModel.exportDirectoryURL.path)
    }

    @objc
    private func handleOpenNotesMenuItem(_ sender: AnyObject?) {
        AppleNotesService.openDoomMoments()
    }

    @objc
    private func handleCopyLastOutputPathMenuItem(_ sender: AnyObject?) {
        guard let fileURL = viewModel.latestGeneratedFileURL else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fileURL.path, forType: .string)
    }

    @objc
    private func handlePropertiesMenuItem(_ sender: AnyObject?) {
        propertiesWindowController.showWindow(sender)
        propertiesWindowController.window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc
    private func handleAboutMenuItem(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel([
            NSApplication.AboutPanelOptionKey.applicationName: "BreakPoint",
            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(string: "made by kika")
        ])
    }

    @objc
    private func handleCloseAppMenuItem(_ sender: AnyObject?) {
        NSApp.terminate(sender)
    }
}

extension MenuBarController: NSMenuDelegate {
    func menuDidClose(_ menu: NSMenu) {
        guard menu === contextMenu else { return }
        isPresentingContextMenu = false
    }
}
