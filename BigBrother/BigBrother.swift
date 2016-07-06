//
//  BigBrother.swift
//  BigBrother
//
//  Created by Marcelo Fabri on 01/01/15.
//  Copyright (c) 2015 Marcelo Fabri. All rights reserved.
//

import Foundation
import UIKit

/**
    Registers BigBrother to the shared NSURLSession (and to NSURLConnection).
*/
public func addToSharedSession() {
    NSURLProtocol.registerClass(BigBrother.URLProtocol.self)
}

/**
    Adds BigBrother to a NSURLSessionConfiguration that will be used to create a custom NSURLSession.

    - parameter configuration: The configuration on which BigBrother will be added
*/
public func addToSessionConfiguration(configuration: NSURLSessionConfiguration) {
    // needs to be inserted at the beginning (see https://github.com/AliSoftware/OHHTTPStubs/issues/65 )
    let arr: [AnyClass]
    if let classes = configuration.protocolClasses {
        arr = [BigBrother.URLProtocol.self] + classes
    } else {
        arr = [BigBrother.URLProtocol.self]
    }
    configuration.protocolClasses = arr
}

/**
    Removes BigBrother from the shared NSURLSession (and to NSURLConnection).
*/
public func removeFromSharedSession() {
    NSURLProtocol.unregisterClass(BigBrother.URLProtocol.self)
}

/**
    Removes BigBrother from a NSURLSessionConfiguration.
    You must create a new NSURLSession from the updated configuration to stop using BigBrother.

    - parameter configuration: The configuration from which BigBrother will be removed (if present)
*/
public func removeFromSessionConfiguration(configuration: NSURLSessionConfiguration) {
    configuration.protocolClasses = configuration.protocolClasses?.filter {  $0 !== BigBrother.URLProtocol.self }
}

/**
*  A custom NSURLProtocol that automatically manages UIApplication.sharedApplication().networkActivityIndicatorVisible.
*/
public class URLProtocol: NSURLProtocol {
    
    var connection: NSURLConnection?
    var mutableData: NSMutableData?
    var response: NSURLResponse?
    
    /// The singleton instance.
    public static var manager = BigBrother.Manager.sharedInstance
    
    // MARK: NSURLProtocol
    
    override public class func canInitWithRequest(request: NSURLRequest) -> Bool {
        if NSURLProtocol.propertyForKey(NSStringFromClass(self), inRequest: request) != nil {
            return false
        }
        
        return true
    }
    
    override public class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override public class func requestIsCacheEquivalent(aRequest: NSURLRequest, toRequest bRequest: NSURLRequest) -> Bool {
        return super.requestIsCacheEquivalent(aRequest, toRequest:bRequest)
    }
    
    override public func startLoading() {
        URLProtocol.manager.incrementActivityCount()
        
        let newRequest = request.mutableCopy() as! NSMutableURLRequest
        NSURLProtocol.setProperty(true, forKey: NSStringFromClass(self.dynamicType), inRequest: newRequest)
        connection = NSURLConnection(request: newRequest, delegate: self)
    }
    
    override public func stopLoading() {
        connection?.cancel()
        connection = nil
        
        URLProtocol.manager.decrementActivityCount()
    }
    
    // MARK: NSURLConnectionDelegate
    
    public func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        let policy = NSURLCacheStoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .NotAllowed
        client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: policy)
        
        self.response = response
        mutableData = NSMutableData()
    }
    
    public func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        client?.URLProtocol(self, didLoadData: data)
        mutableData?.appendData(data)
    }
    
    public func connectionDidFinishLoading(connection: NSURLConnection!) {
        client?.URLProtocolDidFinishLoading(self)
    }
    
    public func connection(connection: NSURLConnection!, didFailWithError error: NSError!) {
        client?.URLProtocol(self, didFailWithError: error)
    }
}
