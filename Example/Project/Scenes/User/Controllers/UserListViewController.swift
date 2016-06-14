// This file is a example created for the template project

import UIKit
import ReactiveCocoa
import APEReactiveNetworking

class UserListViewController: UIViewController {
    
    //MARK: Properties
    
    private let apeChatApi: ApeChatApi = ApeChatApiFactory.create()
    
    @IBOutlet weak var getUsersButton: UIBarButtonItem!
    
    
    //MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindUIWithSignals()
    }
    
    //MARK: Private
    
    private func bindUIWithSignals() {
        
        ///Assosicate the UIBarButtonItem with a RACCommand that starts a signal when the button is tapped
        //The UIBarButtonItem is disabled while the RACCommand is executing
        getUsersButton.rac_command = RACCommand { [weak self] _ ->  RACSignal! in
            guard let strongSelf = self else { return RACSignal.empty() }
            
            //The outer RACSignal starts an inner 'get-all-users' signal and completes when the inner signal terminates.
            //When the outer RACCommand signal completes the UIBarButtonItem becomes enabled again
            return RACSignal.createSignal { (subscriber: RACSubscriber!) -> RACDisposable! in
                
                strongSelf.getAllUsersSignalProducer()
                    //FIXME: Move 'injectAuthorizationSideEffect' to the 'NetworkedApeChatApiProvider'?
                    .injectAuthorizationSideEffect(strongSelf)
                    .on(terminated: { subscriber.sendCompleted() })
                    .start()
                
                return RACDisposable()
            }
        }
    }
    
    
    private func getAllUsersSignalProducer() -> SignalProducer<[User], NetworkError> {
        return self.apeChatApi.getAllUsers().on (
            failed: { error in
                print("failed fetching users: \(error)")
            }, next: { users in
                print("received users: \(users)")
        })
    }
}