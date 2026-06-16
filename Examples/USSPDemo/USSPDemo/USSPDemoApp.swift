//
//  USSPDemoApp.swift
//  USSPDemo
//
//  Created by 今浦大雅 on 2026/03/07.
//

import SwiftUI

@main
struct USSPDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 500)
        #elseif os(visionOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 800)
        #endif
        
        #if os(macOS) || os(visionOS)
        Window("Build Mode", id: "BuildMode") {
            #if os(macOS)
            BuildModeView()
                .frame(minWidth: 500, minHeight: 300)
            #elseif os(visionOS)
            BuildModeView()
                .frame(minWidth: 500, maxWidth: 1500, minHeight: 300, maxHeight: 1200)
            #endif
        }
        .windowResizability(.contentMinSize)
        #if os(macOS)
        .defaultSize(width: 900, height: 600)
        #elseif os(visionOS)
        .defaultSize(width: 1000, height: 700)
        #endif
        #endif
    }
}
