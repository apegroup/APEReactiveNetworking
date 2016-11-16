//
//  UserDetailViewModel.swift
//  Example
//
//  Created by Magnus Eriksson on 2016-10-31.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import ReactiveSwift
import APEReactiveNetworking

struct UserDetailViewModel: ViewModel {
    
    enum ViewState {
        case currentUser
        case otherUser(username: String)
    }
    
    //MARK: - Properties
    
    private let userApi = UserApiFactory.make()
    
    let username = MutableProperty<String>("")
    let isCameraVisible = MutableProperty<Bool>(false)
    let imageData = MutableProperty<Data>(Data())
    
    var viewState = ViewState.currentUser {
        didSet {
            switch viewState {
            case .currentUser:      isCameraVisible.value = true
            default:                isCameraVisible.value = false
            }}
    }

    var isActive: Bool = false { didSet {
        if isActive {
            fetchUser()
        }}
    }
    
    //MARK: - Public
    
    func updateAvatar(image: UIImage) {
        let imageSize: CGFloat = 300
        let scaledImage = image.resized(to: imageSize)
        userApi.updateAvatar(image: scaledImage).startWithCompleted {
            self.fetchUser()
        }
    }

    
    //MARK: - Private
    
    private func fetchUser() {
        let signal: SignalProducer<NetworkDataResponse<User>, Network.OperationError>
        switch viewState {
        case .currentUser:                  signal = userApi.getCurrentUser()
        case .otherUser(let username):      signal = userApi.getUser(username)
        }
        
        signal.on(value: { response in
            let user = response.parsedData
            self.username.value = user.username
            self.imageData.value = user.avatar ?? Data()
        }, failed: { error in
            print("users failed fetching: \(error)")
        }).start()
    }
}
