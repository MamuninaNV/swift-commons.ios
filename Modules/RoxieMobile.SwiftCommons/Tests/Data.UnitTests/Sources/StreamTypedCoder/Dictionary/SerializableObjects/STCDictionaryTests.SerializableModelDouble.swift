// ----------------------------------------------------------------------------
//
//  STCDouble.swift
//
//  @author     Natalia Mamunina <mamunina-nv@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.ru/
//
// ----------------------------------------------------------------------------

@testable import SwiftCommonsObjC
import XCTest

// ----------------------------------------------------------------------------

extension STCDictionaryTests
{
// MARK: - Tests

    func testSerializableModel_Double() {

        let _dObject: [String: STCDoubleModel]? = [JsonKeys.object: STCDoubleModel.shared]

        // Positive
        assertNoThrow {
            // Encode
            let data = NSMutableData()
            StreamTypedEncoder(forWritingWith: data).encodeRootObject(_dObject)
            XCTAssertNotEqual(data, NSMutableData())

            // Decode
            var _dResult: [String: STCDoubleModel]?
            if let value = StreamTypedDecoder(forReadingWith: data as Data)?.decodeObject() as? [String: STCDoubleModel] {
                _dResult = value
            }
            XCTAssertEqual(_dObject, _dResult)
        }
    }
}

// ----------------------------------------------------------------------------