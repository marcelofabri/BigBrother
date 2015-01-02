//
//  NetworkActivityIndicatorManager.swift
//  speakerdeckapp
//
//  Created by Marcelo Fabri on 01/01/15.
//  Copyright (c) 2015 Marcelo Fabri. All rights reserved.
//

import Foundation
import UIKit

/**
    Runs a closure in a synchronized way

    :param: lock    The object to be used to synchronize
    :param: closure The closure that will be run in a synchronized way
*/
private func synchronized(lock: AnyObject, closure: @autoclosure () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

@objc public protocol NetworkActivityIndicatorOwner {
    var networkActivityIndicatorVisible: Bool { get set }
}

extension UIApplication : NetworkActivityIndicatorOwner {}

/**
   Manages manages the state of the network activity indicator in the status bar.
   Based on AFNetworkActivityIndicatorManager from AFNetworking.
*/
public class Manager {
    private var _activityCount: Int = 0
   
    private var activityCount: Int {
        get {
            return self._activityCount
        }
        set {
            synchronized(self, self._activityCount = newValue)
            dispatch_async(dispatch_get_main_queue()) {
                self.updateNetworkActivityIndicatorVisibility()
            }
        }
    }
    
    private var activityIndicatorVisibilityTimer: NSTimer?
    private let invisibilityDelay: NSTimeInterval = 0.17
    
    public let application: NetworkActivityIndicatorOwner
    
    /// Indicates whether the network activity indicator is visible.
    public var networkActivityIndicatorVisible: Bool {
        return activityCount > 0
    }
    
    public init(application: NetworkActivityIndicatorOwner = UIApplication.sharedApplication()){
        self.application = application
    }
    
    /// The singleton instance.
    public class var sharedInstance: Manager {
        struct Singleton {
            static let instance = Manager()
        }
        
        return Singleton.instance
    }
    
    /**
        Increments the number of active network requests. If this number was zero before incrementing, this will start animating the status bar network activity indicator.
    */
    public func incrementActivityCount() {
        synchronized(self, self._activityCount += 1)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.updateNetworkActivityIndicatorVisibilityDelayed()
        }
    }
    
    /**
        Decrements the number of active network requests. If this number becomes zero after decrementing, this will stop animating the status bar network activity indicator.
    */
    public func decrementActivityCount() {
        synchronized(self, self._activityCount = max(self._activityCount - 1, 0))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.updateNetworkActivityIndicatorVisibilityDelayed()
        }
    }
    
    // MARK: Private
    
    @objc private func updateNetworkActivityIndicatorVisibility() {
        application.networkActivityIndicatorVisible = networkActivityIndicatorVisible
    }
    
    private func updateNetworkActivityIndicatorVisibilityDelayed() {
        if !networkActivityIndicatorVisible {
            activityIndicatorVisibilityTimer?.invalidate()
            activityIndicatorVisibilityTimer = NSTimer(timeInterval: invisibilityDelay,
                target: self, selector: "updateNetworkActivityIndicatorVisibility", userInfo: nil, repeats: false)
            NSRunLoop.mainRunLoop().addTimer(activityIndicatorVisibilityTimer!, forMode: NSRunLoopCommonModes)
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.updateNetworkActivityIndicatorVisibility()
            }
        }
    }
}