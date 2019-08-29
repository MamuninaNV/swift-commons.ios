// ----------------------------------------------------------------------------
//
//  STCCharacter.swift
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

    func testCharacter() {
        
        let _cValue: [String: Character]? = [JsonKeys.value: Constants.characterValue]

        // Positive
        assertNoThrow {
            // Encode
            let data = NSMutableData()
            StreamTypedEncoder(forWritingWith: data).encodeRootObject(_cValue)
            XCTAssertNotEqual(data, NSMutableData())

            // Decode
            var _cResult: [String: Character]?
            if let value = StreamTypedDecoder(forReadingWith: data as Data)?.decodeObject() as? [String: Character] {
                _cResult = value
            }
            XCTAssertEqual(_cValue, _cResult)
        }
    }
}

// ----------------------------------------------------------------------------