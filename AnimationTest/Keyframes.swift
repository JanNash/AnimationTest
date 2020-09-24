//
//  Keyframes.swift
//  AnimationTest
//
//  Created by Jan Nash on 24.09.20.
//

import UIKit


struct Keyframes<T: UIView> {
    // Private State
    private weak var view: T?
    private let keyframes: () -> Void
    
    // Initializer
    init(for view: T, _ frames: [(relStart: Double, relDuration: Double, animation: (T) -> Void)]) {
        self.view = view
        self.keyframes = { [weak view] in
            guard let view = view else { return }
            frames.map({ frame in (frame.0, frame.1, { frame.2(view) }) }).forEach(UIView.addKeyframe)
        }
    }
    
    // Functions
    func evaluate() { keyframes() }
    func layoutViewIfNeeded() { view?.layoutIfNeeded() }
}
