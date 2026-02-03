//
//  SwitchView.swift
//  Pods
//
//  Created by Daiuno on 2026/1/24.
//

class SwitchView: UIView {
    var state: Bool = false {
        didSet {
            if let animation {
                if animation.type == "spring" {
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, animations: {
                        self.imageView.frame = (self.state ? animation.end : animation.begin) ?? self.bounds
                        self.imageView.image = self.state ? self.onImage : self.offImage
                    }, completion: { _ in
                        if self.state, self.selfRetracting {
                            self.state = false
                        }
                    })
                }
            }
        }
    }
    var isHapticEnabled = true
    
    var valueChangedHandler: ((_ inputString: Input) -> Void)?
    
    var onImage: UIImage? {
        didSet {
            if state {
                imageView.image = onImage
            }
        }
    }
    
    var offImage: UIImage?{
        didSet {
            if !state {
                imageView.image = offImage
            }
        }
    }
    
    var input: Input
    var selfRetracting: Bool
    
    var animation: ControllerSkin.Item.Animation? {
        didSet {
            imageView.frame = (state ? animation?.end : animation?.begin) ?? bounds
        }
    }
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(frame: self.animation?.begin ?? bounds)
        view.contentMode = .center
        return view
    }()

    private var feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    //添加震感的样式
    var hapticFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .soft {
        didSet {
            feedbackGenerator = UIImpactFeedbackGenerator(style: hapticFeedbackStyle)
        }
    }
    
    init(input: Input, selfRetracting: Bool) {
        self.input = input
        self.selfRetracting = selfRetracting
        super.init(frame: .zero)
        addSubview(imageView)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:))))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handleTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        feedbackGenerator.impactOccurred()
        state = !state
        valueChangedHandler?(input)
    }
}
