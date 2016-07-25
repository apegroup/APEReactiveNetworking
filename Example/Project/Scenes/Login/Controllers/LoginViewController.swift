// This file is a example created for the template project

import UIKit
import ReactiveCocoa
import enum Result.NoError
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
        setupUI()
        bindUIWithSignals()
    }
    
    //MARK: Private
    
    private func setupUI() {
        usernameTextField.layer.borderWidth = 1
        passwordTextField.layer.borderWidth = 1
    }
    
    private func bindUIWithSignals() {
        
        //Validate textfields input values
        let usernameSignal = usernameTextField.rac_textSignal()
            .toSignalProducer()
            .map { text in DataValidator().isValidUsername(text as! String) }
        
        let passwordSignal = passwordTextField.rac_textSignal()
            .toSignalProducer()
            .map { text in DataValidator().isValidPassword(text as! String) }
        
        //Mark textfields as green when input is valid
        usernameSignal.startWithNext { [unowned self] valid in
            let color = valid ? UIColor.greenColor() : UIColor.clearColor()
            self.usernameTextField.layer.borderColor = color.CGColor
        }

        passwordSignal.startWithNext { [unowned self] valid in
            let color = valid ? UIColor.greenColor() : UIColor.clearColor()
            self.passwordTextField.layer.borderColor = color.CGColor
        }

        //Enable/disable login button according to input
        usernameSignal
            .combineLatestWith(passwordSignal)
            .map { (valid: (username:Bool, password:Bool)) in
                valid.username && valid.password
            }
            .startWithNext { [unowned self] valid in
                self.loginButton.enabled = valid
        }
        
        dismissButton.rac_command = RACCommand { [unowned self] _ ->  RACSignal! in
            return RACSignal.createSignal { (subscriber: RACSubscriber!) -> RACDisposable! in
                self.dismissViewControllerAnimated(true, completion: nil)
                return RACDisposable()
                }
                .deliverOnMainThread()
        }
        
        loginButton
            .rac_signalForControlEvents(.TouchUpInside)
            .throttle(0.2)
            .subscribeNext { [unowned self] _sender in
                self.apeChatApi
                    .authenticateUser(self.usernameTextField.text ?? "", password: self.passwordTextField.text ?? "")
                    .start { event in
                        switch event {
                        case .Next(let NetworkDataResponse):
                            //This is a POC - mark the global "authenticated" state that we are authenticated
                            DummyState.authed = true
                            self.handleLoginSuccess(NetworkDataResponse.parsedData)
                        case .Failed(let error):
                            self.handleLoginError(error)
                        default: break
                        }
                }
        }
    }
    
    private func handleLoginSuccess(authResponse: AuthResponse) {
        authHandler.handleAuthTokenReceived(authResponse.accessToken)
        loginCompletionHandler?(authResponse)
    }
    
    private func handleLoginError(error: Network.Error) {
        print("received error: \(error)")
    }
}