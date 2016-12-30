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
    
    func testThatNetworkActivityIndicationTurnsOffWithURL(_ URL: Foundation.URL) {
        let configuration = URLSessionConfiguration.default
        
        BigBrother.addToSessionConfiguration(configuration)
        
        let session = URLSession(configuration: configuration)
        
        let expectation = self.expectation(description: "GET \(URL)")
        
        let task = session.dataTask(with: URL, completionHandler: { _ in
            delay(0.2) {
                expectation.fulfill()
                XCTAssertFalse(self.mockApplication.networkActivityIndicatorVisible)
            }
        }) 
        
        task.resume()
        
        let invisibilityDelayExpectation = self.expectation(description: "TurnOnInvisibilityDelayExpectation")
        delay(0.2) {
            invisibilityDelayExpectation.fulfill()
            XCTAssertTrue(self.mockApplication.networkActivityIndicatorVisible)
        }
        
        waitForExpectations(timeout: task.originalRequest!.timeoutInterval + 1) { _ in
            task.cancel()
        }
    }

    func testThatNetworkActivityIndicatorTurnsOffIndicatorWhenRequestSucceeds() {
        let URL =  Foundation.URL(string: "http://httpbin.org/delay/1")!
        testThatNetworkActivityIndicationTurnsOffWithURL(URL)
    }
    
    func testThatNetworkActivityIndicatorTurnsOffIndicatorWhenRequestFails() {
        let URL =  Foundation.URL(string: "http://httpbin.org/status/500")!
        testThatNetworkActivityIndicationTurnsOffWithURL(URL)
    }
}

private class MockApplication: NetworkActivityIndicatorOwner {
    var networkActivityIndicatorVisible = false
}

private func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
