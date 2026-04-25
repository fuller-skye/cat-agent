//
//  agentkittenApp.swift
//  agentkitten
//

import SwiftUI
import AppKit
import Combine

@main
struct agentkittenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var kittenWindow: NSPanel?
    var kittenState = KittenState()

    private var walkTimer: Timer?
    private var frameTimer: Timer?
    private let kittenWidth: CGFloat = 180
    private let kittenHeight: CGFloat = 140
    private let walkSpeed: CGFloat = 50
    private var lastTick: Date = Date()

    private var jazzWorkItem: DispatchWorkItem?
    private var bubbleWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()

    private let workingMessages = ["kitten writing", "kitten do big math", "kitten is obviously best"]
    private let jazzMessages = ["AAAHHHH!!!", "meow meow meow", "work"]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupKittenWindow()
        startWalking()
        setupJazzTriggers()
        setupSpeechBubble()
    }

    // MARK: - Window

    func setupKittenWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: kittenWidth, height: kittenHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]

        if let screen = NSScreen.main {
            let dockTop = screen.visibleFrame.minY
            let startX = screen.frame.midX - kittenWidth / 2
            panel.setFrameOrigin(NSPoint(x: startX, y: dockTop))
            kittenState.positionX = startX
            kittenState.screenBounds = screen.frame
            kittenState.dockY = dockTop
        }

        let contentView = NSHostingView(rootView: KittenView(state: kittenState))
        contentView.frame = panel.contentView!.bounds
        contentView.autoresizingMask = [.width, .height]
        panel.contentView = contentView

        panel.makeKeyAndOrderFront(nil)
        kittenWindow = panel
    }

    // MARK: - Walk

    func startWalking() {
        lastTick = Date()

        walkTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
        frameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 10.0, repeats: true) { [weak self] _ in
            self?.updateFrame()
        }
    }

    private func updatePosition() {
        let now = Date()
        defer { lastTick = now }
        guard !kittenState.isChatOpen, !kittenState.isJazzing else { return }

        let dt = now.timeIntervalSince(lastTick)
        let screen = kittenState.screenBounds
        let maxX = screen.maxX - kittenWidth

        kittenState.positionX += CGFloat(dt) * walkSpeed * kittenState.direction

        if kittenState.positionX >= maxX {
            kittenState.positionX = maxX
            kittenState.direction = -1
        } else if kittenState.positionX <= screen.minX {
            kittenState.positionX = screen.minX
            kittenState.direction = 1
        }

        kittenWindow?.setFrameOrigin(NSPoint(x: kittenState.positionX, y: kittenState.dockY))
    }

    private func updateFrame() {
        if kittenState.isJazzing {
            kittenState.jazzFrameIndex = (kittenState.jazzFrameIndex + 1) % 3
        } else if !kittenState.isChatOpen {
            kittenState.walkFrameIndex = (kittenState.walkFrameIndex + 1) % 3
        }
    }

    // MARK: - Jazz

    private func setupJazzTriggers() {
        // Jazz when a Claude task finishes
        kittenState.session.$isRunning
            .removeDuplicates()
            .dropFirst()                    // skip the initial false
            .filter { !$0 }                 // only when it becomes false (task done)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.startJazz(duration: 3.0) }
            .store(in: &cancellables)

        // Random jazz while idle
        scheduleRandomJazz()
    }

    private func setupSpeechBubble() {
        kittenState.session.$isRunning
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] running in
                guard let self else { return }
                self.bubbleWorkItem?.cancel()
                if running {
                    withAnimation {
                        self.kittenState.speechBubble = self.workingMessages.randomElement()!
                    }
                } else {
                    withAnimation {
                        self.kittenState.speechBubble = "kitten done!"
                    }
                    let work = DispatchWorkItem { [weak self] in
                        withAnimation { self?.kittenState.speechBubble = nil }
                    }
                    self.bubbleWorkItem = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: work)
                }
            }
            .store(in: &cancellables)
    }

    func startJazz(duration: TimeInterval) {
        guard !kittenState.isJazzing else { return }
        kittenState.isJazzing = true

        jazzWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.kittenState.isJazzing = false
        }
        jazzWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

    private func scheduleRandomJazz() {
        let delay = Double.random(in: 15...45)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            if !self.kittenState.isChatOpen {
                self.startJazz(duration: 2.0)
                withAnimation { self.kittenState.speechBubble = self.jazzMessages.randomElement()! }
                self.bubbleWorkItem?.cancel()
                let work = DispatchWorkItem { [weak self] in
                    withAnimation { self?.kittenState.speechBubble = nil }
                }
                self.bubbleWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
            }
            self.scheduleRandomJazz()
        }
    }
}
