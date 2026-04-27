import SwiftUI

#if os(iOS)
import UIKit
#else
import AppKit
#endif

enum SharePresenter {
    static func share(text: String) {
        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return
        }

        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        root.present(controller, animated: true)
        #else
        guard let window = NSApp.keyWindow,
              let contentView = window.contentView else {
            return
        }

        let picker = NSSharingServicePicker(items: [text])
        picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
        #endif
    }

    static func shareFile(url: URL) {
        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.excludedActivityTypes = [.addToReadingList, .assignToContact]
        root.present(controller, animated: true)
        #endif
    }
}
