//
//  ImageFetcher.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later
import HXPhotoPicker
import UniformTypeIdentifiers

struct ImageFetcher {
    private static func defaultEditorConfiguration() -> EditorConfiguration {
        var editConfig = EditorConfiguration()
        editConfig.buttonType = .top
//        editConfig.photo.defaultSelectedToolOption = .cropSize
//        editConfig.cropSize.isFixedRatio = true
//        editConfig.cropSize.aspectRatio = CGSize(width: 1, height: 1)
//        editConfig.cropSize.aspectRatios.removeAll()
        editConfig.toolsView.toolOptions.removeFirst { $0.type == .chartlet }
        editConfig.finishButtonTitleNormalColor = Constants.Color.Main
        editConfig.text.tintColor = Constants.Color.Main
        editConfig.text.doneTitleColor = Constants.Color.Main
        return editConfig
    }
    
    static func capture(preferenceSize: CGSize = .init(Constants.Size.GameCoverMaxSize), completion: @escaping (_ image: UIImage?)->Void) {
        //拍摄
        PermissionKit.requestCamera {
            var config = CameraConfiguration()
            config.editor = defaultEditorConfiguration()
            let vc = Photo.capture(config, type: .photo, sender: topViewController()) { result, _, _ in
                if case .image(let image) = result {
                    completion(image.scaled(toSize: preferenceSize))
                } else {
                    completion(nil)
                }
                
            }
            vc.sheetPresentationController?.preferredCornerRadius = Constants.Size.CornerRadiusMax
        }
    }
    
    static func pick(preferenceSize: CGSize = .init(Constants.Size.GameCoverMaxSize), completion: @escaping (_ image: UIImage?)->Void) {
        PermissionKit.requestPhoto {
            var config = PickerConfiguration.default
            config.navigationBackgroundColor = Constants.Color.BackgroundPrimary.forceStyle(.dark)
            config.maximumSelectedCount = 1
            config.selectMode = .single
            config.selectOptions = [.livePhoto, .photo]
            config.photoSelectionTapAction = .openEditor
            config.editor = defaultEditorConfiguration()
            let vc = Photo.picker(config, sender: topViewController()) { result, _ in
                result.getImage(compressionScale: 1) { image in
                    if let image = image.first {
                        completion(image.scaled(toSize: preferenceSize))
                    } else {
                        completion(nil)
                    }
                    
                }
            }
            vc.sheetPresentationController?.preferredCornerRadius = Constants.Size.CornerRadiusMax
        }
    }
    
    static func file(preferenceSize: CGSize = .init(Constants.Size.GameCoverMaxSize), completion: @escaping (_ image: UIImage?)->Void) {
        ImageFileFetcher.shared.file(preferenceSize: preferenceSize, completion: { image in
            if let image {
                edit(image: image, preferenceSize: preferenceSize, completion: completion)
            } else {
                completion(nil)
            }
        })
    }
    
    static func edit(image: UIImage, preferenceSize: CGSize = .init(Constants.Size.GameCoverMaxSize), completion: @escaping (_ image: UIImage?)->Void) {
        let vc = Photo.edit(asset: .init(type: .image(image)), config: defaultEditorConfiguration(), finished: { asset, _ in
            if let newImage = asset.result?.image {
                completion(newImage.scaled(toSize: preferenceSize))
            } else {
                completion(image.scaled(toSize: preferenceSize))
            }
        })
        vc.sheetPresentationController?.preferredCornerRadius = Constants.Size.CornerRadiusMax
    }
}

fileprivate class ImageFileFetcher: NSObject {
    static let shared = ImageFileFetcher()
    private var preferenceSize: CGSize = .init(Constants.Size.GameCoverMaxSize)
    private var completion: ((_ image: UIImage?)->Void)? = nil
    
    func file(preferenceSize: CGSize = .init(Constants.Size.GameCoverMaxSize), completion: @escaping (_ image: UIImage?)->Void) {
        self.preferenceSize = preferenceSize
        self.completion = completion
        let documentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image], asCopy: true)
        documentPickerViewController.delegate = self
        documentPickerViewController.overrideUserInterfaceStyle = .dark
        documentPickerViewController.allowsMultipleSelection = false
        topViewController()?.present(documentPickerViewController, animated: true)
    }
}

extension ImageFileFetcher: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first, let image = try? UIImage(url: url) {
            completion?(image.scaled(toSize: preferenceSize))
        } else {
            completion?(nil)
        }
        completion = nil
    }
}
