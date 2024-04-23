import Foundation
import UIKit

public protocol GistViewDelegate: AnyObject {
    func action(message: Message, currentRoute: String, action: String, name: String)
    func sizeChanged(message: Message, width: CGFloat, height: CGFloat)
}

/*
 Note: The modifications done to GistView are done for POC purposes to get an inline in-app displayed in an app's UI. In the feature implementation, we may not actually write this code inside of this class.

 This class does represent a UIView subclass that can display a WebView with adjustable height to the web content aspect ratio, just like the requirements of inline in-app messages.
 */
public class GistView: UIView, EngineWebDelegate {
    var heightConstraint: NSLayoutConstraint!

    public func bootstrapped() {}

    public func tap(name: String, action: String, system: Bool) {}

    public func routeChanged(newRoute: String) {}

    public func routeError(route: String) {}

    public func routeLoaded(route: String) {}

    // This function is called by WebView when the content's size changes.
    public func sizeChanged(width: CGFloat, height: CGFloat) {
        // We keep the width the same to what the customer set it as.
        // Update the height to match the aspect ratio of the web content.
        heightConstraint.constant = height

        superview?.updateConstraints()
    }

    public func error() {}

    var message: Message?
    weak var delegate: GistViewDelegate?

    public func startItUp() {
        // The Engine is hard-coded with 1 URL to load for an in-app message to display.
        // Construct an instance of this hard-coded Engine and set it to display the content in this UIView.
        let engine = EngineWeb(configuration: nil)
        engine.delegate = self
        let engineView = engine.view

        // Setup an autolayout constraint that we can dynamically update as the web content changes.
        heightConstraint = heightAnchor.constraint(equalToConstant: frame.height)
        NSLayoutConstraint.activate([heightConstraint])

        addSubview(engineView)
        engineView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleBottomMargin, .flexibleRightMargin]
    }

    override public func removeFromSuperview() {
        super.removeFromSuperview()
        if let message = message {
            Gist.shared.removeMessageManager(instanceId: message.instanceId)
        }
    }
}
