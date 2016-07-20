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
        getUsersButton.rac_command = RACCommand { [unowned self] _ ->  RACSignal! in
            
            //The outer RACSignal starts an inner 'get-all-users' signal and completes when the inner signal terminates.
            //When the outer RACCommand signal completes the UIBarButtonItem becomes enabled again
            return RACSignal.createSignal { (subscriber: RACSubscriber!) -> RACDisposable! in
                self.getAllUsers()
                    .on(terminated: { subscriber.sendCompleted() })
                    .startWithAuthentication()
                
                return RACDisposable()
            }
        }
    }
    
    private func getAllUsers() -> SignalProducer<[User], NetworkError> {
        return apeChatApi.getAllUsers().on(
            started : {
                print("users started")
            },
            failed: { error in
                print("users failed fetching: \(error)")
                
            },
            completed: {
                print("users completed")
            },
            terminated: {
                print("users terminated")
            },
            next: { users in
                print("users received: \(users)")
                self.dataSource.elements = users
                self.tableView.reloadData()
        })
    }
}