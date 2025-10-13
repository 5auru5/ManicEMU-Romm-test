//
//  FeaturesView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/3/15.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import JXBanner
import JXPageControl

enum FeaturesType: Int, CaseIterable {
    case advance = 0, `import`, controler, airplay, iCloud
    
    var title: String {
        switch self {
        case .advance:
            R.string.localizable.purchaseAdcancedFeaturesTitle()
        case .import:
            R.string.localizable.purchaseImportFeaturesTitle()
        case .controler:
            R.string.localizable.purchaseControllerFeaturesTitle()
        case .airplay:
            R.string.localizable.purchaseAirPlayFeaturesTitle()
        case .iCloud:
            R.string.localizable.purchaseiCloudFeaturesTitle()
        }
    }
    
    var image: UIImage? {
        switch self {
        case .advance:
            R.image.advance_features_bg()
        case .import:
            R.image.import_service_bg()
        case .controler:
            R.image.controller_white_bg()
        case .airplay:
            R.image.airplay_bg()
        case .iCloud:
            R.image.iCloud_bg()
        }
    }
}

class FeaturesView: UIView {
    private lazy var banner: JXBanner = {
        let banner = JXBanner()
        banner.backgroundColor = UIColor.black
        banner.delegate = self
        banner.dataSource = self
        banner.backgroundColor = .clear
        return banner
    }()
    
    var featuresType: FeaturesType? = nil
    
    deinit {
        Log.debug("\(String(describing: Self.self)) deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        Log.debug("\(String(describing: Self.self)) init")
        addSubview(banner)
        banner.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let featuresType = self.featuresType {
            DispatchQueue.main.async {
                self.banner.scrollToIndex(featuresType.rawValue, animated: false)
            }
            self.featuresType = nil
        }
    }
}

extension FeaturesView: JXBannerDataSource {
    
    // 注册重用Cell标识
    func jxBanner(_ banner: JXBannerType) -> JXBannerCellRegister {
        return JXBannerCellRegister(type: FeaturesCell.self, reuseIdentifier: String(describing: FeaturesCell.self))
    }
    
    // 轮播总数
    func jxBanner(numberOfItems banner: JXBannerType) -> Int {
        FeaturesType.allCases.count
    }
    
    func jxBanner(_ banner: any JXBannerType, params: JXBannerParams) -> JXBannerParams {
        params.isAutoPlay = false
        return params
    }
    
    // 轮播cell内容设置
    func jxBanner(_ banner: JXBannerType, cellForItemAt index: Int, cell: UICollectionViewCell) -> UICollectionViewCell {
        if let cell = cell as? FeaturesCell, let type = FeaturesType(rawValue: index) {
            cell.setData(type: type)
        }
        return cell
    }
    
    func jxBanner(pageControl banner: any JXBannerType, numberOfPages: Int, coverView: UIView, builder: JXBannerPageControlBuilder) -> JXBannerPageControlBuilder {
        let pageControl = JXPageControlJump()
        pageControl.contentMode = .center
        pageControl.isAnimation = true
        pageControl.activeColor = Constants.Color.LabelPrimary.forceStyle(.dark)
        pageControl.inactiveColor = Constants.Color.LabelPrimary.forceStyle(.dark).withAlphaComponent(0.15)
        pageControl.indicatorSize = .init(6)
        pageControl.columnSpacing = Constants.Size.ContentSpaceUltraTiny
        pageControl.contentAlignment = JXPageControlAlignment(.center, .bottom)
        builder.pageControl = pageControl
        builder.layout = {
            pageControl.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview().offset(-Constants.Size.ContentSpaceMin)
                make.height.equalTo(6)
            }
        }
        return builder
    }
}

extension FeaturesView: JXBannerDelegate {

    
}
