//
//  SubtitlesConverter.swift
//  ani365
//
//  Created by p.flaks on 04.01.2024.
//

import ffmpegkit
import Foundation

enum SubtitlesConverterError: Error {
    case invalidURL
    case downloadFailed(error: Error?)
    case movingDownloadedFileToTemporaryDirectoryFailed(error: Error)
    case ffmpegFailedCreatingSession
    case ffmpegCancelledSession
    case ffmpegUnsuccessfulSessionReturnCode
    case ffmpegUnsuccessfulSessionUnknownError(
        sessionState: String,
        returnCodeDescription: String,
        sessionFailStackTrace: String
    )
}

enum SubtitlesInputFormat: String {
    case ass
}

enum SubtitlesOutputFormat: String {
    case vtt
}

final class SubtitlesConverter {
    public func convertAssSubtitlesToVtt(
        inputSubtitlesUrl: String,
        completion: @escaping (Result<String, SubtitlesConverterError>) -> Void
    ) {
        downloadSubtitlesFileToTemporaryDirectory(
            inputSubtitlesUrl: inputSubtitlesUrl,
            subtitlesInputFormat: .ass
        ) { (result: Result<String, SubtitlesConverterError>) in
            switch result {
            case .success(let inputSubtitlesPath):
                self.convertSubtitles(
                    inputSubtitlesPath: inputSubtitlesPath,
                    subtitlesOutputFormat: .vtt,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func downloadSubtitlesFileToTemporaryDirectory(
        inputSubtitlesUrl: String,
        subtitlesInputFormat: SubtitlesInputFormat,
        completion: @escaping (Result<String, SubtitlesConverterError>) -> Void
    ) {
        guard let subtitlesUrl = URL(string: inputSubtitlesUrl) else {
            completion(.failure(.invalidURL))
            return
        }

        let task = URLSession.shared.downloadTask(with: subtitlesUrl) { url, _, error in
            if let downloadedUrl = url {
                do {
                    let tempSubtitlesPath = NSTemporaryDirectory() + UUID().uuidString + "." + subtitlesInputFormat.rawValue

                    // Move the downloaded file to the temporary location
                    try FileManager.default.moveItem(
                        at: downloadedUrl,
                        to: URL(fileURLWithPath: tempSubtitlesPath)
                    )

                    completion(.success(tempSubtitlesPath))
                } catch {
                    completion(.failure(.movingDownloadedFileToTemporaryDirectoryFailed(error: error)))
                }
            } else {
                completion(.failure(.downloadFailed(error: error)))
            }
        }

        task.resume()
    }

    private func convertSubtitles(
        inputSubtitlesPath: String,
        subtitlesOutputFormat: SubtitlesOutputFormat,
        completion: @escaping (Result<String, SubtitlesConverterError>) -> Void
    ) {
        let tempSubtitlesPath = NSTemporaryDirectory() + UUID().uuidString + "." + subtitlesOutputFormat.rawValue

        let ffmpegCommand = "-i \"\(inputSubtitlesPath)\" \"\(tempSubtitlesPath)\""

        print("[SubtitlesConverter] Executing ffmpeg command: \(ffmpegCommand)")

        FFmpegKit.executeAsync(ffmpegCommand) { ffmpegSession in
            guard let ffmpegSession = ffmpegSession else {
                print("[SubtitlesConverter] Creating ffmpeg session failed")

                completion(.failure(.ffmpegFailedCreatingSession))
                return
            }

            guard let ffmpegSessionReturnCode = ffmpegSession.getReturnCode() else {
                completion(.failure(.ffmpegUnsuccessfulSessionReturnCode))

                return
            }

            if ReturnCode.isSuccess(ffmpegSessionReturnCode) {
                print("[SubtitlesConverter] ffmpeg converted file: \(tempSubtitlesPath)")

                completion(.success(tempSubtitlesPath))
                return

            } else if ReturnCode.isCancel(ffmpegSessionReturnCode) {
                print("[SubtitlesConverter] ffmpeg session cancelled")

                completion(.failure(.ffmpegCancelledSession))
                return
            }

            let ffmpegSessionFailureState = FFmpegKitConfig.sessionState(toString: ffmpegSession.getState()) ?? "Unknown"
            let ffmpegSessionReturnCodeDescription = ffmpegSessionReturnCode.description
            let ffmpegSessionFailStackTrace = ffmpegSession.getFailStackTrace() ?? "Unknown"

            print("[SubtitlesConverter] ffmpeg command failed: state: \(ffmpegSessionFailureState); return code: \(ffmpegSessionReturnCodeDescription); stack trace: \(ffmpegSessionFailStackTrace)")

            completion(.failure(.ffmpegUnsuccessfulSessionUnknownError(
                sessionState: ffmpegSessionFailureState,
                returnCodeDescription: ffmpegSessionReturnCodeDescription,
                sessionFailStackTrace: ffmpegSessionFailStackTrace
            )))
        } withLogCallback: { _ in
//            guard let logs = logs else { return }
            // CALLED WHEN SESSION PRINTS LOGS
        } withStatisticsCallback: { _ in
//            guard let stats = stats else { return }
            // CALLED WHEN SESSION GENERATES STATISTICS
        }
    }
}
