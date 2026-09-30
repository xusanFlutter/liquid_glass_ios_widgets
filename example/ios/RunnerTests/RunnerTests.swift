import Flutter
import UIKit
import XCTest

@testable import liquid_glass_ios_widgets

class RunnerTests: XCTestCase {

  func testIsLiquidGlassSupported() {
    let plugin = LiquidGlassIosWidgetsPlugin()
    let call = FlutterMethodCall(methodName: "isLiquidGlassSupported", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      let expected: Bool
      if #available(iOS 26.0, *) {
        expected = true
      } else {
        expected = false
      }
      XCTAssertEqual(result as? Bool, expected)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }
}
