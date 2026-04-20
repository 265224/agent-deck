import AppKit
import SwiftUI

struct MenuBarBearIcon: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let image = Self.templateImage {
                Image(nsImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .interpolation(.high)
            } else {
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: size, weight: .regular))
            }
        }
        .frame(width: size, height: size)
    }

    private static let templateImage: NSImage? = {
        let logicalSize = NSSize(width: 18, height: 18)
        let image = NSImage(size: logicalSize)

        addRepresentation(named: "menubar-bear", to: image, logicalSize: logicalSize)
        addRepresentation(named: "menubar-bear@2x", to: image, logicalSize: logicalSize)

        guard !image.representations.isEmpty else {
            return nil
        }

        image.isTemplate = true
        image.accessibilityDescription = "Agent Deck"
        return image
    }()

    private static func addRepresentation(named name: String, to image: NSImage, logicalSize: NSSize) {
        let url = Bundle.appResources.url(forResource: name, withExtension: "png", subdirectory: "MenuBarBear")
            ?? Bundle.appResources.url(forResource: name, withExtension: "png")

        guard let url,
              let data = try? Data(contentsOf: url),
              let representation = NSBitmapImageRep(data: data)
        else {
            return
        }

        representation.size = logicalSize
        image.addRepresentation(representation)
    }
}
