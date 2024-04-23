import CioMessagingInApp
import UIKit

/*
 Very simple screen in the app where we can display inline in-app messages, like a customer would.
 */
class POCController: UIViewController {
    @IBOutlet var gistView: GistView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Customers would not actually call this function.
        // Calling it here to trigger the View to begin displaying it's content.
        gistView.startItUp()
    }
}
