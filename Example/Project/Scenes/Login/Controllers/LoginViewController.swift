// This file is a example created for the template project

import UIKit
import ReactiveSwift
import enum Result.NoError
import APEReactiveNetworking
import ReactiveObjC
import ReactiveObjCBridge

typealias LoginCompletionHandler = (AuthResponse)->()

class LoginViewController: UIViewController {
    
    //MARK: Properties
    
    var loginCompletionHandler: LoginCompletionHandler?
    
    private let apeChatApi: ApeChatApi = ApeChatApiFactory.make()
    
    
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
        
        //FIXME:
        //Validate textfields input values
        let usernameSignal = usernameTextField.rac_textSignal()
            .toSignalProducer()
            .map { text in DataValidator().isValidUsername(text as! String) }
        
        let passwordSignal = passwordTextField.rac_textSignal()
            .toSignalProducer()
            .map { text in DataValidator().isValidPassword(text as! String) }
        
        //Mark textfields as green when input is valid
        usernameSignal.on(value: { [unowned self] isValid in
            let color = isValid ? UIColor.green : UIColor.clear
            self.usernameTextField.layer.borderColor = color.cgColor
            }).start()
        
        passwordSignal.on(value: { [unowned self] isValid in
            let color = isValid ? UIColor.green : UIColor.clear
            self.passwordTextField.layer.borderColor = color.cgColor
            }).start()
        
        //Enable/disable login button according to input
        usernameSignal.combineLatest(with: passwordSignal)
            .map { (isValid: (username:Bool, password:Bool)) in isValid.username && isValid.password }
            .on(value: { [unowned self] valid in
                self.loginButton.isEnabled = valid
                }).start()
        
        dismissButton.rac_command = RACCommand { [unowned self] _ ->  RACSignal in
            return RACSignal.createSignal { (subscriber: RACSubscriber!) -> RACDisposable! in
                self.dismiss(animated: true, completion: nil)
                return RACDisposable()
                }
                .deliverOnMainThread()
        }
        
        loginButton
            .rac_signal(for: .touchUpInside)
            .throttle(0.2)
            .subscribeNext { [unowned self] _sender in
                self.apeChatApi
                    .authenticateUser(self.usernameTextField.text ?? "", password: self.passwordTextField.text ?? "")
                    .start { event in
                        switch event {
                        case .value(let NetworkDataResponse):
                            //This is a POC - mark the global "authenticated" state that we are authenticated
                            DummyState.authed = true
                            self.handleLoginSuccess(NetworkDataResponse.parsedData)
                        case .failed(let error):
                            self.handleLoginError(error)
                        default: break
                        }
                }
        }
    }
    
    private func handleLoginSuccess(_ authResponse: AuthResponse) {
        loginCompletionHandler?(authResponse)
    }
    
    private func handleLoginError(_ error: Network.OperationError) {
        print("received error: \(error)")
    }
}
