//
//  ViewController.swift
//  AnimationTest
//
//  Created by Jan Nash on 17.09.20.
//

import UIKit


class Animation {
    let id = UUID()
    private let animation: () -> Void
    
    init<T: UIView>(for view: T, animation: @escaping (T) -> Void) {
        self.animation = { [weak view] in
            guard let view = view else { return }
            animation(view)
        }
    }
    
    func execute() { animation() }
}


class Animator {
    enum Configuration {
        case timingParameters(UITimingCurveProvider)
        case curve(UIView.AnimationCurve)
        case controlPoints(p1: CGPoint, p2: CGPoint)
        case dampingRatio(CGFloat)
    }
    
    var duration: Double = 10
    var configuration: Configuration = .curve(.linear)
    var animation: Animation?
    
    private(set) var progress: CGFloat = 0
    
    private var _animator: UIViewPropertyAnimator?
    private var animator: UIViewPropertyAnimator {
        _animator ?? {
            switch configuration {
            case .timingParameters(let parameters):
                _animator = .init(duration: duration, timingParameters: parameters)
            case .curve(let curve):
                _animator = .init(duration: duration, curve: curve)
            case .controlPoints(let controlPoint1, let controlPoint2):
                _animator = .init(duration: duration, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            case .dampingRatio(let dampingRatio):
                _animator = .init(duration: duration, dampingRatio: dampingRatio)
            }
            
            _animator?.pausesOnCompletion = true
            _animator?.pauseAnimation()
            if let animation = animation {
                _animator?.addAnimations(animation.execute)
            }
            _animator?.fractionComplete = progress
            
            return _animator!
        }()
    }

    enum StopType {
        case withoutFinishing
        case finish(position: UIViewAnimatingPosition)
    }
    
    func stop(_ type: StopType) {
        _animator?.stopAnimation(true)
        if case .finish(let position) = type {
            _animator?.finishAnimation(at: position)
        }
        progress = 0
    }
    
    func pause() {
        _animator?.pauseAnimation()
    }
    
    func seekTo(progress: CGFloat) {
        self.progress = progress
        guard let animator = _animator else { return }
        let isRunning = animator.isRunning
        animator.fractionComplete = progress
        if !isRunning {
            animator.pauseAnimation()
        }
    }
    
    func play(fromProgress progress: CGFloat? = nil) {
        guard animation != nil else { return }
        let progress = progress ?? self.progress
        if progress != animator.fractionComplete { seekTo(progress: progress) }
        animator.startAnimation()
        // This didn't work:
//        animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }
}



class ViewController: UIViewController {
    private var progressBarContainer = ProgressBarContainer()
    private lazy var startButton: UIButton = {
        let button = UIButton()
        button.setTitle("Start animation", for: .normal)
        button.addTarget(progressBarContainer, action: #selector(ProgressBarContainer.startAnimator), for: .touchUpInside)
        button.backgroundColor = UIColor.blue
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(progressBarContainer)
        progressBarContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressBarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressBarContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressBarContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            progressBarContainer.heightAnchor.constraint(equalToConstant: 60),
        ])
        
        view.addSubview(startButton)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: progressBarContainer.bottomAnchor, constant: 20),
            startButton.widthAnchor.constraint(equalTo: progressBarContainer.widthAnchor),
            startButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
}


class ProgressBarContainer: UIView {
    required init?(coder: NSCoder) { fatalError() }
    init() {
        super.init(frame: .zero)
        backgroundColor = .green
        addSubview(progressBar)
        
        let ns = NotificationCenter.default
        ns.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private var progressBar = ProgressBar()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        progressBar.frame = bounds.inset(by: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
        progressBar.layoutIfNeeded()
    }
    
    private lazy var animator: Animator = {
        let animator = Animator()
        animator.duration = 10
        animator.configuration = .curve(.linear)
        animator.seekTo(progress: 0.5)
        animator.animation = Animation(for: self) { view in
            view.progressBar.setProgress(0)
            UIView.animateKeyframes(withDuration: 10, delay: 0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                    view.progressBar.setProgress(1)
                }
            })
        }
        return animator
    }()
    
    @objc func startAnimator() {
        animator.play()
    }
}

extension ProgressBarContainer {
    override func didMoveToWindow() {
        print("didMoveToWindow - window == nil: \(window == nil)")
        super.didMoveToWindow()
        if window == nil {
            // disappeared
//            animator.pause()
        } else {
            // appeared
//            animator.play()
//            createAnimator()
        }
    }
    
    @objc private func applicationWillEnterForeground() {
        print("applicationWillEnterForeground")
//        createAnimator()
    }
}


class ProgressBar: UIView {
    func setProgress(_ progress: CGFloat) {
        self.progress = progress
        upcomingView.frame.size.width = frame.width * progress
    }
    
    private var progress: CGFloat = 0
    
    var progressColor = UIColor.red { didSet { upcomingView.backgroundColor = progressColor } }
    
    required init?(coder: NSCoder) { fatalError() }
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .yellow
    }
    
    private lazy var upcomingView: UIView = {
        let view = UIView()
        view.backgroundColor = progressColor
        addSubview(view)
        return view
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        upcomingView.frame = bounds
        setProgress(progress)
    }
}

