//
//  Animator.swift
//  AnimationTest
//
//  Created by Jan Nash on 24.09.20.
//

import UIKit


// TODO:
/*
 - tabview to check what happens when view disappears and reappears
 - test view resizing while animator is running
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
    
    // Setting these while the animation is running is not implemented yet
    var duration: Double = 10
    var configuration: Configuration = .curve(.linear)
    var animation: Animation?
    
    private(set) var progress: CGFloat = 0
    private(set) var isRunning = false
    
    private var _animator: UIViewPropertyAnimator?
    private var animator: UIViewPropertyAnimator { _animator ?? createAnimator() }
    private func createAnimator() -> UIViewPropertyAnimator {
        let animator: UIViewPropertyAnimator = {
            switch configuration {
            case .timingParameters(let parameters):
                return .init(duration: duration, timingParameters: parameters)
            case .curve(let curve):
                return .init(duration: duration, curve: curve)
            case .controlPoints(let controlPoint1, let controlPoint2):
                return .init(duration: duration, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            case .dampingRatio(let dampingRatio):
                return .init(duration: duration, dampingRatio: dampingRatio)
            }
        }()
        
        animator.pausesOnCompletion = true
        animator.pauseAnimation()
        if let animation = animation {
            animator.addAnimations(animation.execute)
        }
        animator.fractionComplete = progress
        
        _animator = animator
        return animator
    }
    
    init() {
        [UIApplication.didBecomeActiveNotification, UIApplication.willResignActiveNotification].forEach({
            NotificationCenter.default.addObserver(self, selector: #selector(receivedAppLifecycleNotification), name: $0, object: nil)
        })
    }
    
    @objc private func receivedAppLifecycleNotification(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didBecomeActiveNotification:
            if isRunning { _animator?.startAnimation() }
        case UIApplication.willResignActiveNotification:
            _animator?.pauseAnimation()
        default: return
        }
    }
    
    func updateForFrameChange() {
        guard let oldAnimator = _animator, UIApplication.shared.applicationState == .active else { return }
        _animator?.stopAnimation(true)
        _animator?.finishAnimation(at: .current)
        _animator = nil
        let isRunning = oldAnimator.isRunning
        animator.fractionComplete = progress
        if isRunning {
            animator.startAnimation()
        }
    }
    
    func stop() {
        _animator?.pauseAnimation()
        
        _animator?.fractionComplete = 0
        progress = 0
        
        isRunning = false
    }
    
    func pause() {
        _animator?.pauseAnimation()
        progress = _animator?.fractionComplete ?? 0
        isRunning = false
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
        isRunning = true
    }
}
