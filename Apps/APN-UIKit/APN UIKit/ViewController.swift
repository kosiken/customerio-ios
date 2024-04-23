import CioMessagingInApp
import UIKit

/*
 Very simple screen in the app where we can display inline in-app messages, like a customer would.
 */
class POCController: UIViewController {
    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Customers would not actually call this function.
        // Calling it here to trigger the View to begin displaying it's content.
//        gistView.startItUp()

        tableView.dataSource = self
    }
}

extension POCController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GistCell", for: indexPath) as! GistTableViewCell
        cell.setup()
        return cell
    }
}

class GistTableViewCell: UITableViewCell {
    @IBOutlet var gistView: GistView!

    func setup() {
        gistView.startItUp()
    }
}
