// This file is a example created for the template project

import UIKit
import ReactiveSwift
import APEReactiveNetworking
import ReactiveObjCBridge
import ReactiveObjC

final class UserListViewController: UIViewController {
    
    //MARK: - Properties
    
    private let userApi = UserApiFactory.make()
    
    private let dataSource = TableViewDataSource<User, UserCell>(elements: [],
                                                                 templateCell: UserCell(),
                                                                 configureCell: { userCell, user in
                                                                    userCell.textLabel!.text = "\(user.username)"
    })
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var getUsersButton: UIBarButtonItem!
    @IBOutlet weak var viewProfileButton: UIBarButtonItem!
    
    
    //MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = dataSource
        bindUIWithSignals()
    }
    
    //MARK: - Private
    
    private func bindUIWithSignals() {
        
        // Assosicate the UIBarButtonItem with a RACCommand that starts a signal when the button is tapped
        // The UIBarButtonItem is disabled while the RACCommand is executing
        getUsersButton.rac_command = RACCommand { [weak self] _ -> RACSignal in
            
            //The outer RACSignal starts an inner 'get-all-users' signal and completes when the inner signal terminates.
            //When the outer RACCommand signal completes the UIBarButtonItem becomes enabled again
            return RACSignal.createSignal { (subscriber: RACSubscriber!) -> RACDisposable! in
                let disposable = self?.getAllUsers()
                    .on(terminated: { subscriber.sendCompleted() })
                    .start()
                
                return RACDisposable {
                    disposable?.dispose()
                }
            }
        }
    }
    
    private func getAllUsers() -> SignalProducer<NetworkDataResponse<[User]>, Network.OperationError> {
        return userApi.getAllUsers().on(value: { [weak self] response in
            let users = response.parsedData
            self?.dataSource.elements = users
            self?.tableView.reloadData()
            }, failed: { error in
                print("users failed fetching: \(error)")
        })
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationViewController = segue.destination as? UserDetailViewController else {
            return
        }
        
        let viewState: UserDetailViewModel.ViewState
        if let sender = sender as? UITableViewCell {
            let selectedRow = tableView.indexPath(for: sender)!.row
            let username = dataSource.elements[selectedRow].username
            viewState = .otherUser(username: username)
        } else {
            viewState = .currentUser
        }
        
        destinationViewController.setupViewState(viewState)
    }
}
