//
//  BaseViewController.swift
//  ManicEmu
//
//  Created by Aoshuang Lee on 2024/12/25.
//  Copyright © 2024 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit

class BaseViewController: UIViewController {
    
    lazy var closeButton: SymbolButton = {
        let view = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold)), enableGlass: true)
        view.enableRoundCorner = true
        return view
    }()

    fileprivate var orientationNotification: Any? = nil
    
    private var fullScreen: Bool = false
    
    /// present的时候 是否需要隐藏背景的阴影视图
    var hideDimmingViewWhenPresent = PlayViewController.isGaming ? true : false
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configStyle()
    }
    
    init(fullScreen: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.fullScreen = fullScreen
        configStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configStyle()
    }
    
    func configStyle() {
        if UIDevice.isPad {
            self.modalPresentationStyle = .formSheet
        }
        if fullScreen {
            self.modalPresentationStyle = .overFullScreen
        } else if let sheetPresentationController = self.sheetPresentationController {
            sheetPresentationController.preferredCornerRadius = Constants.Size.CornerRadiusMax
        }
    }
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    override func viewDidLoad() {
        Log.debug("\(String(describing: Self.self)) viewDidLoad")
        super.viewDidLoad()
        let backgroundColor = Constants.Color.Background
        view.backgroundColor = backgroundColor
        setPreferredContentSize()
        if let navigationBar = self.navigationController?.navigationBar {
            navigationBar.isTranslucent = false
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
            appearance.shadowColor = .clear
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let presentingViewController = self.presentingViewController, hideDimmingViewWhenPresent {
            presentingViewController.view.superview?.subviews.forEach({ view in
                if String(describing: type(of: view)) == "UIDimmingView" {
                    view.isHidden = true
                }
            })
        }
    }
    
    override var presentingViewController: UIViewController? {
        if let vc = super.presentingViewController {
            return vc
        } else if let vc = self.navigationController?.presentingViewController {
            return vc
        }
        return nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setPreferredContentSize(windowSize: CGSize(width: Constants.Size.WindowSize.height, height: Constants.Size.WindowSize.width))//这个常量的反应会比较慢 所以获取反向值
    }
    
    fileprivate func setPreferredContentSize(windowSize: CGSize = Constants.Size.WindowSize) {
        if UIDevice.isPad {
            if let _ = self.presentingViewController { //如果自己是被present出来的话 就执行
                let finalSize: CGSize
                if UIDevice.isLandscape {
                    let h = windowSize.height*0.9
                    finalSize = CGSize(width: h*9/16, height: h)
                } else {
                    let w = windowSize.width*0.6
                    finalSize = CGSize(width: w, height: w*16/9)
                }
                if self.preferredContentSize != finalSize {
                    self.preferredContentSize = finalSize
                }
            }
        }
    }
    
    func handleScreenPanGesture(edges: UIRectEdge) {}
    
}
