//
//  ManufacturerCategoryView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/11/9.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

class ManufacturerCategoryView: BaseView {
    class ManufacturerCategoryCell: UICollectionViewCell {
        let normalImageView: UIImageView = {
            let view = UIImageView()
            view.contentMode = .center
            return view
        }()
        
        let selectedImageView: UIImageView = {
            let view = UIImageView()
            view.contentMode = .center
            view.isHidden = true
            return view
        }()
        
        var onLongPress: (()->Void)? = nil
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            enableInteractive = true
            delayInteractiveTouchEnd = true
            
            addSubview(normalImageView)
            normalImageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            addSubview(selectedImageView)
            selectedImageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPress.minimumPressDuration = 0.5
            longPress.cancelsTouchesInView = true
            longPress.delaysTouchesBegan = false
            longPress.delaysTouchesEnded = true
            addGestureRecognizer(longPress)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                onLongPress?()
            }
        }
        
        override var isSelected: Bool {
            willSet {
                normalImageView.isHidden = newValue
                selectedImageView.isHidden = !newValue
            }
        }
        
        func setDatas(normalImage: UIImage, highlightImage: UIImage) {
            normalImageView.image = normalImage
            selectedImageView.image = highlightImage
        }
    }
    
    var didManufacturerChange: ((Manufacturer?)->Bool)? = nil
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: ManufacturerCategoryCell.self)
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.alwaysBounceHorizontal = false
        view.alwaysBounceVertical = false
        view.allowsSelection = true
        view.allowsMultipleSelection = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env in
            //item布局
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
            

            
            //group布局
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(UIDevice.isPhone ? 1/4 : 1/5), heightDimension: .fractionalHeight(1)), subitem: item, count: 1)
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            
            return section
        }
        return layout
    }
    
    func deselectAll() {
        if let indexPaths = collectionView.indexPathsForSelectedItems {
            for indexPath in indexPaths {
                collectionView.deselectItem(at: indexPath, animated: false)
            }
            _ = didManufacturerChange?(nil)
        }
    }
}

extension ManufacturerCategoryView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Manufacturer.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: ManufacturerCategoryCell.self, for: indexPath)
        if let manufacturer = Manufacturer(rawValue: indexPath.row) {
            cell.setDatas(normalImage: manufacturer.normalImage, highlightImage: manufacturer.highlightImage)
            cell.onLongPress = {
                topViewController()?.present(WebViewController(url: Constants.URLs.manufacturer(manufacturer)), animated: true)
            }
        }
        return cell
    }
}

extension ManufacturerCategoryView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let cell = collectionView.cellForItem(at: indexPath), cell.isSelected {
            collectionView.deselectItem(at: indexPath, animated: true)
            return didManufacturerChange?(nil) ?? false
        }
        
        if let manufacturer = Manufacturer(rawValue: indexPath.row) {
            return didManufacturerChange?(manufacturer) ?? false
        }
        
        return false
    }
}
