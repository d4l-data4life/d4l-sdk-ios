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

import XCTest
@testable import Data4LifeSDK

fileprivate extension RecordServiceParameterBuilder.TagsParameter {
    static var stringInitialized: RecordServiceParameterBuilder.TagsParameter = RecordServiceParameterBuilder.TagsParameter("tag=value")
    static var keyValueInitialized: RecordServiceParameterBuilder.TagsParameter = RecordServiceParameterBuilder.TagsParameter(
        RecordServiceParameterBuilder.TagsParameter.OrComponent(key: "tag", value: "value", separator: "=")
    )
    static var doubleComponentInitialized: RecordServiceParameterBuilder.TagsParameter = RecordServiceParameterBuilder.TagsParameter(
        [RecordServiceParameterBuilder.TagsParameter.OrComponent(formattedTag: "tag=value"),
         RecordServiceParameterBuilder.TagsParameter.OrComponent(formattedTag: "tag2=value2")
        ]
    )
}

class TagsParameterTests: XCTestCase {
    func testConvenienceInitializers() throws {
        let parameter1 = RecordServiceParameterBuilder.TagsParameter.stringInitialized
        let parameter2 = RecordServiceParameterBuilder.TagsParameter.keyValueInitialized
        XCTAssertEqual(parameter1.orComponents.formattedTags, parameter2.orComponents.formattedTags)
        XCTAssertEqual(parameter1.tagExpression, parameter2.tagExpression)
    }

    func testParameterExpressions() throws {
        let parameter1 = RecordServiceParameterBuilder.TagsParameter.stringInitialized
        let parameter2 = RecordServiceParameterBuilder.TagsParameter.keyValueInitialized
        let parameter3 = RecordServiceParameterBuilder.TagsParameter.doubleComponentInitialized
        XCTAssertEqual(parameter1.tagExpression, "tag=value")
        XCTAssertEqual(parameter2.tagExpression, "tag=value")
        XCTAssertEqual(parameter3.tagExpression, "(tag=value,tag2=value2)")
    }
}
