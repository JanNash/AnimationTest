//
//  Animator.swift
//  AnimationTest
//
//  Created by Jan Nash on 24.09.20.
//

import UIKit


class Animator<T: UIView> {
    // Keyframes
    var keyframes: Keyframes<T>?
    
    // Private State
    private let duration: Double
    private var progress: CGFloat = 0
    private var isRunning = false
    private var backgroundTransitionTime: CFTimeInterval?
    
    // UIViewPropertyAnimator
    private var _animator: UIViewPropertyAnimator?
    private var animator: UIViewPropertyAnimator {
        _animator ?? {
            let duration = self.duration
            let animator = UIViewPropertyAnimator(duration: duration, curve: .linear)
            animator.pausesOnCompletion = true
            
            if let keyframes = keyframes {
                animator.addAnimations({
                    UIView.animateKeyframes(withDuration: duration, delay: 0, animations: keyframes.evaluate)
                })
            }
            
            if progress != 0 {
                animator.startAnimation()
                animator.pauseAnimation()
                animator.fractionComplete = progress
            }
            
            _animator = animator
            return animator
        }()
    }
    
    // Initializer
    init(duration: Double) {
        self.duration = duration
        [UIApplication.willEnterForegroundNotification, UIApplication.willResignActiveNotification].forEach({
            NotificationCenter.default.addObserver(self, selector: #selector(receivedAppLifecycleNotification), name: $0, object: nil)
        })
    }
    
    // Destructor
    deinit {
        _animator?.stopAnimation(true)
        _animator?.finishAnimation(at: .current)
        _animator = nil
    }
    
    // Functions
    func play() {
        guard keyframes != nil else { return }
        if let existingAnimator = _animator, existingAnimator.isRunning { return }
        if animator.fractionComplete == 1 {
            seekTo(progress: 0)
        }
        animator.startAnimation()
        isRunning = true
    }
    
    func pause() {
        pauseAnimator()
        isRunning = false
    }
    
    func stop() {
        _animator?.pauseAnimation()
        _animator?.fractionComplete = 0
        progress = 0
        isRunning = false
    }
    
    func seekTo(progress: CGFloat) {
        let progress = progress.clamped(to: 0...1)
        self.progress = progress
        let isRunning = animator.isRunning
        animator.fractionComplete = progress
        if !isRunning {
            animator.pauseAnimation()
        }
    }
    
    func updateForLayoutChange() {
        guard let currentAnimator = _animator, UIApplication.shared.applicationState == .active else { return }
        let isRunning = currentAnimator.isRunning
        progress = currentAnimator.fractionComplete
        currentAnimator.stopAnimation(true)
        currentAnimator.finishAnimation(at: .current)
        _animator = nil
//        keyframes?.layoutViewIfNeeded()
        isRunning ? animator.startAnimation() : animator.pauseAnimation()
    }
    
    // Private Functions
    @objc private func receivedAppLifecycleNotification(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willEnterForegroundNotification:
            guard isRunning else { return }
            if let backgroundTransitionTime = backgroundTransitionTime {
                self.backgroundTransitionTime = nil
                let backgroundProgress = (CACurrentMediaTime() - backgroundTransitionTime) / duration
                seekTo(progress: progress + CGFloat(backgroundProgress))
            }
            _animator?.startAnimation()
        case UIApplication.willResignActiveNotification:
            guard isRunning else { return }
            pauseAnimator()
            backgroundTransitionTime = CACurrentMediaTime()
        default: return
        }
    }
    
    private func pauseAnimator() {
        _animator?.pauseAnimation()
        progress = _animator?.fractionComplete ?? 0
    }
}
