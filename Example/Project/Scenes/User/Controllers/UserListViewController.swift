// This file is a example created for the template project

import UIKit
import ReactiveCocoa
import APEReactiveNetworking

class UserListViewController: UIViewController {
    
    //MARK: Properties
    
    private let apeChatApi: ApeChatApi = ApeChatApiFactory.create()
    private let dataSource = TableViewDataSource<User, UserCell>(elements: [],
                                                                 templateCell: UserCell(),
                                                                 configureCell: { userCell, user in
                                                                    userCell.textLabel!.text = "\(user.firstName) \(user.lastName)"
    })
    
    //MARK: IBOutlets
    @IBOutlet weak var getUsersButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = dataSource
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
                strongSelf.getAllUsers()
                    .on(terminated: { subscriber.sendCompleted() })
                    .startWithAuthentication()
                
                return RACDisposable()
            }
        }
    }
    
    private func getAllUsers() -> SignalProducer<[User], NetworkError> {
        return apeChatApi.getAllUsers().on(
            failed: { error in
                print("failed fetching users: \(error)")
            }, next: { users in
                print("received users: \(users)")
                self.dataSource.elements = users
                self.tableView.reloadData()
        })
    }
}