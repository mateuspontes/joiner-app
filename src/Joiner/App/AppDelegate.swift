import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var preferencesWindowController: PreferencesWindowController?

    // Core state
    let appState = AppState()
    let eventKitService = EventKitService()
    private var syncService: CalendarSyncService!
    private var syncScheduler: SyncScheduler!
    private var menuBarViewModel: MenuBarViewModel!
    private var statusItemViewModel = StatusItemViewModel()
    private(set) var preferencesViewModel: PreferencesViewModel!

    // Observation
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        DismissedEventsStore.cleanupOldKeys()

        // Initialize services
        syncService = CalendarSyncService(eventKitService: eventKitService)
        syncScheduler = SyncScheduler(syncService: syncService, appState: appState)
        menuBarViewModel = MenuBarViewModel(appState: appState)
        preferencesViewModel = PreferencesViewModel(eventKitService: eventKitService)
        preferencesViewModel.onCalendarVisibilityChanged = { [weak self] in
            self?.syncScheduler.syncNow()
        }

        // React to system calendar changes
        eventKitService.onCalendarChanged = { [weak self] in
            self?.syncScheduler.syncNow()
        }

        // Configure notifications
        NotificationService.shared.configure()

        // Setup UI
        setupStatusItem()
        setupPopover()

        // Bind status item to state
        statusItemViewModel.bind(to: appState)

        // Request EventKit access and start sync
        Task {
            let granted = await eventKitService.requestAccess()
            if granted {
                syncScheduler.start()
            }
        }

        // Observe state changes to update status item
        observeStateChanges()
    }

    func applicationWillTerminate(_ notification: Notification) {
        syncScheduler?.stop()
        eventKitService.stopMonitoring()
        statusItemViewModel.stopMonitoring()
        menuBarViewModel?.stopRefreshing()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateStatusButton()
        }
    }

    private func updateStatusButton() {
        guard let button = statusItem.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let image = NSImage(
            systemSymbolName: "video.fill",
            accessibilityDescription: "Joiner"
        )?.withSymbolConfiguration(config)

        if statusItemViewModel.isOverdue {
            button.contentTintColor = .red
        } else {
            button.contentTintColor = nil
        }

        button.image = statusItemViewModel.showIcon ? image : nil

        // Countdown label
        if let countdown = statusItemViewModel.countdownText {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: statusItemViewModel.isOverdue ? NSColor.red : NSColor.labelColor,
            ]
            button.attributedTitle = NSAttributedString(string: " \(countdown)", attributes: attrs)
        } else {
            button.title = ""
        }
    }

    private func observeStateChanges() {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.updateStatusButton() }
            .store(in: &cancellables)
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 500)
        popover.behavior = .transient
        popover.animates = true

        let contentView = PopoverContentView(
            viewModel: menuBarViewModel,
            onSyncRequest: { [weak self] in
                self?.syncScheduler.syncNow()
            },
            onOpenPreferences: { [weak self] in
                self?.openPreferences()
            }
        )

        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            menuBarViewModel.refresh()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Preferences

    func openPreferences() {
        popover.performClose(nil)

        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(viewModel: preferencesViewModel)
        }

        NSApp.activate(ignoringOtherApps: true)
        preferencesWindowController?.show()
    }
}
