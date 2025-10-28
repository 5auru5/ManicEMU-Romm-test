//
//  UIViewExtensions.swift
//  ManicEmu
//
//  Created by Aoshuang Lee on 2023/5/17.
//  Copyright © 2023 Aoshuang Lee. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import ObjectiveC
import VisualEffectView
import ProHUD
import NVActivityIndicatorView
import Schedule

extension UIView {
    @discardableResult
    func makeBlur(blurRadius: CGFloat = 12.5, blurColor: UIColor = Constants.Color.Background, blurAlpha: CGFloat = 0.9, cornerRadius: CGFloat? = nil) -> VisualEffectView {
        removeBlur()
        backgroundColor = .clear
        let blur = VisualEffectView()
        insertSubview(blur, at: 0)
        blur.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        blur.blurRadius = blurRadius
        blur.colorTint = blurColor
        blur.colorTintAlpha = blurAlpha
        if let cornerRadius = cornerRadius {
            blur.layerCornerRadius = cornerRadius
        }
        return blur
    }
    
    func removeBlur() {
        if let blurView = subviews.first(where: { $0 is VisualEffectView }) as? VisualEffectView {
            blurView.removeFromSuperview()
        }
    }
    
    func setBlurVisble(_ visble: Bool) {
        if let blurView = subviews.first(where: { $0 is VisualEffectView }) as? VisualEffectView {
            blurView.isHidden = !visble
        }
    }
    
    func makeShadow(ofColor: UIColor = Constants.Color.Shadow, radius: CGFloat = 10) {
        self.addShadow(ofColor: ofColor, radius: radius)
    }
    
    /// 为视图添加 iOS 26 的 Liquid Glass 效果
    /// - Parameters:
    ///   - useContainerEffect: 是否使用容器效果（UIGlassContainerEffect），默认为 false 使用普通玻璃效果（UIGlassEffect）
    /// - Note: 此方法仅在 iOS 26.0 及以上版本可用
    @available(iOS 26.0, *)
    func makeGlass(useContainerEffect: Bool = false) {
        // 移除已存在的 Liquid Glass 视图
        subviews.filter { $0 is UIVisualEffectView && $0.accessibilityIdentifier == "LiquidGlassEffectView" }.forEach {
            $0.removeFromSuperview()
        }
        
        // 创建 Glass Effect
        let glassEffect: UIVisualEffect
        if useContainerEffect {
            glassEffect = UIGlassContainerEffect()
        } else {
            glassEffect = UIGlassEffect()
        }
        
        // 创建 UIVisualEffectView 并应用玻璃效果
        let visualEffectView = UIVisualEffectView(effect: glassEffect)
        visualEffectView.accessibilityIdentifier = "LiquidGlassEffectView"
        visualEffectView.frame = bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 继承当前视图的圆角设置
        if layer.cornerRadius > 0 {
            visualEffectView.layer.cornerRadius = layer.cornerRadius
            visualEffectView.clipsToBounds = true
        }
        
        // 将 UIVisualEffectView 添加到当前视图的底层
        insertSubview(visualEffectView, at: 0)
    }
    
    static func normalAnimate(enable: Bool = true, animations: @escaping ()->Void, completion: ((Bool)->Void)? = nil) {
        if enable {
            UIView.animate(withDuration: 0.35, animations: animations, completion: completion)
        } else {
            animations()
            completion?(true)
        }
    }
    
    static func springAnimate(enable: Bool = true, animations: @escaping ()->Void, completion: ((Bool)->Void)? = nil) {
        if enable {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, animations: animations, completion: completion)
        } else {
            animations()
            completion?(true)
        }
    }
    
    static func makeToast(message: String, isRemovable: Bool = true, identifier: String? = nil, duration: TimeInterval = 3, hideCompletion: (()->Void)? = nil) {
        func setupToast(toast: ToastTarget, resue: Bool = false) {
            toast.onViewDidDisappear { _ in
                hideCompletion?()
            }
            let maxWidth = Constants.Size.WindowWidth - 2*Constants.Size.ContentSpaceMax
            let insets = UIEdgeInsets(horizontal: Constants.Size.ContentSpaceHuge*2, vertical: 14*2)
            toast.config.cardEdgeInsets = insets
            let font = Constants.Font.title(size: .s, weight: .semibold)
            toast.config.customTextLabel { label in
                label.textColor = Constants.Color.LabelPrimary
                label.font = font
                label.textAlignment = .natural
                label.lineBreakMode = .byWordWrapping
            }
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            let textSize = NSAttributedString(string: message, attributes: [.font: font, .paragraphStyle: paragraphStyle]).size()
            let textMaxWidth = textSize.width.ceil
            let cornerRadius = (insets.top + textSize.height + insets.bottom)/2
            toast.config.cardCornerRadius = cornerRadius > 24 ? Constants.Size.CornerRadiusMax : cornerRadius
            if insets.left + textMaxWidth + insets.right < maxWidth {
                toast.config.cardMaxWidth = insets.left + textMaxWidth + insets.right
            } else {
                toast.config.cardMaxWidth = maxWidth
            }
            toast.contentView.layerBorderColor = Constants.Color.Border
            toast.contentView.layerBorderWidth = 1
            toast.config.dynamicBackgroundColor = Constants.Color.BackgroundPrimary.withAlphaComponent(0.95)
        }
        
        if !isRemovable, let identifier = identifier {
            if let toast = ToastManager.find(identifier: identifier).first {
                toast.bodyLabel.text = message
            } else {
                //常驻的toast
                Toast(.message(message).duration(.infinity).identifier(identifier)) { toast in
                    toast.isRemovable = false
                    setupToast(toast: toast)
                }
            }
        } else if let identifier = identifier {
            //只有一个Toast 3秒消失
            Toast(.message(message).duration(duration).identifier(identifier)) { toast in
                setupToast(toast: toast)
            }
            
        } else {
            //停留3秒就消失
            Toast(.message(message).duration(duration)) { toast in
                setupToast(toast: toast)
            }
        }
    }
    
    /// 立即移除toast
    /// - Parameter identifier: toast的标识 如果不传入 则隐藏全部
    static func hideToast(identifier: String) {
        ToastManager.find(identifier: identifier).forEach { $0.pop() }
    }
    
    private static var LoadingToastRepeater: Schedule.Task? = nil
    private static var LoadingToastIdentifier = "LoadingToastIdentifier"
    static func makeLoadingToast(message: String) {
        var dot = "..."
        let task = Plan.every(1.seconds).do(queue: .main) {
            UIView.makeToast(message: message + dot,
                             isRemovable: false,
                             identifier: LoadingToastIdentifier)
            dot += "."
            if dot.count > 3 {
                dot = "."
            }
        }
        TaskCenter.default.addTag(LoadingToastIdentifier, to: task)
        LoadingToastRepeater = task
    }
    
    static func hideLoadingToast(forceHide: Bool = false) {
        func hideAction() {
            UIView.hideToast(identifier: LoadingToastIdentifier)
            LoadingToastRepeater?.cancel()
            TaskCenter.default.resume(byTag: LoadingToastIdentifier)
            LoadingToastRepeater = nil
        }
        if forceHide {
            hideAction()
        } else {
            //判断一下还有没有下载中的人物
            if !DownloadManager.shared.hasDownloadTask && !SyncManager.shared.hasDownloadTask {
                hideAction()
            }
        }
    }
    
    private static let LoadingIdentifier = "LoadingIdentifier"
    private static var startLoadingTime: Date? = nil
    static func makeLoading(timeout: Double = .infinity) {
        if let _ = AlertManager.find(identifier: LoadingIdentifier).last {
            return
        }
        Alert(.identifier(LoadingIdentifier).duration(timeout)) { alert in
            let size = 100.0
            alert.config.cardMaxWidth = size
            alert.config.cardMinWidth = size
            alert.config.cardMaxHeight = size
            alert.config.cardMinHeight = size
            alert.contentView.layerBorderColor = UIDevice.isDarkMode ? Constants.Color.Border.forceStyle(.dark) : Constants.Color.Border.forceStyle(.light)
            alert.contentView.layerBorderWidth = 1
            alert.config.cardCornerRadius = Constants.Size.CornerRadiusMid
            alert.config.contentViewMask { mask in }
            let blur = VisualEffectView()
            blur.blurRadius = 12.5
            blur.colorTint = UIDevice.isDarkMode ? Constants.Color.BackgroundPrimary.forceStyle(.dark) : Constants.Color.BackgroundPrimary.forceStyle(.light)
            blur.colorTintAlpha = 0.925
            alert.contentMaskView = blur
            alert.config.backgroundViewMask { mask in
                mask.backgroundColor = .black.withAlphaComponent(0.2)
            }
            let pacman = UIView()
            let activity = NVActivityIndicatorView(frame: .zero, type: .pacman, color: UIDevice.isDarkMode ? Constants.Color.LabelPrimary.forceStyle(.dark) : Constants.Color.LabelPrimary.forceStyle(.light), padding: nil)
            pacman.addSubview(activity)
            activity.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.centerX.equalToSuperview().offset(Constants.Size.ContentSpaceTiny)
                make.size.equalTo(CGSize(width: 50, height: 50))
            }
            alert.add(subview: pacman).snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            activity.startAnimating()
            startLoadingTime = Date()
        }
    }
    
    static func hideLoading(completion: (()->Void)? = nil) {
        if let alert = AlertManager.find(identifier: LoadingIdentifier).last {
            if let startLoadingTime = startLoadingTime {
                let duration = Date().timeIntervalSince1970ms - startLoadingTime.timeIntervalSince1970ms
                if duration > 800 {
                    alert.pop {
                        completion?()
                    }
                } else {
                    DispatchQueue.main.asyncAfter(delay: (800-duration)/800) {
                        alert.pop {
                            completion?()
                        }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(delay: 0.8) {
                    alert.pop {
                        completion?()
                    }
                }
            }
        } else {
            completion?()
        }
        startLoadingTime = nil
    }
    
    static var alertBottomInset: CGFloat? = nil
    private static var SheetIdentifiers = [String]()
    static func makeAlert(identifier: String? = nil,
                          title: String? = nil,
                          detail: String,
                          detailAlignment: NSTextAlignment = .center,
                          cancelTitle: String = R.string.localizable.cancelTitle(),
                          confirmTitle: String? = nil,
                          confirmAutoHide: Bool = true,
                          enableForceHide: Bool = true,
                          cancelAction: (()->Void)? = nil,
                          confirmAction: (()->Void)? = nil,
                          hideAction: (()->Void)? = nil) {
        func setupSheet(_ sheet: SheetTarget) {
            SheetIdentifiers.append(sheet.identifier)
            sheet.contentMaskView.alpha = 0
            sheet.config.windowEdgeInset = 0
            sheet.onTappedBackground { sheet in
                if enableForceHide {
                    SheetIdentifiers.removeAll { $0 == sheet.identifier }
                    sheet.pop(completon: hideAction)
                }
            }
            sheet.config.backgroundViewMask { mask in
                mask.backgroundColor = .black.withAlphaComponent(0.2)
            }
            
            let view = UIView()
            let grabber = UIImageView(image: R.image.grabber_icon())
            grabber.isUserInteractionEnabled = true
            grabber.contentMode = .center
            view.addPanGesture { [weak view, weak sheet] gesture in
                guard let view = view, let sheet = sheet else { return }
                let point = gesture.translation(in: gesture.view)
                view.transform = .init(translationX: 0, y: point.y <= 0 ? 0 : point.y)
                if gesture.state == .recognized {
                    let v = gesture.velocity(in: gesture.view)
                    if (view.y > view.height*2/3 && v.y > 0) || v.y > 1200 {
                        if enableForceHide {
                            // 达到移除的速度
                            SheetIdentifiers.removeAll { $0 == sheet.identifier }
                            sheet.pop(completon: hideAction)
                        }
                    }
                    UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseOut], animations: {
                        view.transform = .identity
                    })
                }
            }
            view.addSubview(grabber)
            grabber.snp.makeConstraints { make in
                make.leading.top.trailing.equalToSuperview()
                make.height.equalTo(Constants.Size.ContentSpaceTiny*3)
            }
            
            let containerView = RoundAndBorderView(roundCorner: (UIDevice.isPad || UIDevice.isLandscape) ? .allCorners : [.topLeft, .topRight])
            containerView.backgroundColor = .clear
            containerView.makeBlur()
            view.addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.top.equalTo(grabber.snp.bottom)
                make.leading.bottom.trailing.equalToSuperview()
            }
            
            let titleLabel = UILabel()
            titleLabel.textAlignment = .center
            titleLabel.text = title
            titleLabel.font = Constants.Font.title(size: .s, weight: .semibold)
            titleLabel.textColor = Constants.Color.LabelPrimary
            containerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(30)
            }
            
            let detailLabel = UILabel()
            detailLabel.numberOfLines = 0
            let style = NSMutableParagraphStyle()
            style.lineSpacing = Constants.Size.ContentSpaceUltraTiny
            style.alignment = detailAlignment
            detailLabel.attributedText = NSAttributedString(string: detail, attributes: [.font: Constants.Font.body(size: .m), .foregroundColor: Constants.Color.LabelPrimary, .paragraphStyle: style])
            containerView.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                make.top.equalTo(titleLabel.snp.bottom).offset(Constants.Size.ContentSpaceMin)
            }
            
            let line = UIView()
            line.backgroundColor = Constants.Color.Border
            containerView.addSubview(line)
            line.snp.makeConstraints { make in
                make.height.equalTo(1)
                make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
                make.top.equalTo(detailLabel.snp.bottom).offset(40)
            }
            
            let buttonContainerView = UIView()
            containerView.addSubview(buttonContainerView)
            buttonContainerView.snp.makeConstraints { make in
                make.height.equalTo(Constants.Size.ItemHeightMid)
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(line.snp.bottom)
                make.bottom.equalToSuperview().offset(-Constants.Size.ContentInsetBottom)
            }
            
            if confirmTitle == nil {
                let button1 = UILabel()
                button1.isUserInteractionEnabled = true
                button1.enableInteractive = true
                button1.text = cancelTitle
                button1.textAlignment = .center
                button1.font = Constants.Font.title(size: .s, weight: .regular)
                button1.textColor = Constants.Color.LabelSecondary
                buttonContainerView.addSubview(button1)
                button1.snp.makeConstraints { make in
                    make.leading.top.bottom.trailing.equalToSuperview()
                }
                button1.addTapGesture { [weak sheet] gesture in
                    guard let sheet = sheet else { return }
                    SheetIdentifiers.removeAll { $0 == sheet.identifier }
                    sheet.pop {
                        cancelAction?()
                        hideAction?()
                    }
                }
            } else {
                let verticalLine = UIView()
                verticalLine.backgroundColor = Constants.Color.Border
                buttonContainerView.addSubview(verticalLine)
                verticalLine.snp.makeConstraints { make in
                    make.size.equalTo(CGSize(width: 1, height: 26))
                    make.centerX.equalToSuperview()
                    make.top.equalToSuperview().offset(Constants.Size.ContentSpaceMin)
                }
                
                let button1 = UILabel()
                button1.isUserInteractionEnabled = true
                button1.enableInteractive = true
                button1.text = cancelTitle
                button1.textAlignment = .center
                button1.font = Constants.Font.title(size: .s, weight: .regular)
                button1.textColor = Constants.Color.LabelSecondary
                buttonContainerView.addSubview(button1)
                button1.snp.makeConstraints { make in
                    make.leading.top.bottom.equalToSuperview()
                    make.trailing.equalTo(verticalLine.snp.leading)
                }
                button1.addTapGesture { [weak sheet] gesture in
                    guard let sheet = sheet else { return }
                    SheetIdentifiers.removeAll { $0 == sheet.identifier }
                    sheet.pop {
                        cancelAction?()
                        hideAction?()
                    }
                }
                
                let button2 = UILabel()
                button2.isUserInteractionEnabled = true
                button2.enableInteractive = true
                button2.text = confirmTitle
                button2.textAlignment = .center
                button2.font = Constants.Font.title(size: .s, weight: .semibold)
                button2.textColor = Constants.Color.Red
                buttonContainerView.addSubview(button2)
                button2.snp.makeConstraints { make in
                    make.trailing.top.bottom.equalToSuperview()
                    make.leading.equalTo(verticalLine.snp.trailing)
                }
                button2.addTapGesture { [weak sheet] gesture in
                    guard let sheet = sheet else { return }
                    if confirmAutoHide {
                        SheetIdentifiers.removeAll { $0 == sheet.identifier }
                        sheet.pop {
                            confirmAction?()
                            hideAction?()
                        }
                    } else {
                        confirmAction?()
                    }
                }
            }
            
            sheet.set(customView: view).snp.makeConstraints { make in
                if let bottomInset = UIView.alertBottomInset, bottomInset > 0, PlayViewController.isGaming {
                    make.leading.top.trailing.equalToSuperview()
                    make.bottom.equalToSuperview().inset(bottomInset)
                } else {
                    make.edges.equalToSuperview()
                }
            }
        }
        if let identifier = identifier {
            Sheet.lazyPush(identifier: identifier) { sheet in
                setupSheet(sheet)
            }
        } else {
            Sheet { sheet in
                setupSheet(sheet)
            }
        }
        
    }
    
    ///只能隐藏由makeAlert展示的
    static func hideAlert(completion: (()->Void)? = nil) {
        var removes: [String] = []
        for identifier in SheetIdentifiers.reversed() {
            if let sheet = SheetProvider.find(identifier: identifier).first {
                sheet.pop {
                    SheetIdentifiers.removeLast()
                    completion?()
                }
                break
            } else {
                removes.append(identifier)
            }
        }
        SheetIdentifiers.removeAll { removes.contains($0) }
    }
    
    ///能隐藏所有Alert
    static func hideAllAlert(completion: (()->Void)? = nil) {
        func hideAll(hideAllcompletion: (()->Void)? = nil) {
            if let sheet = SheetProvider.findAll().first {
                sheet.pop {
                    hideAll(hideAllcompletion: hideAllcompletion)
                }
            } else {
                hideAllcompletion?()
            }
        }
        SheetIdentifiers.removeAll()
        hideAll(hideAllcompletion: completion)
    }
    
    func asImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        format.opaque = isOpaque
        
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
        return renderer.image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: false)
        }
    }
}

fileprivate var UIViewEnableInteractiveAssociationKey: UInt8 = 0
fileprivate var UIViewDelayInteractiveTouchEndAssociationKey: UInt8 = 0
fileprivate var UIViewEnableInteractiveOverlayAssociationKey: UInt8 = 0
fileprivate var UIViewOverlayViewAssociationKey: UInt8 = 0
extension UIView {
    var enableInteractive: Bool {
        get {
            if let bool = objc_getAssociatedObject(self, &UIViewEnableInteractiveAssociationKey) as? Bool {
                return bool
            }
            return false
        }
        set(newValue) {
            objc_setAssociatedObject(self, &UIViewEnableInteractiveAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var delayInteractiveTouchEnd: Bool {
        get {
            if let bool = objc_getAssociatedObject(self, &UIViewDelayInteractiveTouchEndAssociationKey) as? Bool {
                return bool
            }
            return false
        }
        set(newValue) {
            objc_setAssociatedObject(self, &UIViewDelayInteractiveTouchEndAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var enableInteractiveOverlay: Bool {
        get {
            if let bool = objc_getAssociatedObject(self, &UIViewEnableInteractiveOverlayAssociationKey) as? Bool {
                return bool
            }
            return false
        }
        set(newValue) {
            objc_setAssociatedObject(self, &UIViewEnableInteractiveOverlayAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            addOverlay()
        }
    }
    
    private var overlayView: UIView? {
        get {
            if let view = objc_getAssociatedObject(self, &UIViewOverlayViewAssociationKey) as? UIView {
                return view
            }
            return nil
        }
        set(newValue) {
            objc_setAssociatedObject(self, &UIViewOverlayViewAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    private func addOverlay() {
        guard enableInteractiveOverlay else { return }
        if let _ = self.overlayView {
            return
        } else {
            let view = UIView(frame: bounds)
            view.backgroundColor = Constants.Color.Background.reverseStyle().withAlphaComponent(0.08)
            view.isHidden = true
            view.layer.cornerRadius = layer.cornerRadius
            view.clipsToBounds = true
            insertSubview(view, at: 0)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            overlayView = view
        }
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard enableInteractive else { return }
        touchMoved(touch: touches.first)
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard enableInteractive else { return }
        touchMoved(touch: touches.first)
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard enableInteractive else { return }
        if delayInteractiveTouchEnd {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: { [weak self] in
                self?.touchEnded(touch: touches.first)
            })
        } else {
            touchEnded(touch: touches.first)
        }
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard enableInteractive else { return }
        if delayInteractiveTouchEnd {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: { [weak self] in
                self?.touchEnded(touch: touches.first)
            })
        } else {
            touchEnded(touch: touches.first)
        }
    }
    
    func touchMoved(touch: UITouch?) {
        
        guard let touch = touch else { return }
        let locationInSelf = touch.location(in: self)
        if !bounds.contains(locationInSelf) {
            performTransformation(CGAffineTransform(scaleX: 1, y: 1), hideOverlay: true)
            return
        }
        performTransformation(CGAffineTransform(scaleX: 0.9, y: 0.9), hideOverlay: false)
    }

    func touchEnded(touch: UITouch?) {
        performTransformation(CGAffineTransform(scaleX: 1, y: 1), hideOverlay: true)
    }

    private func performTransformation(_ transformation: CGAffineTransform, hideOverlay: Bool) {
        let timingParameters = UISpringTimingParameters(dampingRatio: 1.0, initialVelocity: CGVector(dx: 0.2, dy: 0.2))
        let animator = UIViewPropertyAnimator(duration: 0.0, timingParameters: timingParameters)
        animator.addAnimations { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.transform = transformation
            weakSelf.overlayView?.frame = weakSelf.bounds
            weakSelf.overlayView?.isHidden = hideOverlay
        }
        animator.isInterruptible = true
        animator.startAnimation()
    }
}
