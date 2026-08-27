//
//  USSPDemoApp.swift
//  USSPDemo
//
//  Created by 今浦大雅 on 2026/03/07.
//

import SwiftUI
#if os(macOS)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
#endif

@main
struct USSPDemoApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                .onDisappear {
                    NSApplication.shared.terminate(nil)
                }
                #endif
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 450, height: 500)
        #elseif os(visionOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 800)
        #endif
        
        #if os(macOS)
        Window("Build Mode", id: "BuildMode") {
            BuildModeView()
                .frame(minWidth: 500, minHeight: 300)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 900, height: 600)
        #endif
    }
}
