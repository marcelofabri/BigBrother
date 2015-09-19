//
//  URLProtocolTests.swift
//  BigBrotherTests
//
//  Created by Marcelo Fabri on 01/01/15.
//  Copyright (c) 2015 Marcelo Fabri. All rights reserved.
//

import UIKit
import XCTest
import BigBrother
import ObjectiveC

class URLProtocolTests: XCTestCase {
    
    private var swizzledMethods: [(Method, Method)] = []
    
    private func swizzleRegisterClass() {
        let method: Method = class_getClassMethod(object_getClass(NSURLProtocol), "registerClass:")
        let swizzledMethod: Method = class_getClassMethod(object_getClass(NSURLProtocol), "bb_registerClass:")
        
        method_exchangeImplementations(method, swizzledMethod)
        
        let tuple = (method, swizzledMethod)
        swizzledMethods.append(tuple)
    }
    
    private func swizzleUnregisterClass() {
        let method: Method = class_getClassMethod(object_getClass(NSURLProtocol), "unregisterClass:")
        let swizzledMethod: Method = class_getClassMethod(object_getClass(NSURLProtocol), "bb_unregisterClass:")
        
        method_exchangeImplementations(method, swizzledMethod)
        
        let tuple = (method, swizzledMethod)
        swizzledMethods.append(tuple)
    }
    
    override func setUp() {
        super.setUp()
        
        swizzleRegisterClass()
        swizzleUnregisterClass()
    }
    
    override func tearDown() {
        for tuple in swizzledMethods {
            method_exchangeImplementations(tuple.0, tuple.1)
        }
        swizzledMethods = []
        
        NSURLProtocol.unregisterClass(BigBrother.URLProtocol)
        NSURLProtocol.registeredClasses = NSMutableArray()
        
        super.tearDown()
    }
    
    func testAddToSessionConfiguration() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let previousNumberOfProtocols = configuration.protocolClasses?.count ?? 0
        
        BigBrother.addToSessionConfiguration(configuration)
        
        let numberOfProtocols = configuration.protocolClasses?.count ?? 0
        
        XCTAssertEqual(numberOfProtocols, previousNumberOfProtocols + 1)
        XCTAssertNotNil(configuration.protocolClasses)
        
        let protocols = configuration.protocolClasses!
        XCTAssertTrue(protocols.contains { $0 === BigBrother.URLProtocol.self } )
    }
    
    func testRemoveFromSessionConfiguration() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        BigBrother.addToSessionConfiguration(configuration)
        let previousNumberOfProtocols = configuration.protocolClasses?.count ?? 0
        
        
        BigBrother.removeFromSessionConfiguration(configuration)
        
        let numberOfProtocols = configuration.protocolClasses?.count ?? 0
        
        XCTAssertEqual(numberOfProtocols, previousNumberOfProtocols - 1)
        XCTAssertNotNil(configuration.protocolClasses)
        
        let protocols = configuration.protocolClasses!
        XCTAssertFalse(protocols.contains { $0 === BigBrother.URLProtocol.self } )
    }
    
    func testAddToSharedSession() {
        let previousNumberOfProtocols = NSURLProtocol.registeredClasses.count
        
        BigBrother.addToSharedSession()
        
        let numberOfProtocols = NSURLProtocol.registeredClasses.count
        XCTAssertEqual(numberOfProtocols, previousNumberOfProtocols + 1)
        
        XCTAssertTrue(NSURLProtocol.registeredClasses.contains { $0 === BigBrother.URLProtocol.self } )
    }
    
    func testRemoveFromSharedSession() {
        BigBrother.addToSharedSession()
        
        let previousNumberOfProtocols = NSURLProtocol.registeredClasses.count
        
        BigBrother.removeFromSharedSession()
        
        let numberOfProtocols = NSURLProtocol.registeredClasses.count
        XCTAssertEqual(numberOfProtocols, previousNumberOfProtocols - 1)
        
        XCTAssertFalse(NSURLProtocol.registeredClasses.contains { $0 === BigBrother.URLProtocol.self } )
    }
}

private var registeredClassesKey: UInt8 = 0

extension NSURLProtocol {
    
    class var registeredClasses: NSMutableArray {
        get {
            return objc_getAssociatedObject(self, &registeredClassesKey) as? NSMutableArray ?? NSMutableArray()
        }
        
        set(newValue) {
            objc_setAssociatedObject(self, &registeredClassesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    class func bb_registerClass(protocolClass: AnyClass) -> Bool {
        registeredClasses.addObject(protocolClass)
        
        return bb_registerClass(protocolClass)
    }
    
    class func bb_unregisterClass(protocolClass: AnyClass) {
        registeredClasses.removeObject(protocolClass)
        
        bb_unregisterClass(protocolClass)
    }
}
