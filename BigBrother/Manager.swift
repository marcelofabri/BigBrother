//
//  Manager.swift
//  BigBrother
//
//  Created by Marcelo Fabri on 01/01/15.
//  Copyright (c) 2015 Marcelo Fabri. All rights reserved.
//

import Foundation
import UIKit

/**
*  A protocol that represents an object that can manage a network activity indicator.
*/
public protocol NetworkActivityIndicatorOwner {
    var networkActivityIndicatorVisible: Bool { get set }
}

/**
*  UIApplication already conforms to NetworkActivityIndicatorOwner.
*/
extension UIApplication: NetworkActivityIndicatorOwner {}

/**
   Manages manages the state of the network activity indicator in the status bar.
   Based on AFNetworkActivityIndicatorManager from AFNetworking.
*/
open class Manager {
    fileprivate var _activityCount: Int = 0
   
    fileprivate var activityCount: Int {
        get {
            return self._activityCount
        }
        set {
            synchronized(self, self._activityCount = newValue)
            DispatchQueue.main.async {
                self.updateNetworkActivityIndicatorVisibility()
            }
        }
    }
    
    fileprivate var activityIndicatorVisibilityTimer: Timer?
    fileprivate let invisibilityDelay: TimeInterval = 0.17
    
    /// The responsible for owning the network activity indicator. Defaults to UIApplication.sharedApplication().
    open var application: NetworkActivityIndicatorOwner
    
    /// Indicates whether the network activity indicator is visible.
    open var networkActivityIndicatorVisible: Bool {
        return activityCount > 0
    }
    
    /**
        Inits a manager.
    
        - parameter application: The responsible for owning the network activity indicator. If omitted, defaults to UIApplication.sharedApplication().
    
        - returns: An initializated manager
    */
    public init(application: NetworkActivityIndicatorOwner = UIApplication.shared) {
        self.application = application
    }
    
    /// The singleton instance.
    open static let sharedInstance = Manager()
    
    /**
        Increments the number of active network requests. If this number was zero before incrementing, this will start animating the status bar network activity indicator.
    */
    open func incrementActivityCount() {
        synchronized(self, self._activityCount += 1)
        
        DispatchQueue.main.async {
            self.updateNetworkActivityIndicatorVisibilityDelayed()
        }
    }
    
    /**
        Decrements the number of active network requests. If this number becomes zero after decrementing, this will stop animating the status bar network activity indicator.
    */
    open func decrementActivityCount() {
        synchronized(self, self._activityCount = max(self._activityCount - 1, 0))
        
        DispatchQueue.main.async {
            self.updateNetworkActivityIndicatorVisibilityDelayed()
        }
    }
    
    // MARK: Private
    
    @objc fileprivate func updateNetworkActivityIndicatorVisibility() {
        application.networkActivityIndicatorVisible = networkActivityIndicatorVisible
    }
    
    fileprivate func updateNetworkActivityIndicatorVisibilityDelayed() {
        if !networkActivityIndicatorVisible {
            activityIndicatorVisibilityTimer?.invalidate()
            activityIndicatorVisibilityTimer = Timer(timeInterval: invisibilityDelay,
                target: self, selector: #selector(Manager.updateNetworkActivityIndicatorVisibility), userInfo: nil, repeats: false)
            RunLoop.main.add(activityIndicatorVisibilityTimer!, forMode: RunLoopMode.commonModes)
        } else {
            DispatchQueue.main.async {
                self.updateNetworkActivityIndicatorVisibility()
            }
        }
    }
}

/**
    Runs a closure in a synchronized way.

    - parameter lock:    The object to be used to synchronize
    - parameter closure: The closure that will be run in a synchronized way
*/
private func synchronized(_ lock: AnyObject, _ closure: @autoclosure () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}
