//
//  ImportViewController.swift
//  ManicEmu
//
//  Created by Aoshuang Lee on 2024/12/29.
//  Copyright © 2024 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import UIKit
import SideMenu
import KeyboardKit

class ImportViewController: BaseViewController {
    private var cornerMaskViewForiPad: TransparentHoleView = {
        let view = TransparentHoleView()
        return view
    }()
    
    private lazy var importServiceListView: ImportServiceListView = {
        let view = ImportServiceListView()
        view.addServiceButton.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.showSideMenu()
        }
        return view
    }()
    
    private lazy var addImportServiceView: AddImportServiceView = {
        let view = AddImportServiceView()
        view.requireToHideSideMenu = { [weak self] in
            guard let self = self else { return }
            self.hideSideMenu()
        }
        return view
    }()
    
    private weak var sideMenu: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.isPhone {
            coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.hideSideMenu()
                self?.importServiceListView.updateViews()
            }
        }
    }
    
    private func setupViews() {
        if UIDevice.isPhone {
            view.addSubview(importServiceListView)
            importServiceListView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            view.backgroundColor = UIColor(.dm, light: .white, dark: .black)
            importServiceListView.backgroundColor = Constants.Color.Background
            importServiceListView.addServiceButton.isHidden = true
            view.addSubview(importServiceListView)
            importServiceListView.snp.makeConstraints { make in
                make.top.bottom.trailing.equalToSuperview()
                make.width.equalToSuperview().offset(-Constants.Size.SideMenuWidth*1.15)
            }
            
            view.addSubview(addImportServiceView)
            addImportServiceView.snp.makeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
                make.trailing.equalTo(importServiceListView.snp.leading)
            }
            
            view.addSubview(cornerMaskViewForiPad)
            cornerMaskViewForiPad.snp.makeConstraints { make in
                make.edges.equalTo(importServiceListView)
            }
        }
    }
    
    override func handleScreenPanGesture(edges: UIRectEdge) {
        if UIDevice.isPhone || (UIDevice.isPad && !UIDevice.isLandscape) {
            if edges == .left {
                showSideMenu()
            }
        }
    }
    
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        Log.debug("importServiceListView becomeFirstResponder")
        return importServiceListView.collectionView.becomeFirstResponder()
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        Log.debug("importServiceListView resignFirstResponder")
        return importServiceListView.collectionView.resignFirstResponder()
    }
    
    private func showSideMenu() {
        UIDevice.generateHaptic()
        let vc = AddImportServiceViewController(addImportServiceView: addImportServiceView)
        let menu = ControllableSideMenu(rootViewController: vc)
        menu.navigationBar.isHidden = true
        menu.presentDuration = Constants.Numbers.LongAnimationDuration
        menu.dismissDuration = Constants.Numbers.LongAnimationDuration
        menu.leftSide = !Locale.isRTLLanguage
        menu.menuWidth = Constants.Size.SideMenuWidth
        menu.presentationStyle = SideMenuShowStyle()
        topViewController()?.present(menu, animated: true)
        sideMenu = menu
    }
    
    private func hideSideMenu() {
        sideMenu?.dismiss(animated: true)
    }
}

extension ImportViewController: UIControllerPressable {
    override var keyCommands: [UIKeyCommand]? {
        var commands = super.keyCommands ?? []
        commands.append(UIKeyCommand(input: "[", modifierFlags: [], action: #selector(didImportViewKeyboardPress)))
        return commands
    }
    
    func didControllerPress(key: UIControllerKey) {
        if !UIDevice.isPad {
            if key == .l2 {
                showSideMenu()
            }
        }
    }
    
    @objc func didImportViewKeyboardPress(_ sender: UIKeyCommand) {
        if let inputString = sender.input, !(UIDevice.isPad && UIDevice.isLandscape) {
            if inputString == "[" {
                showSideMenu()
            }
        }
    }
}
