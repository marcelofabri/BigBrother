//
//  BigBrotherTests.swift
//  BigBrother
//
//  Created by Marcelo Fabri on 02/01/15.
//  Copyright (c) 2015 Marcelo Fabri. All rights reserved.
//

import UIKit
import XCTest
import BigBrother

class BigBrotherTests: XCTestCase {

    let mockApplication: NetworkActivityIndicatorOwner = MockApplication()
    
    override func setUp() {
        super.setUp()
        
        BigBrother.URLProtocol.manager = BigBrother.Manager(application: mockApplication)
    }
    
    override func tearDown() {
        BigBrother.URLProtocol.manager = BigBrother.Manager()
        
        super.tearDown()
    }
    
    func testThatNetworkActivityIndicationTurnsOffWithURL(URL: NSURL) {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        BigBrother.addToSessionConfiguration(configuration)
        
        let session = NSURLSession(configuration: configuration)
        
        let expectation = expectationWithDescription("GET \(URL)")
        
        let task = session.dataTaskWithURL(URL) { (data, response, error) in
            delay(0.2) {
                expectation.fulfill()
                XCTAssertFalse(self.mockApplication.networkActivityIndicatorVisible)
            }
        }
        
        task.resume()
        
        let invisibilityDelayExpectation = expectationWithDescription("TurnOnInvisibilityDelayExpectation")
        delay(0.2) {
            invisibilityDelayExpectation.fulfill()
            XCTAssertTrue(self.mockApplication.networkActivityIndicatorVisible)
        }
        
        waitForExpectationsWithTimeout(task.originalRequest.timeoutInterval + 1) { (error) in
            task.cancel()
        }
    }

    func testThatNetworkActivityIndicatorTurnsOffIndicatorWhenRequestSucceeds() {
        let URL =  NSURL(string: "http://httpbin.org/get")!
        testThatNetworkActivityIndicationTurnsOffWithURL(URL)
    }
    
    func testThatNetworkActivityIndicatorTurnsOffIndicatorWhenRequestFails() {
        let URL =  NSURL(string: "http://httpbin.org/status/500")!
        testThatNetworkActivityIndicationTurnsOffWithURL(URL)
    }
    
    func testThatNetworkActivityIndicationTurnsOffWithBasicAuthentication() {
        class AuthURLSessionDelegate: NSObject, NSURLSessionTaskDelegate {
            func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
                let credential = NSURLCredential(user: "u", password: "p", persistence: .ForSession)
                println("delegate")
                completionHandler(.UseCredential, credential)
            }
        }
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        BigBrother.addToSessionConfiguration(configuration)
        
        let delegate = AuthURLSessionDelegate()
        let session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: NSOperationQueue.mainQueue())
        
        let URL = NSURL(string: "http://httpbin.org/basic-auth/u/p")!
        let expectation = expectationWithDescription("GET \(URL)")
        
        let task = session.dataTaskWithURL(URL) { (data, response, error) in
            let httpResponse = response as NSHTTPURLResponse
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            delay(0.2) {
                expectation.fulfill()
                XCTAssertFalse(self.mockApplication.networkActivityIndicatorVisible)
            }
        }
        
        task.resume()
        
        let invisibilityDelayExpectation = expectationWithDescription("TurnOnInvisibilityDelayExpectation")
        delay(0.2) {
            invisibilityDelayExpectation.fulfill()
            XCTAssertTrue(self.mockApplication.networkActivityIndicatorVisible)
        }
        
        waitForExpectationsWithTimeout(task.originalRequest.timeoutInterval + 1) { (error) in
            task.cancel()
        }
    }
}

private class MockApplication: NetworkActivityIndicatorOwner {
    var networkActivityIndicatorVisible = false
}

private func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}
