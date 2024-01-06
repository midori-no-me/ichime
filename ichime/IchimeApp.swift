//
//  IchimeApp.swift
//  Ichime
//
//  Created by p.flaks on 01.01.2024.
//
import DITranquillity
import ScraperAPI
import SwiftUI

@main
struct IchimeApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    VideoPlayerController.enableBackgroundMode()
                }
        }
    }
}
