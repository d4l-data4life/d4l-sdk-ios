//  Copyright (c) 2021 D4L data4life gGmbH
//  All rights reserved.
//  
//  D4L owns all legal rights, title and interest in and to the Software Development Kit ("SDK"),
//  including any intellectual property rights that subsist in the SDK.
//  
//  The SDK and its documentation may be accessed and used for viewing/review purposes only.
//  Any usage of the SDK for other purposes, including usage for the development of
//  applications/third-party applications shall require the conclusion of a license agreement
//  between you and D4L.
//  
//  If you are interested in licensing the SDK for your own applications/third-party
//  applications and/or if you’d like to contribute to the development of the SDK, please
//  contact D4L by email to help@data4life.care.

@testable import Data4LifeSDK
import XCTest

class DIContainerTests: XCTestCase {

    var container: DIContainer!

    override func setUp() {
        super.setUp()
        self.container = DIContainer()
    }

    override func tearDown() {
        super.tearDown()
        container.cleanGlobalInstances()
    }

    func testFailedResolveForStruct() throws {
        let testString: String? = try? container.resolve()
        XCTAssertEqual(testString, nil, "There should be No string registered and found")
    }

    func testFailedResolveAsForStruct() throws {
        let testString: String? = try? container.resolve(as: String.self)
        XCTAssertEqual(testString, nil, "There should be No string registered and found")
    }

    func testSuccessfulNonOptionalRegistrationOptionalResolveForStruct() throws {

        container.register(scope: .transientInstance) { (_) -> String in
            return "test"
        }

        let testString: String? = try? container.resolve()
        XCTAssertEqual(testString, "test", "There should be a String registered")
    }

    func testSuccessfulOptionalRegistrationOptionalResolveForStruct() throws {

        container.register(scope: .transientInstance) { (_) -> String? in
            return "test"
        }

        let testString: String? = try? container.resolve(as: String.self)
        XCTAssertEqual(testString, "test", "There should be a String registered")
    }

    func testSuccessfulNonOptionalRegistrationNonOptionalResolveForStruct() throws {

        container.register(scope: .transientInstance) { (_) -> String in
            return "test"
        }

        let testString: String = try container.resolve()
        XCTAssertEqual(testString, "test", "There should be a String registered")
    }

    func testSuccessfulOptionalRegistrationNonOptionalResolveForStruct() throws {

        container.register(scope: .transientInstance) { (_) -> String? in
            return "test"
        }

        let testString: String = try container.resolve()
        XCTAssertEqual(testString, "test", "There should be a String registered")
    }

    func testSuccessfulContainerResolveAsForStruct() throws {

        container.register(scope: .transientInstance) { (_) -> String in
            return "test"
        }

        let testString: String? = try? container.resolve(as: String.self)
        XCTAssertEqual(testString, "test", "String should be registered and found")
    }

    func testSuccessfulContainerResolveAsForProtocolConformation() throws {

        container.register(scope: .transientInstance) { (_) -> String in
            return "test"
        }

        let testString: CustomStringConvertible? = try? container.resolve(as: String.self)
        XCTAssertEqual(testString?.description, "test", "String should be registered and found")
    }

    func testSuccessfulContainerResolveAsForClass() throws {

        container.register(scope: .transientInstance) { (_) -> NSObject in
            return NSObject()
        }

        let testObject: NSObject? = try? container.resolve(as: NSObject.self)
        XCTAssertEqual(testObject != nil, true, "Object should be registered and found")
    }

    func testSuccessfulContainerResolveAsForSubclass() throws {

        container.register(scope: .transientInstance) { (_) -> NSNumber in
            return NSNumber(value: 5)
        }

        let testObject: NSObject? = try? container.resolve(as: NSNumber.self)
        XCTAssertEqual(testObject != nil, true, "Object should be registered and found")
    }

    func testSuccesfulAlwaysNewInstanceScopeForClass() throws {

        container.register(scope: .transientInstance) { (_) -> NSObject in
            return NSObject()
        }

        let secondContainer = DIContainer()
        secondContainer.register(scope: .transientInstance) { (_) -> NSObject in
            return NSObject()
        }

        let firstObject: NSObject = try container.resolve()
        let secondObject: NSObject = try container.resolve()
        let thirdObject: NSObject = try secondContainer.resolve()
        XCTAssertEqual(firstObject == secondObject, false, "The two should be different objects because of the alwaysNewInstance scope")
        XCTAssertEqual(secondObject == thirdObject, false, "The two should be different objects because of the alwaysNewInstance scope")
        XCTAssertEqual(firstObject == thirdObject, false, "The two should be different objects because of the alwaysNewInstance scope")
    }

    func testSuccesfulContainerScopeForClass() throws {

        container.register(scope: .containerInstance) { (_) -> NSObject in
            return NSObject()
        }

        let secondContainer = DIContainer()
        secondContainer.register(scope: .containerInstance) { (_) -> NSObject in
            return NSObject()
        }

        let firstObject: NSObject = try container.resolve()
        let secondObject: NSObject = try container.resolve()
        let thirdObject: NSObject = try secondContainer.resolve()
        XCTAssertEqual(firstObject == secondObject, true, "The two should be same objects because of the container scope")
        XCTAssertEqual(secondObject == thirdObject, false, "The two should be different objects because of the container scope")
        XCTAssertEqual(firstObject == thirdObject, false, "The two should be difference objects because of the container scope")
    }

    func testSuccesfulGlobalScopeForClass() throws {

        container.register(scope: .globalInstance) { (_) -> NSObject in
            return NSObject()
        }

        let secondContainer = DIContainer()
        secondContainer.register(scope: .globalInstance) { (_) -> NSObject in
            return NSObject()
        }

        let firstObject: NSObject = try container.resolve()
        let secondObject: NSObject = try container.resolve()
        let thirdObject: NSObject = try secondContainer.resolve()
        XCTAssertEqual(firstObject == secondObject, true, "The two should be same objects because of the global scope")
        XCTAssertEqual(firstObject == thirdObject, true, "The two should be same objects because of the global scope")
        XCTAssertEqual(secondObject == thirdObject, true, "The two should be same objects because of the global scope")
    }
}
