//
//  TriggerProListViewController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/10/21.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

class TriggerProListViewController: BaseViewController {
    
    private lazy var triggerProListView: TriggerProListView = {
        let view = TriggerProListView(showClose: showClose)
        view.didTapClose = {[weak self] in
            self?.dismiss(animated: true)
        }
        return view
    }()
    
    private var showClose: Bool
    
    init(showClose: Bool = true) {
        self.showClose = showClose
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(triggerProListView)
        triggerProListView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
