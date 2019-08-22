// ----------------------------------------------------------------------------
//
//  STCBool.swift
//
//  @author     Natalia Mamunina <mamunina-nv@roxiemobile.com>
//  @copyright  Copyright (c) 2019, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.ru/
//
// ----------------------------------------------------------------------------

@testable import SwiftCommonsObjC
import XCTest

// ----------------------------------------------------------------------------

extension STCSetTests
{
// MARK: - Tests

    func testSerializableModel_Bool() {

        let _bObject: Set<STCBoolModel> = [STCBoolModel.shared]

        // Positive
        assertNoThrow {
            // Encode
            let data = NSMutableData()
            StreamTypedEncoder(forWritingWith: data).encodeRootObject(_bObject)
            XCTAssertNotEqual(data, NSMutableData())

            // Decode
            var _bResult: Set<STCBoolModel>?
            if let value = StreamTypedDecoder(forReadingWith: data as Data)?.decodeObject() as? Set<STCBoolModel> {
                _bResult = value
            }
            XCTAssertEqual(_bObject, (_bResult)!)
        }
    }
}

// ----------------------------------------------------------------------------
