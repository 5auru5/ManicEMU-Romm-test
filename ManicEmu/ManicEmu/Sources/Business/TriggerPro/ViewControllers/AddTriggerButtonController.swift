//
//  AddTriggerButtonController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/10/21.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import ManicEmuCore

class AddTriggerButtonController: BaseViewController {
    
    private lazy var addTriggerButtonView: AddTriggerButtonView = {
        let view = AddTriggerButtonView(triggerItem: triggerItem, gameType: gameType, inputs: inputs)
        view.didTapClose = {[weak self] in
            self?.dismiss(animated: true)
            self?.didPageClose?()
        }
        return view
    }()
    
    private var triggerItem: TriggerItem
    private let gameType: GameType
    private let inputs: [String]
    var didPageClose: (()->Void)? = nil
    
    init(triggerItem: TriggerItem, gameType: GameType, inputs: [String]) {
        self.triggerItem = triggerItem
        self.gameType = gameType
        self.inputs = inputs
        super.init(nibName: nil, bundle: nil)
        //禁止下滑关闭控制器
        isModalInPresentation = true
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(addTriggerButtonView)
        addTriggerButtonView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
