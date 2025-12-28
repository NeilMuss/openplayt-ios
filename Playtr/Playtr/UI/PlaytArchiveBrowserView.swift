import SwiftUI

struct PlaytArchiveBrowserView: View {
    @ObservedObject var viewModel: PlaybackViewModel
    @State private var cartridges: [PlaytArchiveCartridge] = []
    @State private var errorMessage: String?

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
            .navigationTitle("Test Library")
            .navigationDestination(for: PlaytArchiveCartridge.self) { cartridge in
                PlaytArchiveDetailView(viewModel: viewModel, cartridge: cartridge)
            }
        }
        .task {
            await loadCartridges()
        }
    }

    private func loadCartridges() async {
        do {
            let ids = try TestPlaytArchive.listCartridgeIDs()
            let decoder = JSONDecoder()
            let items = try ids.map { id -> PlaytArchiveCartridge in
                let data = try TestPlaytArchive.loadPlaytJSON(cartridgeID: id)
                return try decoder.decode(PlaytArchiveCartridge.self, from: data)
            }
            cartridges = items.sorted { $0.title < $1.title }
            errorMessage = nil
        } catch {
            cartridges = []
            errorMessage = "Failed to load TestPlaytArchive: \(error.localizedDescription)"
        }
    }
}

private struct PlaytArchiveDetailView: View {
    @ObservedObject var viewModel: PlaybackViewModel
    let cartridge: PlaytArchiveCartridge

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
    }
}
