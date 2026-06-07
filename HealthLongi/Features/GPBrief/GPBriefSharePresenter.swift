import UIKit

enum GPBriefSharePresenter {
    static func sharePDF(from brief: GPVisitBrief) {
        let data = GPBriefPDFRenderer.render(brief)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GPVisitBrief-\(UUID().uuidString).pdf")

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return
        }

        share(url: url)
    }

    private static func share(url: URL) {
        guard let presenter = topViewController() else { return }

        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        configurePopover(activity, on: presenter)
        presenter.present(activity, animated: true)
    }

    private static func topViewController(from base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? keyWindow?.rootViewController
        if let navigation = root as? UINavigationController {
            return topViewController(from: navigation.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }
        return root
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    private static func configurePopover(
        _ activity: UIActivityViewController,
        on presenter: UIViewController
    ) {
        guard let popover = activity.popoverPresentationController else { return }
        popover.sourceView = presenter.view
        popover.sourceRect = CGRect(
            x: presenter.view.bounds.midX,
            y: presenter.view.bounds.midY,
            width: 0,
            height: 0
        )
        popover.permittedArrowDirections = []
    }
}
