//
//  PurchaseView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/15.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class PurchaseView: BaseView {
    
    ///点击关闭按钮回调
    var didTapClose: (()->Void)? = nil
    
    private lazy var navigationView: UIView = {
        let view = UIView()
        let closeButton = SymbolButton(image: UIImage(symbol: .xmark, font: Constants.Font.body(weight: .bold), color: Constants.Color.LabelPrimary.forceStyle(.dark)), enableGlass: true)
        closeButton.backgroundColor = .white.withAlphaComponent(0.1)
        closeButton.enableRoundCorner = true
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(Constants.Size.IconSizeMid)
            make.leading.equalToSuperview().offset(Constants.Size.ContentSpaceMax)
        }
        closeButton.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            self.didTapClose?()
        }
        
        let restorePurchase = UILabel()
        restorePurchase.isUserInteractionEnabled = true
        restorePurchase.enableInteractive = true
        restorePurchase.font = Constants.Font.caption(size: .l, weight: .regular)
        restorePurchase.textColor = Constants.Color.LabelPrimary.forceStyle(.dark)
        restorePurchase.text = R.string.localizable.restorePurchaseButton()
        view.addSubview(restorePurchase)
        restorePurchase.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-Constants.Size.ContentSpaceMax)
        }
        restorePurchase.addTapGesture { [weak self] gesture in
            guard let self = self else { return }
            //恢复购买
            UIView.makeLoading()
            PurchaseManager.restore { [weak self] isSuccess in
                guard let self = self else { return }
                UIView.hideLoading()
                if isSuccess {
                    UIView.makeToast(message: R.string.localizable.restoreSuccessDesc()) { [weak self] in
                        self?.didTapClose?()
                    }
                } else {
                    UIView.makeToast(message: R.string.localizable.restoreEndDesc())
                }
                
            }
        }
        
        return view
    }()
    
    private let imageLayer: CALayer = CALayer()
    private lazy var backgroundGradientView: AnimatedGradientView = {
        let view = AnimatedGradientView(notifiedUpadate: true, alphaComponent: 0.9)
        view.layer.insertSublayer(imageLayer, at: 0)
        return view
    }()
    
    var needToClosePurchaseView: (()->Void)? = nil
    
    private var featureView = FeaturesView()
    
    private lazy var priceView: PriceView = {
        let view = PriceView()
        view.needToClosePurchaseView = { [weak self] in
            self?.didTapClose?()
        }
        return view
    }()
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    init(featuresType: FeaturesType?) {
        super.init(frame: .zero)
        Log.debug("\(String(describing: Self.self)) init")
        addSubview(backgroundGradientView)
        addSubview(navigationView)
        navigationView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(Constants.Size.ItemHeightMid)
        }
        
        addSubview(featureView)
        featureView.featuresType = featuresType
        featureView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(navigationView.snp.bottom)
        }
        backgroundGradientView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.bottom.equalTo(featureView.snp.bottom)
        }
        
        addSubview(priceView)
        priceView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(featureView.snp.bottom)
            make.height.equalTo(447)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageLayer.contents = R.image.game_cover_bg()?.scaled(toWidth: backgroundGradientView.width)?.cropped(to: backgroundGradientView.bounds).cgImage
        imageLayer.frame = CGRect(origin: .zero, size: backgroundGradientView.size)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
