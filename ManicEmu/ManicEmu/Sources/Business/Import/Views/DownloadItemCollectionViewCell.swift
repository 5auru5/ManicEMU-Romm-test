//
//  DownloadItemCollectionViewCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/4/29.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later
import Tiercel

class DownloadItemCollectionViewCell: UICollectionViewCell {
    
    class ProgressView: UIView {
        ///0-1
        var progress: Double = 0 {
            didSet {
                UIView.normalAnimate {
                    self.colorView.width = self.width * self.progress
                }
            }
        }
        
        private var colorView: UIView = {
            let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: 2)))
            view.layerCornerRadius = 1
            view.backgroundColor = Constants.Color.Main
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            layerCornerRadius = 1
            backgroundColor = Constants.Color.BackgroundSecondary
            addSubview(colorView)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private var iconView: UIImageView = {
        let view = UIImageView(image: R.image.file_browser_document())
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.body(size: .l)
        view.textColor = Constants.Color.LabelPrimary
        view.numberOfLines = 2
        return view
    }()
    
    private var subTitleLabel: UILabel = {
        let view = UILabel()
        view.font = Constants.Font.caption(size: .l)
        view.textColor = Constants.Color.LabelSecondary
        return view
    }()
    
    var pauseButton: SymbolButton = {
        let view = SymbolButton(symbol: .pause)
        view.backgroundColor = .clear
        return view
    }()
    
    var removeButton: SymbolButton = {
        let view = SymbolButton(symbol: .xmarkCircle)
        view.backgroundColor = .clear
        return view
    }()
    
    var progressView = ProgressView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(36)
        }
        
        let titleContainerView = UIView()
        addSubview(titleContainerView)
        titleContainerView.snp.makeConstraints { make in
            make.top.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
        }
        
        titleContainerView.addSubviews([titleLabel, subTitleLabel])
        titleLabel.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }
        subTitleLabel.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceUltraTiny)
        }
        
        addSubview(pauseButton)
        pauseButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(titleContainerView.snp.trailing).offset(Constants.Size.ContentSpaceMax)
            make.size.equalTo(24)
        }
        
        addSubview(removeButton)
        removeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(pauseButton.snp.trailing).offset(Constants.Size.ContentSpaceMid)
            make.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceMid)
            make.size.equalTo(24)
        }
        
        addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.leading.equalTo(titleContainerView)
            make.trailing.equalTo(removeButton)
            make.height.equalTo(2)
            make.bottom.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //TODO: 需要处理图片的尺寸
    func setData(task: DownloadTask) {
        titleLabel.text = task.fileName
        
        if task.status == .failed {
            subTitleLabel.text = R.string.localizable.downloadFailed()
            pauseButton.isHidden = true
        } else {
            subTitleLabel.text = "\(FileType.humanReadableFileSize(UInt64(task.progress.completedUnitCount)) ?? "0.0 KB")/\(FileType.humanReadableFileSize(UInt64(task.progress.totalUnitCount)) ?? "0.0 KB")"
            pauseButton.isHidden = false
            if task.status == .suspended {
                pauseButton.imageView.image = .symbolImage(.play)
            } else {
                pauseButton.imageView.image = .symbolImage(.pause)
            }
            pauseButton.addTapGesture { [weak task, weak self] gesture in
                guard let task else { return }
                if task.status == .suspended {
                    //继续下载
                    DownloadManager.shared.sessionManager.start(task)
                    self?.pauseButton.imageView.image = .symbolImage(.pause)
                    NotificationCenter.default.post(name: Constants.NotificationName.BeginDownload, object: nil)
                } else {
                    //暂停下载
                    DownloadManager.shared.sessionManager.suspend(task)
                    self?.pauseButton.imageView.image = .symbolImage(.play)
                }
            }
        }
        if progressView.width == 0 {
            DispatchQueue.main.asyncAfter(delay: 0.35) {
                self.progressView.progress = task.progress.fractionCompleted
            }
        } else {
            progressView.progress = task.progress.fractionCompleted
        }
        removeButton.addTapGesture { [weak task] gesture in
            guard let task else { return }
            UIView.makeAlert(detail: R.string.localizable.removeDownloadTask(task.fileName), confirmTitle: R.string.localizable.confirmTitle(), confirmAction: {
                DownloadManager.shared.sessionManager.remove(task)
            })
        }
        task.progress { [weak self] insideTask in
            guard let self = self else { return }
            let completedUnitCount = insideTask.progress.completedUnitCount
            let totalUnitCount = insideTask.progress.totalUnitCount
            if completedUnitCount > 0 && totalUnitCount > 0 {
                self.subTitleLabel.text = "\(FileType.humanReadableFileSize(UInt64(completedUnitCount)) ?? "0.0 KB")/\(FileType.humanReadableFileSize(UInt64(totalUnitCount)) ?? "0.0 KB")"
            }
            self.progressView.progress = insideTask.progress.fractionCompleted
        }
    }
}
