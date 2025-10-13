//
//  SparkleSeperatorView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/2/23.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class SparkleSeperatorView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    init(color: UIColor, lineColor: UIColor? = nil) {
        super.init(frame: .zero)
        setupViews(color: color, lineColor: lineColor)
    }
    
    init(isGradient: Bool) {
        super.init(frame: .zero)
        setupViews(isGradient: isGradient)
    }
    
    private func setupViews(color: UIColor = Constants.Color.Border, lineColor: UIColor? = nil, isGradient: Bool = false) {
        let starView = isGradient ? GradientImageView(image: UIImage(symbol: .sparkle, size: 24)) : UIImageView(image: UIImage(symbol: .sparkle, color: color))
        addSubview(starView)
        starView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let leftLine = UIView()
        leftLine.backgroundColor = lineColor ?? color
        addSubview(leftLine)
        leftLine.snp.makeConstraints { make in
            make.height.equalTo(Constants.Size.BorderLineHeight)
            make.leading.centerY.equalToSuperview()
            make.trailing.equalTo(starView.snp.leading).offset(-Constants.Size.ContentSpaceMin)
        }
        let rightLine = UIView()
        rightLine.backgroundColor = lineColor ?? color
        addSubview(rightLine)
        rightLine.snp.makeConstraints { make in
            make.height.equalTo(Constants.Size.BorderLineHeight)
            make.trailing.centerY.equalToSuperview()
            make.leading.equalTo(starView.snp.trailing).offset(Constants.Size.ContentSpaceMin)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
