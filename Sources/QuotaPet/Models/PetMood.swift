import QuotaPetCore

enum PetMood: Equatable {
    case normal, worried, tired, sleeping, offline

    init(window: QuotaWindow?) {
        guard let remaining = window?.remainingPercent else { self = .offline; return }
        switch remaining {
        case 0: self = .sleeping
        case ...20: self = .tired
        case ...50: self = .worried
        default: self = .normal
        }
    }
}
