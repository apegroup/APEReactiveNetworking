// This file is a example created for the template project

import UIKit
import ReactiveCocoa

class LoginViewController: UIViewController {

    //MARK: Properties

    private let apeChatApi: ApeChatApi = ApeChatApiFactory.create()

    //MARK: Outlets

    @IBOutlet weak var loginButton: UIButton!


    //MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        bindUIWithSignals()
    }

    //MARK: Private

    private func bindUIWithSignals() {

        loginButton
            .rac_signalForControlEvents(.TouchUpInside)
            .throttle(0.2)
            .subscribeNext { sender in

                self.apeChatApi.authenticateUser("ape", password: "ape")
                    .start { [weak self] event in

                        switch event {
                        case .Next(let authResponse):
                            self?.getUser(authResponse)

                        case .Failed(let error):
                            print("received error: \(error)")

                        default: break
                        }
                }
        }
    }


    private func getUser(authResponse: AuthResponse) {

        let producer = self.apeChatApi.getUser(authResponse.user.userId)

        producer.start { event in

            switch event {
            case .Next(let user):
                print("received user: \(user)")

            case .Failed(let error):
                print("received error: \(error)")

            default: break
            }
        }

    }
}
