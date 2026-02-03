//
//  ShadersListViewController.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/12/11.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

class ShadersListViewController: BaseViewController {
    
    private lazy var shadersListView: ShadersListView = {
        let view = ShadersListView(showClose: showClose, initType: initType, ignoreShaderConfig: true, usingShaderPath: usingShaderPath)
        view.didTapClose = {[weak self] in
            self?.dismiss(animated: true)
        }
        return view
    }()
    
    private var showClose: Bool
    private var initType: ShadersListView.InitType
    private var usingShaderPath: String? = nil
    
    init(showClose: Bool = true, initType: ShadersListView.InitType, isGlsl: Bool = false, usingShaderPath: String? = nil) {
        self.showClose = showClose
        self.initType = initType
        super.init(nibName: nil, bundle: nil)
        self.usingShaderPath = usingShaderPath
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(shadersListView)
        shadersListView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
