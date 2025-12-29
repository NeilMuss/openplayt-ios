import SwiftUI

struct PlaytArchiveBrowserView: View {
    @ObservedObject var viewModel: PlaybackViewModel
    @State private var cartridges: [PlaytArchiveCartridge] = []
    @State private var errorMessage: String?
    @State private var selectedSource: ArchiveSource = .bundledTestArchive

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                ForEach(cartridges) { cartridge in
                    NavigationLink(value: cartridge) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cartridge.title)
                                .font(.headline)
                            Text(cartridge.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Library", selection: $selectedSource) {
                        ForEach(ArchiveSource.allCases) { source in
                            Text(source.displayName).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationDestination(for: PlaytArchiveCartridge.self) { cartridge in
                PlaytArchiveDetailView(viewModel: viewModel, cartridge: cartridge)
            }
        }
        .task {
            await loadCartridges()
        }
        .onChange(of: selectedSource) { _ in
            Task {
                await loadCartridges()
            }
        }
    }

    private func loadCartridges() async {
        do {
            let library = PlaytLibrary.shared
            let ids = try library.listCartridgeIDs(source: selectedSource)
            let items = try ids.map { id -> PlaytArchiveCartridge in
                try library.loadCartridge(source: selectedSource, cartridgeID: id)
            }
            cartridges = items.sorted { $0.title < $1.title }
            errorMessage = nil
        } catch {
            cartridges = []
            errorMessage = "Failed to load library: \(error.localizedDescription)"
        }
    }
}

private struct PlaytArchiveDetailView: View {
    @ObservedObject var viewModel: PlaybackViewModel
    let cartridge: PlaytArchiveCartridge
    @State private var installMessage: String?
    @State private var didLoadQueue = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cartridge.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(cartridge.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Cartridge \(cartridge.cartridgeID)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("Load Album into Player") {
                    viewModel.loadArchiveQueue(from: cartridge)
                }
                .buttonStyle(.borderedProminent)

                if cartridge.source == .bundledTestArchive {
                    Button("Install Album to Local Library") {
                        installToLocal()
                    }
                    .buttonStyle(.bordered)
                }

                if let installMessage {
                    Text(installMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let playbackError = viewModel.playbackError {
                    Text(playbackError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                WebPlayerView(viewModel: viewModel)
                    .frame(height: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tracks")
                        .font(.headline)
                    ForEach(cartridge.tracks) { track in
                        Text("\(track.number). \(track.title)")
                            .font(.subheadline)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Album")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !didLoadQueue {
                viewModel.loadArchiveQueue(from: cartridge)
                didLoadQueue = true
            }
        }
    }

    private func installToLocal() {
        do {
            try PlaytLibrary.shared.installBundledCartridgeToLocal(cartridgeID: cartridge.cartridgeID)
            installMessage = "Installed to Local Library."
        } catch {
            installMessage = "Install failed: \(error.localizedDescription)"
        }
    }
}
