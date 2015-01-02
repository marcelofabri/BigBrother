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

class MockApplication: NetworkActivityIndicatorOwner {
    var networkActivityIndicatorVisible = false
}

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

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
}
