import Foundation

final class PlaybackSession {
    var machine: PlaybackStateMachine

    init(machine: PlaybackStateMachine) {
        self.machine = machine
    }

    convenience init() {
        self.init(machine: PlaybackStateMachine())
    }
}
