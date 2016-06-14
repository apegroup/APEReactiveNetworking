// This file is a example created for the template project

import UIKit
import ReactiveCocoa
import APEReactiveNetworking

typealias LoginCompletionHandler = (AuthResponse)->()

class LoginViewController: UIViewController {
    
    //MARK: Properties
    
    private let authHandler = ApeJwtAuthenticationHandler()
    
    private let apeChatApi: ApeChatApi = ApeChatApiFactory.create()
    
    var loginCompletionHandler: LoginCompletionHandler?
    
    //MARK: Outlets
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var dismissButton: UIBarButtonItem!
    
    //MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindUIWithSignals()
    }
    
    //MARK: Private
    
    private func bindUIWithSignals() {
        
        dismissButton.rac_command = RACCommand { _ ->  RACSignal! in
            return RACSignal.createSignal { (subscriber: RACSubscriber!) -> RACDisposable! in
                self.dismissViewControllerAnimated(true, completion: nil)
                return RACDisposable()
                }
                .deliverOnMainThread()
        }
        
        loginButton
            .rac_signalForControlEvents(.TouchUpInside)
            .throttle(0.2)
            .subscribeNext { sender in
                
                self.apeChatApi
                    .authenticateUser(self.usernameTextField.text ?? "", password: self.passwordTextField.text ?? "")
                    .start { [weak self] event in
                        switch event {
                        case .Next(let authResponse):
                            //This is a POC - mark the global "authenticated" state that we are authenticated
                            Authenticated.authed = true
                            
                            self?.handleLoginSuccess(authResponse)
                        case .Failed(let error):
                            self?.handleLoginError(error)
                        default: break
                        }
                }
        }
    }
    
    private func handleLoginSuccess(authResponse: AuthResponse) {
        authHandler.handleAuthTokenReceived(authResponse.accessToken)
        loginCompletionHandler?(authResponse)
        dispatch_async(dispatch_get_main_queue()) {
            self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    private func handleLoginError(error: NetworkError) {
        print("received error: \(error)")
    }
}