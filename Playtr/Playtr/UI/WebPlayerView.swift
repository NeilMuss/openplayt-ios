import SwiftUI
import WebKit

struct WebPlayerView: UIViewRepresentable {
    @ObservedObject var viewModel: PlaybackViewModel

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "playPause")
        contentController.add(context.coordinator, name: "next")
        contentController.add(context.coordinator, name: "previous")
        contentController.add(context.coordinator, name: "seek")
        contentController.add(context.coordinator, name: "volume")
        contentController.add(context.coordinator, name: "reloadSample")
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear

        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        pushState(to: webView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    private func pushState(to webView: WKWebView) {
        let payload: [String: Any] = [
            "title": viewModel.nowPlayingTitle,
            "artist": viewModel.nowPlayingArtist,
            "status": statusString(viewModel.status),
            "position": viewModel.position,
            "volume": viewModel.volume,
            "queueEnded": viewModel.isQueueEnded
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        webView.evaluateJavaScript("window.playt && playt.updateState(\(json));", completionHandler: nil)
    }

    private func statusString(_ status: PlaybackStatus) -> String {
        switch status {
        case .idle:
            return "Idle"
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .stopped:
            return "Stopped"
        }
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        private let viewModel: PlaybackViewModel

        init(viewModel: PlaybackViewModel) {
            self.viewModel = viewModel
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
            case "playPause":
                viewModel.togglePlayPause()
            case "next":
                viewModel.next()
            case "previous":
                viewModel.previous()
            case "seek":
                if let value = message.body as? Double {
                    viewModel.seek(to: value)
                } else if let payload = message.body as? [String: Any],
                          let value = payload["value"] as? Double {
                    viewModel.seek(to: value)
                }
            case "volume":
                if let value = message.body as? Double {
                    viewModel.setVolume(Float(value))
                } else if let payload = message.body as? [String: Any],
                          let value = payload["value"] as? Double {
                    viewModel.setVolume(Float(value))
                }
            case "reloadSample":
                viewModel.loadSampleQueue()
            default:
                break
            }
        }
    }
}
