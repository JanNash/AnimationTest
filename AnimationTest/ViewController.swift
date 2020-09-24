//
//  ViewController.swift
//  AnimationTest
//
//  Created by Jan Nash on 17.09.20.
//

import UIKit

// TODO:
/*
 - tabview to check what happens when view disappears and reappears
 - test view resizing while animator is running
 - observe app lifecycle notifications?
 - fix setting progress before animator is started
 */


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
    
    enum StopType {
        case withoutFinishing
        case finish(position: UIViewAnimatingPosition)
    }
    
    // Setting these while the animation is running is not implemented yet
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
    
    func stop(_ type: StopType) {
        pause()
        _animator?.fractionComplete = 0
        progress = 0
    }
    
    func pause() {
        _animator?.pauseAnimation()
        progress = _animator?.fractionComplete ?? 0
    }
    
    func seekTo(progress: CGFloat) {
        self.progress = progress
        let isRunning = animator.isRunning
        animator.fractionComplete = progress
        if !isRunning {
            animator.pauseAnimation()
        }
    }
    
    func play() {
        guard animation != nil else { return }
        if let animator = _animator, animator.isRunning { return }
        animator.startAnimation()
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
    
    private lazy var pauseButton: UIButton = {
        let button = UIButton()
        button.setTitle("Pause animation", for: .normal)
        button.addTarget(progressBarContainer, action: #selector(ProgressBarContainer.pauseAnimator), for: .touchUpInside)
        button.backgroundColor = UIColor.blue
        return button
    }()
    
    private lazy var stopButton: UIButton = {
        let button = UIButton()
        button.setTitle("Stop animation", for: .normal)
        button.addTarget(progressBarContainer, action: #selector(ProgressBarContainer.stopAnimator), for: .touchUpInside)
        button.backgroundColor = UIColor.blue
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(progressBarContainer)
        progressBarContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressBarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressBarContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -150),
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
        
        view.addSubview(pauseButton)
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pauseButton.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 20),
            pauseButton.widthAnchor.constraint(equalTo: progressBarContainer.widthAnchor),
            pauseButton.heightAnchor.constraint(equalToConstant: 60),
        ])
        
        view.addSubview(stopButton)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopButton.topAnchor.constraint(equalTo: pauseButton.bottomAnchor, constant: 20),
            stopButton.widthAnchor.constraint(equalTo: progressBarContainer.widthAnchor),
            stopButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
}


class ProgressBarContainer: UIView {
    required init?(coder: NSCoder) { fatalError() }
    init() {
        super.init(frame: .zero)
        backgroundColor = .green
        addSubview(progressBar)
        animator = createAnimator()
    }
    
    private var progressBar = ProgressBar()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        progressBar.frame = bounds.inset(by: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
        progressBar.layoutIfNeeded()
//        animator?.seekTo(progress: 0.5)
    }
    
    private var animator: Animator?
    func createAnimator() -> Animator {
        let animator = Animator()
        animator.duration = 10
        animator.configuration = .curve(.linear)
        animator.animation = Animation(for: self) { view in
            view.progressBar.setProgress(0)
            UIView.animateKeyframes(withDuration: 10, delay: 0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                    view.progressBar.setProgress(1)
                }
            })
        }
//        animator.seekTo(progress: 0.5)
        return animator
    }
    
    @objc func startAnimator() {
        animator?.play()
    }
    
    @objc func pauseAnimator() {
        animator?.pause()
    }
    
    @objc func stopAnimator() {
        animator?.stop(.withoutFinishing)
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


extension UIViewAnimatingState: CustomStringConvertible {
    public var description: String {
        return "UIViewAnimatingState." + {
            switch self {
            case .active: return "active"
            case .inactive: return "inactive"
            case .stopped: return "stopped"
            @unknown default: return "@unknown.default(rawValue: \(rawValue))"
            }
        }()
    }
}
