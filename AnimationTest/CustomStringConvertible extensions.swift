//
//  CustomStringConvertible extensions.swift
//  AnimationTest
//
//  Created by Jan Nash on 24.09.20.
//

import UIKit


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


extension UIApplication.State: CustomStringConvertible {
    public var description: String {
        return "UIApplication.State." + {
            switch self {
            case .active: return "active"
            case .background: return "background"
            case .inactive: return "inactive"
            @unknown default: return "@unknown.default(rawValue: \(rawValue))"
            }
        }()
    }
}
