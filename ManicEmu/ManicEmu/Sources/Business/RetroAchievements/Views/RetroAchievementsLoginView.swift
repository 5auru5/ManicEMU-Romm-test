//
//  RetroAchievementsLoginView.swift
//  ManicEmu
//
//  Created by Daiuno on 2025/8/19.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

class RetroLoginFooterReusableView: UICollectionReusableView {
    let button: SymbolButton = {
        let view = SymbolButton(image: nil, title: "", titleFont: Constants.Font.body(size: .l, weight: .medium), titleColor: Constants.Color.LabelPrimary.forceStyle(.dark), horizontalContian: true, titlePosition: .right)
        view.enableRoundCorner = true
        view.backgroundColor = Constants.Color.Red
        return view
    }()
    
    let register: UIButton = {
        let view = UIButton(type: .custom)
        let att = NSAttributedString(string: R.string.localizable.achievementsRegisterTitle(), attributes: [.font: Constants.Font.body(size: .l), .foregroundColor: Constants.Color.LabelSecondary])
        view.onTap {
            UIApplication.shared.open(Constants.URLs.RetroSignUp)
        }
        view.setAttributedTitle(att.underlined, for: .normal)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Constants.Size.ContentSpaceHuge)
            make.height.equalTo(Constants.Size.ItemHeightMid)
            make.top.equalToSuperview().offset(Constants.Size.ItemHeightMin)
        }
        
        let labelContainer = UIView()
        addSubview(labelContainer)
        labelContainer.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(Constants.Size.ContentSpaceMax)
            make.centerX.equalToSuperview()
        }
        
        let notMemberLabel = UILabel()
        notMemberLabel.text = R.string.localizable.achievementsNotMember()
        notMemberLabel.font = Constants.Font.body(size: .l)
        notMemberLabel.textColor = Constants.Color.LabelSecondary
        
        labelContainer.addSubviews([notMemberLabel, register])
        register.snp.makeConstraints { make in
            make.leading.equalTo(notMemberLabel.snp.trailing).offset(Constants.Size.ContentSpaceUltraTiny)
            make.top.bottom.trailing.equalToSuperview()
        }
        notMemberLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalTo(register)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
}

class RetroAchievementsLoginView: BaseView {
    private var editItems: [LanServiceEditViewController.EditItem] = []
    private var username: String? = nil
    private var password: String? = nil
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        view.register(cellWithClass: LanServiceEditCollectionViewCell.self)
        view.register(supplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withClass: RetroLoginFooterReusableView.self)
        view.showsVerticalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.contentInset = UIEdgeInsets(top: 90, left: 0, bottom: Constants.Size.ContentInsetBottom, right: 0)
        return view
    }()
    
    private weak var button: SymbolButton? = nil
    
    var loginSuccess: (()->Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let user = LanServiceEditViewController.EditItem(title: R.string.localizable.landServiceEditUserName(),
                            placeholderString: "",
                            keyboardType: .default,
                            requiredField: false,
                            type: .user,
                            returnKeyType: .next)
        let password = LanServiceEditViewController.EditItem(title: R.string.localizable.landServiceEditPassword(),
                                placeholderString: "",
                                keyboardType: .default,
                                requiredField: false,
                                type: .password,
                                returnKeyType: .done)
        editItems.append(contentsOf: [user, password])
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
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(84)), subitems: [item])
            group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: Constants.Size.ContentSpaceMid,
                                                            bottom: 0,
                                                            trailing: Constants.Size.ContentSpaceMid)
            //section布局
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Constants.Size.ContentSpaceHuge
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            
            let footerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                                            heightDimension: .absolute(130)),
                                                                         elementKind: UICollectionView.elementKindSectionFooter,
                                                                         alignment: .bottom)
            section.boundarySupplementaryItems.append(footerItem)
            
            return section
        }
        return layout
    }
    
    private func updateButton() {
        guard let button else { return }
        if let username = self.username, !username.trimmed.isEmpty, let password = self.password, !password.isEmpty {
            button.backgroundColor = Constants.Color.Main
            button.titleLabel.textColor = Constants.Color.LabelPrimary.forceStyle(.dark)
            button.isUserInteractionEnabled = true
        } else {
            button.backgroundColor = Constants.Color.BackgroundSecondary
            button.titleLabel.textColor = Constants.Color.LabelSecondary
            button.isUserInteractionEnabled = false
        }
    }
}

extension RetroAchievementsLoginView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        editItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: LanServiceEditCollectionViewCell.self, for: indexPath)
        let item =  editItems[indexPath.row]
        if item.type == .password {
            cell.editTextField.isSecureTextEntry = true
        } else {
            cell.editTextField.isSecureTextEntry = false
        }
        cell.setData(item:item)
        cell.shouldGoNext = { [weak self] in
            guard let self = self else { return }
            if let cell = self.collectionView.cellForItem(at: IndexPath(row: indexPath.row + 1, section: indexPath.section)) as? LanServiceEditCollectionViewCell {
                cell.editTextField.becomeFirstResponder()
            }
        }
        cell.editTextField.onChange { [weak self] string in
            guard let self = self else { return }
            if item.type == .user {
                self.username = string
            } else if item.type == .password {
                self.password = string
            }
            self.updateButton()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: RetroLoginFooterReusableView.self, for: indexPath)
        footer.button.titleLabel.text = R.string.localizable.achievementsLoginTitle()
        button = footer.button
        updateButton()
        footer.button.addTapGesture { [weak self] gesture in
            guard let self else { return }
            guard let username = self.username, !username.isEmpty, let password = self.password, !password.isEmpty else {
                return
            }
            UIView.makeLoading()
            CheevosBridge.loginCheevos(username, password: password) { [weak self] result, user in
                UIView.hideLoading()
                /**
                 const char* display_name; Daiuno
                 const char* username; Daiuno
                 const char* token; YNdH4yRapojs0moo
                 uint32_t score; 4
                 uint32_t score_softcore; 0
                 uint32_t num_unread_messages; 0
                 */
                if let _ = user {
                    self?.loginSuccess?()
                } else {
                    if result == LoginResult.invalid ||  result == LoginResult.expired {
                        UIView.makeToast(message: R.string.localizable.achievementsLoginFail())
                    } else if result == LoginResult.denied {
                        UIView.makeToast(message: R.string.localizable.achievementsLoginDenied())
                    } else if result == LoginResult.serverError {
                        UIView.makeToast(message: R.string.localizable.achievementsServerError())
                    } else if result == LoginResult.unknown {
                        UIView.makeToast(message: R.string.localizable.errorUnknown())
                    }
                }
            }
        }
        return footer
    }
}

extension RetroAchievementsLoginView: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for cell in collectionView.visibleCells {
            if let cell = cell as? LanServiceEditCollectionViewCell {
                if cell.editTextField.isFirstResponder {
                    cell.editTextField.resignFirstResponder()
                    break
                }
            }
        }
    }
}
