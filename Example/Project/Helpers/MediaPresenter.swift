//
//  CameraPresenter.swift
//  activitywall
//
//  Created by Magnus Eriksson on 25/07/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import MobileCoreServices
import Photos


struct MediaPresenter {
    
    //MARK: Properties
    
    private let desiredMediaType = kUTTypeImage as NSString as String
    private let pickerControllerDelegate: ImagePickerControllerDelegate
    
    //MARK: Public
    
    init(imageCompletionBlock: @escaping ((UIImage) -> ())) {
        pickerControllerDelegate = ImagePickerControllerDelegate(imageCompletionBlock: imageCompletionBlock)
    }
    
    func canShowCamera() -> Bool {
        let camera = UIImagePickerControllerSourceType.camera
        guard UIImagePickerController.isSourceTypeAvailable(camera) else {
            print("unable to show camera")
            return false
        }
        
        guard let availableMediaTypes = UIImagePickerController.availableMediaTypes(for: camera),
            availableMediaTypes.index(of: desiredMediaType) != nil else {
                print("Media type not available")
                return false
        }
        
        return true
    }
    
    func configuredImagePickerController(sourceType: UIImagePickerControllerSourceType = .photoLibrary) -> UIViewController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.mediaTypes = [desiredMediaType]
        picker.delegate = pickerControllerDelegate
        
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraFlashMode = .auto
        }
        return picker
    }
}


class ImagePickerControllerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let imageCompletionBlock: (UIImage) -> ()
    
    init(imageCompletionBlock: @escaping ((UIImage) -> ())) {
        self.imageCompletionBlock = imageCompletionBlock
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true) {
            guard let image = info[UIImagePickerControllerEditedImage] as? UIImage,
                let type = info[UIImagePickerControllerMediaType] as? String, type == kUTTypeImage as NSString as String else {
                    return
            }
            
            self.imageCompletionBlock(image)
        }
    }
}
