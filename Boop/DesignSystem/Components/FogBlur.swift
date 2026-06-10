import CoreGraphics

/// Maps a comfort score (0–100) and match stage to a blur radius, so faces
/// visibly sharpen as a connection grows. Revealed/dating = fully clear.
///
/// Expected values (verified by reasoning):
///   stage "revealed"/"dating" → 0
///   comfort nil/0  → 30   (heavy fog)
///   comfort 35     → ~20
///   comfort 70     → ~10  (reveal threshold — hazy; full clarity comes at reveal via stage)
///   comfort 100    → 2
enum FogBlur {
    static func radius(forComfort comfort: Int?, stage: String?) -> CGFloat {
        if stage == "revealed" || stage == "dating" { return 0 }
        let c = max(0, min(100, comfort ?? 0))
        // Linear: 0 → 30, 100 → 2.
        let radius = 30.0 - (CGFloat(c) / 100.0) * 28.0
        return max(2, radius)
    }
}
