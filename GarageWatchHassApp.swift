//
//  GarageWatchHassApp.swift
//  GarageWatchHass Watch App
//
//  Created by Michel Lapointe on 2024-01-23.
//

import SwiftUI

@main
struct GarageWatchHassApp: App {
    @StateObject var watchViewModel = WatchManager()
    var body: some Scene {
        WindowGroup {
            WatchView(watchViewModel: watchViewModel)
        }
    }
}
