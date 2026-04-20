import CoreText
import SwiftUI

enum DepartureMono {
    static let postScriptName = "DepartureMono-Regular"

    static func registerBundledFont() {
        guard let fontURL = Bundle.appResources.url(
            forResource: "DepartureMono-Regular",
            withExtension: "otf",
            subdirectory: "Fonts"
        ) else {
            return
        }

        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}

extension Font {
    static func departureMono(size: CGFloat) -> Font {
        .custom(DepartureMono.postScriptName, fixedSize: size)
    }
}
