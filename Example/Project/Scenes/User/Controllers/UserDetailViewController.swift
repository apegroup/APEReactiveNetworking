//
//  UserDetailViewController.swift
//  Example
//
//  Created by Magnus Eriksson on 2016-10-31.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import UIKit
import ReactiveSwift
import APEReactiveNetworking
import enum Result.NoError
import ReactiveObjC
import ReactiveObjCBridge

final class UserDetailViewController: UIViewController {
    
    //MARK: - Properties
    
    private var viewModel = UserDetailViewModel()
    
    private lazy var mediaPresenter: MediaPresenter = {
        return MediaPresenter { [weak self] image in
            self?.viewModel.updateAvatar(image: image)
        }
    }()
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    //MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindUIWithSignals()
    }
    
    private func bindUIWithSignals() {
        viewModel.imageData.producer.on(value: { [weak self] data in
            self?.avatarImageView.image = UIImage(data: data)
            
        }).observe(on: UIScheduler()).start()
        
        usernameLabel.rac_text <~ viewModel.username
        
        viewModel.isCameraVisible.producer.on(value: { [weak self] visible in
            self?.navigationItem.rightBarButtonItem = visible ? self?.cameraButton : nil
        }).start()
        
        cameraButton.rac_command = RACCommand { [weak self] _ -> RACSignal in
            return RACSignal.createSignal { (subscriber: RACSubscriber!) -> RACDisposable! in
                if let vc = self?.mediaPresenter.configuredImagePickerController() {
                    self?.present(vc, animated: true, completion: nil)
                }
                subscriber.sendCompleted()
                return RACDisposable {}
                }.deliverOnMainThread()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.isActive = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.isActive = false
    }
    
    //MARK: - Public
    
    func setupViewState(_ state: UserDetailViewModel.ViewState) {
        viewModel.viewState = state
    }
}
