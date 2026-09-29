import Foundation

enum PetScaleMode: Double, CaseIterable, Sendable {
    case half = 0.5
    case full = 1.0

    var label: String {
        self == .half ? "0.5x" : "1x"
    }

    var next: PetScaleMode {
        self == .half ? .full : .half
    }
}
