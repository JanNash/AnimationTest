//
//  clamp.swift
//  AnimationTest
//
//  Created by Jan Nash on 24.09.20.
//

import Foundation


func clamp<T>(_ value: T, to range: ClosedRange<T>) -> T {
    max(range.lowerBound, min(value, range.upperBound))
}


extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        clamp(self, to: range)
    }
}
