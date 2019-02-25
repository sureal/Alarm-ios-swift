//
//  SchedulerTestCase.swift
//  Alarm-ios-swiftTests
//
//  Created by natsu1211 on 2018/01/18.
//  Copyright © 2018年 LongGames. All rights reserved.
//

import XCTest
@testable import Alarm_ios_swift

class SchedulerTestCase: XCTestCase {
    
    let scheduler = AlarmScheduler()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
