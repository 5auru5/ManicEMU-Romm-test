//
//  AddTriggerMappingCell.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/10/22.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

class AddTriggerMappingCell: UICollectionViewCell {
    
    lazy var mappingListView: TriggerProMappingListView = {
        let view = TriggerProMappingListView(inputs: [], isHorizontalScroll: true, isEditMode: true)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layerCornerRadius = Constants.Size.CornerRadiusMax
        backgroundColor = Constants.Color.BackgroundPrimary
        
        addSubview(mappingListView)
        mappingListView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func setDatas(inputs: [String]) {
        mappingListView.inputs = [inputs]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
