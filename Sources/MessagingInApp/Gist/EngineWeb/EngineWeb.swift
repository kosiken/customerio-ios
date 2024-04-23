import Foundation
import UIKit
import WebKit

public protocol EngineWebDelegate: AnyObject {
    func bootstrapped()
    func tap(name: String, action: String, system: Bool)
    func routeChanged(newRoute: String)
    func routeError(route: String)
    func routeLoaded(route: String)
    func sizeChanged(width: CGFloat, height: CGFloat)
    func error()
}

public class EngineWeb: NSObject {
    private var _currentRoute = ""
    private var _timeoutTimer: Timer?
    private var _elapsedTimer = ElapsedTimer()

    public weak var delegate: EngineWebDelegate?
    var webView = WKWebView()

    public var view: UIView {
        webView
    }

    public private(set) var currentRoute: String {
        get {
            _currentRoute
        }
        set {
            _currentRoute = newValue
        }
    }

    /*
     Modified this function to not parse an in-app message but instead have a hard-coded in-app message.
     */
    init(configuration: EngineWebConfiguration?) {
        super.init()

        _elapsedTimer.start(title: "Engine render for message: ")

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear

        let js = "window.parent.postMessage = function(message) {webkit.messageHandlers.gist.postMessage(message)}"
        let messageHandlerScript = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)

        webView.configuration.userContentController.add(self, name: "gist")
        webView.configuration.userContentController.addUserScript(messageHandlerScript)

        if #available(iOS 11.0, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        }

        if true {
            // URL to a small in-app message
            let url = "https://renderer.gist.build/2.0/index.html?options=eyJzaXRlSWQiOiJkNTQ1ODJkYTUzZWQ5NmQ4MjRlZiIsImluc3RhbmNlSWQiOiI3MWQzMGZjMi0wNDUwLTQ2MGUtOWQyNC00OGI0NDljZjMzY2UiLCJtZXNzYWdlSWQiOiJnaXN0LWh0bWwtMDFIVzNENE5RVDNWTTdaWUdKTUhON05RME4iLCJsaXZlUHJldmlldyI6ZmFsc2UsImRhdGFDZW50ZXIiOiJVUyIsImVuZHBvaW50IjoiaHR0cHM6XC9cL2VuZ2luZS5hcGkuZ2lzdC5idWlsZCIsInByb3BlcnRpZXMiOnsiZ2lzdCI6eyJwb3NpdGlvbiI6InRvcCIsImVuY29kZWRNZXNzYWdlSHRtbCI6Ikg0c0lBQUFBQUFBQVwvOVJYeTI3clJnXC9lNXlsNDlPTUhUb0RJa3AzTFNSVTVRSEdBNGl4YW9JdFRkRTFKbERUMWFDak1qR3lyUlorZ3F6NUJYN0dQVU9oaVoyUmJTZEJkczBna2trTitcL0hqUkpQNlFjV3JibXFDMGxYeStpcnNcL0lGRVZhNCtVOTN3RkVKZUVXZmNBRUZka0VkSVN0U0c3OW43NitwM1wvNkVIZ0tQc25BSVVWcmIydG9GM04ybnFqTkdWbFNkbTF0eE9aTGRjWmJVVktmdjl5QTBJSksxRDZKa1ZKNitVaXZJRUs5NkpxS2xmVUdOTDlPeWFTMXVIZytRREFDaXZwK1dlU0tWY0VQNUF4V0ZBY0RPTEJ4TmoyOEF3UWFXWUx2NDF2QUw2ZllMb3BORGNxODFPV3JDUDRYNTduVDQ1RlI0WlF4VkY5ZTN2cnFpM3Q3VkgzOFBEZzZtb3RLdFN0bnpUV3NqcGFoZUg5cFwvVHVMVU9cLzVDME41bmNQR0w1aVBvRndndDZVbVBIT0NkMzlMTkUxeVprdDZha1hYT0lxV1Iyc2ZyOGFIXC9wZWVhR3ZBMmhTelZMNkNaVzRGZDFaeFlwZTNLZU5OcDAwb3h3YmFjODhKcHkxanNlY2xmVnpySVJzSVwvaFdDNVEzWUZBWjM1QVdUbUlWNmtLb0NNSjZmdzV5NlRpOFlEaEdNZUpYaW1EMTZDcWtVT1NYSklyU1JyQmNyTzZkUkFabXRxZ1wvbnZURTlSbUMyZ0V3T2ZmQzhmVkZOTXVIV1RTcnV3dXBMcXFoNWYxY1kwVk8xUE8ySGdDY3loMFlDZXVNdEs4eEU0MkpZTUxMZ2NXSk1PSDkyRjRSaExDcTkzQlg3OGM0YnR1ZDgzT0VQZTRINHlDdk1ldW9uU1k4SmVtMWtzMVY3QUx6TDNBd3RZTFZPRTRPRnBReWdrWVpzazl2TW50cGhOXC9KYmlaTUxiR05JSmZraUg5cGpCVjVleUFwZ3BTVUpYMCtXeldMcWNKcVZFWjBPVVZuZUNGYzNCb2dOTTZROWdzNWdtVVlcL3Y4TmNxSitLYjJqMGVZMzJqelwvWFkxT2Q4R2xrcjhXYUg3Q2RtT1BKQ3l6cFwvTjJjMGZ2aUd4WWpRNm1mMXNxbEtKUXZyQlVtWFBsc1hzdnpKeHZ1VDdkQzZNbVlXdTVpc0JcL25FYyt1NG5PbHY3TVFscWREZUdCeDdzd25KdkNTM25vOGRRODFvWGtnbnNLVWFnSjZ3WFdrNU96ZFhpRjVyZWlTVXhJXC9vZlpFbFhob04rU3RpSkY2ZmVNUkZDSkxKTjBvZVZXYm9UdWR4d2NiMHpqM2VrZ2dUZzRYQXpqN3JNOVhyQXlzWVZVb2pGcmJcL0kxOGc2WHJrc1doOFZcL05KcWFhZDQ1bXU1R3VueisrNjhcL1wvNEF2MUlJdFNkT0hPQ2lYenVFZ0U5dDMrcXJkTjRDdkphb050TnhBemhyU2t0a0lWUUEzR21yTldaUGFCWHpCTFFHQ1pONEE5dHV1dTZ0dWFPS281VVlia2ptZ2hiSzdqNkxLUU9TOWEwV1VBYW9XMEJoaExLcVVicUNXM1JvR1NSWWFBeHZGdTRXTE02am44eHUybldNOUpqdFoxcDZqWlwvVlppblJ6ck1BaUU2WVN4bnk4ZHExUUNcL1Q3U1ZoN24xbFpvUnA2MFU5WU5EV3FrNmpkZUhqUGNEall0VktOeWsxaXdPVklobVkrS2MrUHZDTk5HU1R0aElOcFdhZnQ3MDFyR291cW1BZ0FqRTdYWG1sdGJhSWdNSloxUjBMQlhFakNXcGhGeWxXUUN2YUY4ckd1ZlV0VkxkR1NDZEFZc3FiWDlURXJWdXpualpRTFhIM0M5RDc4Wm1HMmhYY1NEcVZkZTk5endWTkZNRW5ucEtqQmxBMUhmWHlNZzJIeTRxRFwvNysyZkFBQUFcL1wvOGNqMnlXelEwQUFBPT0ifX19"

            // URL to a large in-app message (bigger height)
//        let url = "https://code.gist.build/renderer/0.2.15/index.html?options=eyJzaXRlSWQiOiJkNTQ1ODJkYTUzZWQ5NmQ4MjRlZiIsImluc3RhbmNlSWQiOiIzM2IyOGZiMy04MWQwLTQ4NGItYTBhMi02ODE2OTRlZTg5ZmIiLCJtZXNzYWdlSWQiOiJnaXN0LWh0bWwtMDFIVzNEQ1dIMDlNVFBWMzZOUUZKRjBRNjUiLCJsaXZlUHJldmlldyI6ZmFsc2UsImRhdGFDZW50ZXIiOiJVUyIsImVuZHBvaW50IjoiaHR0cHM6XC9cL2VuZ2luZS5hcGkuZ2lzdC5idWlsZCIsInByb3BlcnRpZXMiOnsiZ2lzdCI6eyJwb3NpdGlvbiI6InRvcCIsImVuY29kZWRNZXNzYWdlSHRtbCI6Ikg0c0lBQUFBQUFBQVwvK3hZelc3anRoT1wvNzFQTTZvOFwvc0F0RWx1eDhiS3JJQVlvRmlqMjBRQTliOUR5U1JoSnJpaU9RbEcyMTZCUDAxQ2ZvS1wvWVJDbjNZb1N3N0NYb3JrQndTYW1iSStmRTNIeHdrZnA5eGF0dWFvTFNWZkh3WGQzOUFvaXJXSGludjhSMUFYQkptM1FJZ3JzZ2lwQ1ZxUTNidFwvZlQxT1wvXC9lZzhCUjlpc0FoUld0dmEyZ1hjM2FlcU0wWldWSjJiVzNFNWt0MXhsdFJVcCtcLzNFRlFna3JVUG9tUlVucjVTSzhnZ3Izb21vcVY5UVkwdjAzSnBMVzRYRHlBWUFWVnRManp5UlRyZ2grSUdPd29EZ1l4SU9Kc2UxaERSQnBaZ3VcL2pWOEF2cDlndWlrME55cnpVNWFzSVwvaGZudWNQamtWSGhsREZVWDE5ZmUycUxlM3RVWGQzZCtmcWFpMHExSzJmTk5heU9scUY0ZTJuOU9ZbFE3XC9rTFEzbU4zY1lQbU0rZ1hDQzNwU1k4YzV4M2YwczBUWEptUzNwNlNtNHhGV3lPbGo5XC9tNWM5TG55UkY4SDBLU2FwZlFUS25FcnVyMktGVDBkbnpiYWROS01jbXlrbloyWWNOWTZKK2Fzcko5akpXUWJ3YmRhb0x3Q2c4cjRoclJ3TGxhaExvU0tJS3ozYzVCTDU4QXpocU1YSTM2bENGYjNya0lLUlg1Sm9paHRCTXZGNnRhNXlNRE1GdldIazV6NE9FTlFPd0FtKzU0NFwvbmdXemZMdUlwclZ6Wm1yTHFvaDVmMWNZMFdPMTNsYUR3Qk81UTZNaEhWRzJ0ZVlpY1pFTU9IbHdPSkVtUEIrVEs4SVFsalZlN2lwOTZNZk4rM21cL0J4aGpcLzNCT01ocnpEcHFweGVla3ZSY3lDNUY3QXp6VDNBd3RZTFZXRTRPRnBReWdrWVpzZzh2TW51dWhGXC9KYmlaTUxiR05JSmZraUg5cGpCVjVleUFwZ3BTVUpUMnZyWnJGVkdFMUtpTzZPMFV6dkJBdXJnMFFHcWRJKzRZY3dUSU1cL1wvOENPVkhmbEY2UmFKYzcybVgrdXhpZDlvSnpJWFwvTzBlVUsyNDA1a3JETUh1YnA1cGJlRWRuUUdoMU1cL3paVUtFV2hmR0dwTW5QbE1YdlAxSnh2dVQ3dEM2TW1ZV3U1aXNDXC92NHo4WWllYU5mMExEV2sxSzhJRGp6ZGhlS2tLejkxRGo3c3VZMTFJTHJpbkVJV2FzRjVnUGRsNU1RN1AwUHlTTjRrSnlmOHdXNklxSFBSYjBsYWtLUDJla1FncWtXV1N6cVRjeXZYUVwvWTZENDhRMHprNEhDY1RCWVRDTXUyZDdITEF5c1lWVW9qRnJiXC9JYWVZZWg2NXpGb2ZFZmphWm1tbmVPcHB0SWw0OVwvXC9cL1huSFwvQ0ZXckFsYVhvZkIrWFMyUnhrWXZ2S3MycjNDK0JyaVdvRExUZVFzNGEwWkRaQ0ZjQ05obHB6MXFSMkFWOXdTNEFnbVRlQWZiZnJadFVOVFE1cXVkR0daQTVvb2V6bVVWUVppTHdcL1doRmxnS29GTkVZWWl5cWxLNmhsMTRaQmtvWEd3RWJ4YnVIaURPbzMyRyt3MzJDXC93WDZEUFd2d3c3am5XSVwvZGZqS3RlbzZlMVdjcDBzM3hDVnBrd2xUQ21BOGZYU3ZVQXYxK0ZGaDduMWxab1JwNjBrOVlORFdxRTZcL2RmT0E5d21Gajk1YldxTnhMRExnY3lmQ2FuNFRuUjk2UnBneVM5alIwenJzMmZmKzlhVXhqVVJVVEFZRFI2ZG9ycmExTkZBVEdzdTVJS0pnTFNWZ0xzMGk1Q2xMQnZsQSsxclZ2cWFvbFdqSUJHa1BXOUxyZVo4V0tcL2J5UmNvR3JUNWplaHQ4c3pMYndUdHlodEd2dmV5NTRxZ2dtMXprSmFqQmx3MUVmbDNFd2pCNXgwUFwvNzZwOEFBQURcL1wvK3h6RHFqT0VnQUEifX19"
            Logger.instance.info(message: "Loading URL: \(url)")
            if let link = URL(string: url) {
                self._timeoutTimer = Timer.scheduledTimer(
                    timeInterval: 5.0,
                    target: self,
                    selector: #selector(forcedTimeout),
                    userInfo: nil,
                    repeats: false
                )
                let request = URLRequest(url: link)
                webView.load(request)
            }
        }
    }

    public func cleanEngineWeb() {
        webView.removeFromSuperview()
        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "gist")
    }

    @objc
    func forcedTimeout() {
        Logger.instance.info(message: "Timeout triggered, triggering message error.")
        delegate?.error()
    }
}

// swiftlint:disable cyclomatic_complexity
extension EngineWeb: WKScriptMessageHandler {
    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let dict = message.body as? [String: AnyObject],
              let eventProperties = dict["gist"] as? [String: AnyObject],
              let method = eventProperties["method"] as? String,
              let engineEventMethod = EngineEvent(rawValue: method)
        else {
            return
        }

        switch engineEventMethod {
        case .bootstrapped:
            _timeoutTimer?.invalidate()
            delegate?.bootstrapped()
        case .routeLoaded:
            _elapsedTimer.end()
            if let route = EngineEventHandler.getRouteLoadedProperties(properties: eventProperties) {
                delegate?.routeLoaded(route: route)
            }
        case .routeChanged:
            if let route = EngineEventHandler.getRouteChangedProperties(properties: eventProperties) {
                _elapsedTimer.start(title: "Engine render for message: \(route)")
                delegate?.routeChanged(newRoute: route)
            }
        case .routeError:
            if let route = EngineEventHandler.getRouteErrorProperties(properties: eventProperties) {
                delegate?.routeError(route: route)
            }
        case .sizeChanged:
            if let size = EngineEventHandler.getSizeProperties(properties: eventProperties) {
                delegate?.sizeChanged(width: size.width, height: size.height)
            }
        case .tap:
            if let tapProperties = EngineEventHandler.getTapProperties(properties: eventProperties) {
                delegate?.tap(name: tapProperties.name, action: tapProperties.action, system: tapProperties.system)
            }
        case .error:
            delegate?.error()
        }
    }
}

// swiftlint:enable cyclomatic_complexity

extension EngineWeb: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {}

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        delegate?.error()
    }

    public func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        delegate?.error()
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        delegate?.error()
    }
}
