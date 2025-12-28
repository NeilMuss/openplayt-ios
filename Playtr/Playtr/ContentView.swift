//
//  ContentView.swift
//  Playtr
//
//  Created by Neil Mussett on 12/27/25.
//

import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PlaybackViewModel()

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(viewModel.nowPlayingTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                Text(viewModel.nowPlayingArtist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(statusLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                Button(action: viewModel.previous) {
                    Image(systemName: "backward.fill")
                }
                Button(action: viewModel.togglePlayPause) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                }
                Button(action: viewModel.next) {
                    Image(systemName: "forward.fill")
                }
            }
            .font(.title2)

            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { viewModel.position },
                        set: { viewModel.seek(to: $0) }
                    ),
                    in: 0...240
                )
                Text("Position: \(Int(viewModel.position))s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(viewModel.volume) },
                        set: { viewModel.setVolume(Float($0)) }
                    ),
                    in: 0...1
                )
                Text("Volume: \(Int(viewModel.volume * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Reload Sample Queue") {
                viewModel.loadSampleQueue()
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var statusLabel: String {
        let state: String
        switch viewModel.status {
        case .idle:
            state = "Idle"
        case .playing:
            state = "Playing"
        case .paused:
            state = "Paused"
        case .stopped:
            state = "Stopped"
        }
        return viewModel.isQueueEnded ? "\(state) • Queue Ended" : state
    }
}

#Preview {
    ContentView()
}
