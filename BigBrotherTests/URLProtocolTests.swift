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
    
    fileprivate var swizzledMethods: [(Method, Method)] = []
    
    fileprivate func swizzleRegisterClass() {
        let method: Method = class_getClassMethod(object_getClass(Foundation.URLProtocol), #selector(Foundation.URLProtocol.registerClass(_:)))
        let swizzledMethod: Method = class_getClassMethod(object_getClass(Foundation.URLProtocol), #selector(Foundation.URLProtocol.bb_registerClass(_:)))
        
        method_exchangeImplementations(method, swizzledMethod)
        
        let tuple = (method, swizzledMethod)
        swizzledMethods.append(tuple)
    }
    
    fileprivate func swizzleUnregisterClass() {
        let method: Method = class_getClassMethod(object_getClass(Foundation.URLProtocol), #selector(Foundation.URLProtocol.unregisterClass(_:)))
        let swizzledMethod: Method = class_getClassMethod(object_getClass(Foundation.URLProtocol), #selector(Foundation.URLProtocol.bb_unregisterClass(_:)))
        
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
        
        Foundation.URLProtocol.unregisterClass(BigBrother.URLProtocol)
        Foundation.URLProtocol.registeredClasses = NSMutableArray()
        
        super.tearDown()
    }
    
    func testAddToSessionConfiguration() {
        let configuration = URLSessionConfiguration.default
        let previousNumberOfProtocols = configuration.protocolClasses?.count ?? 0
        
        BigBrother.addToSessionConfiguration(configuration)
        
        let numberOfProtocols = configuration.protocolClasses?.count ?? 0
        
        XCTAssertEqual(numberOfProtocols, previousNumberOfProtocols + 1)
        XCTAssertNotNil(configuration.protocolClasses)
        
        let protocols = configuration.protocolClasses!
        XCTAssertTrue(protocols.contains { $0 === BigBrother.URLProtocol.self } )
    }
    
    func testRemoveFromSessionConfiguration() {
        let configuration = URLSessionConfiguration.default
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
        let previousNumberOfProtocols = Foundation.URLProtocol.registeredClasses.count
        
        BigBrother.addToSharedSession()
        
        let numberOfProtocols = Foundation.URLProtocol.registeredClasses.count
        XCTAssertEqual(numberOfProtocols, previousNumberOfProtocols + 1)
        
        XCTAssertTrue((Foundation.URLProtocol.registeredClasses[0] as? BigBrother.URLProtocol.Type) === BigBrother.URLProtocol.self)
    }
    
    func testRemoveFromSharedSession() {
        BigBrother.addToSharedSession()
        
        let previousNumberOfProtocols = Foundation.URLProtocol.registeredClasses.count
        
        BigBrother.removeFromSharedSession()
        
        let numberOfProtocols = Foundation.URLProtocol.registeredClasses.count
        XCTAssertEqual(numberOfProtocols, previousNumberOfProtocols - 1)
        
        XCTAssertFalse(Foundation.URLProtocol.registeredClasses.contains { $0 === BigBrother.URLProtocol.self } )
    }
}

private var registeredClassesKey: UInt8 = 0

extension Foundation.URLProtocol {
    
    class var registeredClasses: NSMutableArray {
        get {
            return objc_getAssociatedObject(self, &registeredClassesKey) as? NSMutableArray ?? NSMutableArray()
        }
        
        set(newValue) {
            objc_setAssociatedObject(self, &registeredClassesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    class func bb_registerClass(_ protocolClass: AnyClass) -> Bool {
        registeredClasses.add(protocolClass)
        
        return bb_registerClass(protocolClass)
    }
    
    class func bb_unregisterClass(_ protocolClass: AnyClass) {
        registeredClasses.remove(protocolClass)
        
        bb_unregisterClass(protocolClass)
    }
}
