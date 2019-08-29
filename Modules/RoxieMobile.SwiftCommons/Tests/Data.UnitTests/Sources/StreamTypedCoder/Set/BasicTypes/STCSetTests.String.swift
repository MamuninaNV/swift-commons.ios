// ----------------------------------------------------------------------------
//
//  STCString.swift
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

    func testString() {

        let _sValue: Set<String> = [Constants.stringValue]

        // Positive
        assertNoThrow { [weak self] in
            // Encode
            let data = NSMutableData()
            StreamTypedEncoder(forWritingWith: data).encodeRootObject(_sValue)
            XCTAssertNotEqual(data, NSMutableData())

            // Decode
            var _sResult = Set<String>()
            if let value = StreamTypedDecoder(forReadingWith: data as Data)?.decodeObject() as? NSSet {
                self?.transform(set: &_sResult, from: value)
            }
            XCTAssertEqual(_sValue, _sResult)
        }
    }
}

// ----------------------------------------------------------------------------