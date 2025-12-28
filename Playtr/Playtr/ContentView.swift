//
//  ContentView.swift
//  Playtr
//
//  Created by Neil Mussett on 12/27/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PlaybackViewModel()

    var body: some View {
        WebPlayerView(viewModel: viewModel)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
