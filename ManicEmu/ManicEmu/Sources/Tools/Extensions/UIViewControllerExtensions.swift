//
//  UIViewControllerExtensions.swift
//  ManicEmu
//
//  Created by Aoshuang Lee on 2024/12/25.
//  Copyright © 2024 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import Foundation
import VisualEffectView
import ProHUD

func topViewController(appController: Bool = false) -> UIViewController? {
    if appController {
        //如果设置为true则只找自己应用的window 弹窗那些window就不去找了
        if let vc = topViewController(rootViewController: ApplicationSceneDelegate.applicationWindow?.rootViewController) {
            return vc
        }
    } else if let window = ApplicationSceneDelegate.applicationScene?.windows.last(where: { $0.isHidden == false && $0.rootViewController != nil && (String(describing: type(of: $0)) == "SheetWindow" || String(describing: type(of: $0)) == "AlertWindow" || $0.windowLevel == .normal) }),
              let vc = topViewController(rootViewController: window.rootViewController) {
        return vc
    }
    return nil
}

private func topViewController(rootViewController: UIViewController?) -> UIViewController? {
    if rootViewController is UITabBarController, let vc = (rootViewController as! UITabBarController).selectedViewController {
        return topViewController(rootViewController: vc)
    } else if rootViewController is UINavigationController, let vc = (rootViewController as! UINavigationController).visibleViewController {
        return topViewController(rootViewController: vc)
    } else if let vc = rootViewController?.presentedViewController {
        return topViewController(rootViewController: vc)
    } else {
        return rootViewController
    }
}

extension BaseViewController {
    
    func addCloseButton(onTap: (() -> Void)? = nil, makeConstraints: ((ConstraintMaker) -> Void)? = nil) {
        
        view.addSubview(closeButton)
        
        closeButton.snp.makeConstraints { (maker) in
            if makeConstraints != nil {
                makeConstraints?(maker)
            } else {
                maker.size.equalTo(Constants.Size.IconSizeMid)
                maker.top.equalTo(view).offset(Constants.Size.ContentSpaceMin)
                maker.trailing.equalTo(view).offset(-Constants.Size.ContentSpaceMax)
            }
        }
        closeButton.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            if onTap != nil {
                onTap?()
            } else {
                dismiss(animated: true, completion: nil)
            }
        }
    }
}
