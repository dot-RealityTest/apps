import AppKit
import SwiftUI

struct AnimatedGIFView: NSViewRepresentable {
    let resourceName: String

    func makeNSView(context: Context) -> GIFContainerView {
        let container = GIFContainerView()
        container.imageView.imageScaling = .scaleProportionallyUpOrDown
        container.imageView.imageAlignment = .alignCenter
        container.imageView.animates = true
        return container
    }

    func updateNSView(_ nsView: GIFContainerView, context: Context) {
        guard let image = Self.loadGIF(named: resourceName) else { return }
        nsView.imageView.image = image
    }

    private static func loadGIF(named resourceName: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "gif") else {
            return nil
        }

        let image = NSImage(contentsOf: url)
        image?.isTemplate = false
        return image
    }
}

final class GIFContainerView: NSView {
    let imageView = NSImageView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }
}
