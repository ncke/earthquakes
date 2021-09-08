//
//  QuakeNavController.swift
//  Earthquake
//
//  Created by Nick on 07/09/2021.
//

import UIKit

// MARK: - Quake Nav Controller

class QuakeNavController: UINavigationController {

    // I'm keeping the coordinator here because the nav controller is
    // alive for the duration of the application session.
    private let coordinator = QuakeCoordinator()

    override func viewDidLoad() {
        super.viewDidLoad()

        // The nav controller is instantiated from the storyboard as the
        // initial view controller, and creates its root view controller
        // as well. In other scenarios these elements could be created
        // programmatically, that would relax the dependency on the
        // lifecycle of the UIKit stuff. But for now, we use the
        // start up of the nav controller to get the coordinator going.

        coordinator.setNavController(self)

        // At this stage we expect a single root view controller of the
        // expected type, because that's the way UIKit does it. But there's
        // a little flexibility on that in this implementation anyway.

        if let vc: QuakeTableViewController = self.viewControllers.firstAmong()
        {
            coordinator.setQuakeTableViewController(vc)
        }

    }

}
