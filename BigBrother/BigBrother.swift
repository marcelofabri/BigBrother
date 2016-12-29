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
    Foundation.URLProtocol.registerClass(BigBrother.URLProtocol.self)
}

/**
    Adds BigBrother to a NSURLSessionConfiguration that will be used to create a custom NSURLSession.

    - parameter configuration: The configuration on which BigBrother will be added
*/
public func addToSessionConfiguration(_ configuration: URLSessionConfiguration) {
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
    Foundation.URLProtocol.unregisterClass(BigBrother.URLProtocol.self)
}

/**
    Removes BigBrother from a NSURLSessionConfiguration.
    You must create a new NSURLSession from the updated configuration to stop using BigBrother.

    - parameter configuration: The configuration from which BigBrother will be removed (if present)
*/
public func removeFromSessionConfiguration(_ configuration: URLSessionConfiguration) {
    configuration.protocolClasses = configuration.protocolClasses?.filter {  $0 !== BigBrother.URLProtocol.self }
}

/**
*  A custom NSURLProtocol that automatically manages UIApplication.sharedApplication().networkActivityIndicatorVisible.
*/
open class URLProtocol: Foundation.URLProtocol {
    
    var connection: NSURLConnection?
    var mutableData: NSMutableData?
    var response: URLResponse?
    
    /// The singleton instance.
    open static var manager = BigBrother.Manager.sharedInstance
    
    // MARK: NSURLProtocol
    
    override open class func canInit(with request: URLRequest) -> Bool {
        if Foundation.URLProtocol.property(forKey: NSStringFromClass(self), in: request) != nil {
            return false
        }
        
        return true
    }
    
    override open class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override open class func requestIsCacheEquivalent(_ aRequest: URLRequest, to bRequest: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(aRequest, to:bRequest)
    }
    
    override open func startLoading() {
        URLProtocol.manager.incrementActivityCount()
        
        let newRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        Foundation.URLProtocol.setProperty(true, forKey: NSStringFromClass(type(of: self)), in: newRequest)
        connection = NSURLConnection(request: newRequest as URLRequest, delegate: self)
    }
    
    override open func stopLoading() {
        connection?.cancel()
        connection = nil
        
        URLProtocol.manager.decrementActivityCount()
    }
    
    // MARK: NSURLConnectionDelegate
    
    func connection(_ connection: NSURLConnection!, didReceiveResponse response: URLResponse!) {
        let policy = URLCache.StoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .notAllowed
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
        
        self.response = response
        mutableData = NSMutableData()
    }
    
    func connection(_ connection: NSURLConnection!, didReceiveData data: Data!) {
        client?.urlProtocol(self, didLoad: data)
        mutableData?.append(data)
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection!) {
        client?.urlProtocolDidFinishLoading(self)
    }
    
    func connection(_ connection: NSURLConnection!, didFailWithError error: NSError!) {
        client?.urlProtocol(self, didFailWithError: error)
    }
}
