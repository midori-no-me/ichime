//
//  VideoModel.swift
//  Ichime
//
//  Created by Nikita Nafranets on 23.03.2024.
//
import AVFoundation
import Foundation

struct VideoModel {
    let videoURL: URL
    let subtitleURL: URL?

    let title: String?
    let subtitle: String?
    let description: String?
}
