// This file is a example created for the template project

import UIKit
import ReactiveSwift
import APEReactiveNetworking
import ReactiveObjC
import ReactiveObjCBridge

class LoginViewController: UIViewController {
    
    //MARK: Properties
    
    private let userApi = UserApiFactory.make()
    
    
    //MARK: Outlets
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var dismissButton: UIBarButtonItem!
    
    
    //MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindUIWithSignals()
    }
    
    //MARK: - Private
    
    private func setupUI() {
        usernameTextField.layer.borderWidth = 1
        passwordTextField.layer.borderWidth = 1
    }
    
    private func bindUIWithSignals() {
        
        //Connect the dismiss button
        dismissButton.rac_command = RACCommand { [weak self] _ ->  RACSignal in
            return RACSignal.createSignal { (subscriber: RACSubscriber!) -> RACDisposable! in
                self?.dismiss(animated: true, completion: nil)
                return RACDisposable()
                }.deliverOnMainThread()
        }
        
        //Connect the register button
        registerButton.rac_command = RACCommand(signal: { [weak self] _ -> RACSignal in
            return RACSignal.createSignal { (subscriber: RACSubscriber!) -> RACDisposable in
                let disposable = self?.registerUserSignal()
                    .on(terminated: { subscriber.sendCompleted() })
                    .start()
                
                return RACDisposable {
                    disposable?.dispose()
                }}.deliverOnMainThread()
            })
        
        //Connect the login button
        loginButton.rac_command = RACCommand(signal: { [weak self] _ -> RACSignal in
            return RACSignal.createSignal { (subscriber: RACSubscriber!) -> RACDisposable in
                let disposable = self?.loginUserSignal()
                    .on(terminated: { subscriber.sendCompleted() })
                    .start()
                
                return RACDisposable {
                    disposable?.dispose()
                }}.deliverOnMainThread()
        })
        
        let isValidUsernameSignal = usernameTextField.rac_textSignal().toSignalProducer()
            .map { text in DataValidator().isValidUsername(text as! String) }
        
        let isValidPasswordSignal = passwordTextField.rac_textSignal().toSignalProducer()
            .map { text in DataValidator().isValidPassword(text as! String) }
        
        //Mark textfields as green when input is valid
        isValidUsernameSignal.on(value: { [weak self] isValid in
            let color = isValid ? UIColor.green : UIColor.clear
            self?.usernameTextField.layer.borderColor = color.cgColor
            }).start()
        
        isValidPasswordSignal.on(value: { [weak self] isValid in
            let color = isValid ? UIColor.green : UIColor.clear
            self?.passwordTextField.layer.borderColor = color.cgColor
            }).start()
        
        /*
         Enable the register and the login buttons iff:
          - input is valid
          - no execution is in place
         */
        let isValidInputSignal = isValidUsernameSignal.combineLatest(with: isValidPasswordSignal)
            .map { (isValid: (username:Bool, password:Bool)) in isValid.username && isValid.password }
        
        let isExecutingSignal = loginButton.rac_command.executing.combineLatest(with: registerButton.rac_command.executing)
            .or()
            .toSignalProducer()
            .map { $0 as! Bool }
        
        isValidInputSignal.combineLatest(with: isExecutingSignal).map { [weak self] (info: (isValidInput:Bool, requestInProgress:Bool)) in
            let shouldEnable = info.isValidInput && !info.requestInProgress
            self?.loginButton.isEnabled = shouldEnable
            self?.registerButton.isEnabled = shouldEnable
            }.start()
    }
    
    //MARK: - Register
    
    private func registerUserSignal() -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.OperationError> {
        return userApi.register(username: usernameTextField.text ?? "",
                                password: passwordTextField.text ?? "")
            .on(value: handleSuccess, failed:  handleError)
    }
    
    //MARK: - Login
    
    private func loginUserSignal() -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.OperationError> {
        return userApi.login(username: usernameTextField.text ?? "",
                             password: passwordTextField.text ?? "")
            .on(value: handleSuccess, failed:  handleError)
    }
    
    private func handleSuccess(_ authResponse: NetworkDataResponse<AuthResponse>) {
        guard KeychainManager.save(jwtToken: authResponse.parsedData.accessToken) else {
            return handleError()
        }
        dismiss(animated: true)
    }
    
    private func handleError(_ error: Network.OperationError? = nil) {
        print("received error: \(error?.description ?? "")")
    }
}
