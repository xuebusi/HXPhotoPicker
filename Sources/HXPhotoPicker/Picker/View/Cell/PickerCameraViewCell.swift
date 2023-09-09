//
//  PickerCameraViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import AVFoundation

#if !targetEnvironment(macCatalyst)
class PickerCameraViewCell: UICollectionViewCell {
    
    private var captureView: CaptureVideoPreviewView!
    private var imageView: UIImageView!
    
    var config: PhotoListConfiguration.CameraCell? {
        didSet {
            configProperty()
        }
    }
    var allowPreview = true
    override init(frame: CGRect) {
        super.init(frame: frame)
        captureView = CaptureVideoPreviewView(isCell: true)
        contentView.addSubview(captureView)
        imageView = UIImageView()
        contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func configProperty() {
        if captureView.sessionCompletion {
            return
        }
        let isCache = PhotoManager.shared.cameraPreviewImage != nil
        if (captureView.previewLayer?.session != nil || isCache) && canPreview() {
            imageView.image = UIImage.image(for: config?.cameraDarkImageName)
        }else {
            imageView.image = UIImage.image(
                for: PhotoManager.isDark ?
                    config?.cameraDarkImageName :
                    config?.cameraImageName
            )
        }
        backgroundColor = PhotoManager.isDark ? config?.backgroundDarkColor : config?.backgroundColor
        imageView.size = imageView.image?.size ?? .zero
        if let allowPreview = config?.allowPreview, allowPreview {
            requestCameraAccess()
        }else {
            imageView.image = UIImage.image(
                for: PhotoManager.isDark ?
                    config?.cameraDarkImageName :
                    config?.cameraImageName
            )
            captureView.isHidden = true
        }
    }
    func canPreview() -> Bool {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) ||
            AssetManager.cameraAuthorizationStatus() == .denied {
            return false
        }
        return true
    }
    func requestCameraAccess() {
        if !canPreview() {
            captureView.isHidden = true
            return
        }
        if captureView.sessionCompletion || !allowPreview {
            return
        }
        AssetManager.requestCameraAccess { (granted) in
            if granted {
                self.startSession()
            }else {
                PhotoTools.showNotCameraAuthorizedAlert(
                    viewController: self.viewController
                )
            }
        }
    }
    func startSession() {
        captureView.startSession { [weak self] isFinished in
            if isFinished {
                self?.imageView.image = UIImage.image(
                    for: self?.config?.cameraDarkImageName
                )
            }
        }
    }
    func stopSession() {
        captureView.stopSession()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        captureView.frame = bounds
        imageView.center = CGPoint(x: width * 0.5, y: height * 0.5)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                configProperty()
            }
        }
    }
    deinit {
        captureView.removeSampleBufferDelegate()
        stopSession()
    }
}
#endif
