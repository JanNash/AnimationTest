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
 - test view layout changes while animator is running
 - save current time when going to background and advance progress accordingly when coming back to foreground
 */


struct Keyframes {
    let id = UUID()
    private let keyframes: () -> Void
    
    init<T: UIView>(for view: T, keyframes: @escaping (T) -> Void) {
        self.keyframes = { [weak view] in
            guard let view = view else { return }
            keyframes(view)
        }
    }
    
    func execute() { keyframes() }
}


class Animator {
    var keyframes: Keyframes?
    
    private let duration: Double
    private(set) var progress: CGFloat = 0
    private(set) var isRunning = false
    
    private var _animator: UIViewPropertyAnimator?
    private var animator: UIViewPropertyAnimator { _animator ?? createAnimator() }
    private func createAnimator() -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: duration, curve: .linear)
        
        animator.pausesOnCompletion = true
        animator.pauseAnimation()
        if let animation = keyframes {
            animator.addAnimations({ [weak self] in
                guard let self = self else { return }
                UIView.animateKeyframes(withDuration: self.duration, delay: 0, animations: animation.execute)
            })
        }
        animator.fractionComplete = progress
        
        _animator = animator
        return animator
    }
    
    init(duration: Double) {
        self.duration = duration
        [UIApplication.didBecomeActiveNotification, UIApplication.willResignActiveNotification].forEach({
            NotificationCenter.default.addObserver(self, selector: #selector(receivedAppLifecycleNotification), name: $0, object: nil)
        })
    }
    
    @objc private func receivedAppLifecycleNotification(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didBecomeActiveNotification:
            // FIXME: Advance progress according to passed time since going to background
            if isRunning { _animator?.startAnimation() }
        case UIApplication.willResignActiveNotification:
            _animator?.pauseAnimation()
        default: return
        }
    }
    
    func updateForLayoutChange() {
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
        guard keyframes != nil else { return }
        if let existingAnimator = _animator, existingAnimator.isRunning { return }
        animator.startAnimation()
        isRunning = true
    }
}
