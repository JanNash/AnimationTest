//
//  ViewController.swift
//  AnimationTest
//
//  Created by Jan Nash on 17.09.20.
//

import UIKit

class ViewController: UIViewController {
    private var progressBarContainer = ProgressBarContainer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(progressBarContainer)
        progressBarContainer.translatesAutoresizingMaskIntoConstraints = false
        progressBarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        progressBarContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        progressBarContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        progressBarContainer.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        progressBarContainer.startAnimator()
    }
}


class ProgressBarContainer: UIView {
    required init?(coder: NSCoder) { fatalError() }
    init() {
        super.init(frame: .zero)
        backgroundColor = .green
        addSubview(progressBar)
    }
    
    private var progressBar = ProgressBar()
    private let duration: TimeInterval = 30
    
    override func layoutSubviews() {
        super.layoutSubviews()
        progressBar.frame = bounds.inset(by: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
        progressBar.layoutIfNeeded()
        createAnimator()
    }
    
    private var animator: UIViewPropertyAnimator? {
        willSet {
            guard animator?.state != .inactive else { return }
            animator?.stopAnimation(true)
            animator?.finishAnimation(at: .current)
        }
    }
    
    private var currentTime: TimeInterval {
        get {
            guard let animator = animator, duration > 0 else { return 0 }
            return Double(animator.fractionComplete) * duration
        }
        set {
            guard let animator = animator, duration > 0 else { return }
            animator.fractionComplete = CGFloat(newValue / duration)
        }
    }
    
    private func createAnimator() {
        // Save State
        let time = currentTime
        let isRunning = animator?.isRunning ?? false
        
        let animator = UIViewPropertyAnimator(duration: duration, curve: .linear)
        animator.pausesOnCompletion = true
        animator.pauseAnimation()
        
        progressBar.setProgress(0)
        
        animator.addAnimations { [weak self] in
            guard let self = self else { return }
            UIView.animateKeyframes(withDuration: self.duration, delay: 0, animations: { [weak self] in
                guard let self = self, self.duration > 0 else { return }
                
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                    self.progressBar.setProgress(1)
                }
            })
        }
        
        self.animator = animator
        
        // Restore State
        currentTime = time
        if isRunning {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    
    func startAnimator() {
        animator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }
}


class ProgressBar: UIView {
    func setProgress(_ progress: CGFloat) {
        self.progress = progress
        upcomingView.frame.size.width = frame.width * progress
    }
    
    private var progress: CGFloat = 0.4
    
    required init?(coder: NSCoder) { fatalError() }
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .yellow
    }
    
    private lazy var upcomingView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        addSubview(view)
        return view
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        upcomingView.frame = bounds
        setProgress(progress)
    }
}

