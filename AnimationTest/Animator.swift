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
 */


struct Keyframes<T: UIView> {
    let id = UUID()
    private weak var view: T?
    private let keyframes: () -> Void
    
    init(for view: T, _ frames: [(relStart: Double, relDuration: Double, animation: (T) -> Void)]) {
        self.view = view
        self.keyframes = { [weak view] in
            guard let view = view else { return }
            frames.map({ frame in (frame.0, frame.1, { frame.2(view) }) }).forEach(UIView.addKeyframe)
        }
    }
    
    func evaluate() { keyframes() }
    func layoutViewIfNeeded() { view?.layoutIfNeeded() }
}


class Animator<T: UIView> {
    var keyframes: Keyframes<T>?
    
    private let duration: Double
    private(set) var progress: CGFloat = 0
    private(set) var isRunning = false
    private(set) var backgroundTransitionTime: CFTimeInterval?
    
    private var _animator: UIViewPropertyAnimator?
    private var animator: UIViewPropertyAnimator {
        _animator ?? {
            let duration = self.duration
            let animator = UIViewPropertyAnimator(duration: duration, curve: .linear)
            animator.pausesOnCompletion = true
            animator.fractionComplete = progress
            
            if let keyframes = keyframes {
                animator.addAnimations({
                    UIView.animateKeyframes(withDuration: duration, delay: 0) { keyframes.evaluate() }
                })
            }
            
            _animator = animator
            return animator
        }()
    }
    
    init(duration: Double) {
        self.duration = duration
        [UIApplication.willEnterForegroundNotification, UIApplication.willResignActiveNotification].forEach({
            NotificationCenter.default.addObserver(self, selector: #selector(receivedAppLifecycleNotification), name: $0, object: nil)
        })
    }
    
    func updateForLayoutChange() {
        guard let currentAnimator = _animator, UIApplication.shared.applicationState == .active else { return }
        let isRunning = currentAnimator.isRunning
        currentAnimator.stopAnimation(true)
        currentAnimator.finishAnimation(at: .current)
        _animator = nil
        keyframes?.layoutViewIfNeeded()
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
        pauseAnimator()
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
    
    func play() {
        guard keyframes != nil else { return }
        if let existingAnimator = _animator, existingAnimator.isRunning { return }
        if animator.fractionComplete == 1 {
            seekTo(progress: 0)
        }
        animator.startAnimation()
        isRunning = true
    }
    
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
