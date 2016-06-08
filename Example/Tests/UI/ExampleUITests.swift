//
//  ExampleUITests.swift
//  
//
//  Created by Apegroup on 15/12/15.
//  Copyright ? 2015 Apegroup. All rights reserved.
//

import XCTest

class ExampleUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // In UI tests it?s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        XCUIDevice.sharedDevice().orientation = .Portrait;
    }
    
    func testExampleTakeScreenshots() {
        snapshot("FirstScreen")
        XCUIApplication().tabBars.buttons["Second"].tap()
        snapshot("SecondScreen")
                
        XCTAssertTrue(true, "This test will always succeed")
    }
    
}
