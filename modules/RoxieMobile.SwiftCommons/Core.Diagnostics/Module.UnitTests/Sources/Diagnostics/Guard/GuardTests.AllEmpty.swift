// ----------------------------------------------------------------------------
//
//  GuardTests.AllEmpty.swift
//
//  @author     Alexander Bragin <bragin-av@roxiemobile.com>
//  @copyright  Copyright (c) 2017, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

@testable import SwiftCommons
import XCTest

// ----------------------------------------------------------------------------

extension GuardTests
{
// MARK: - Tests

    func testAllEmpty_Array() {
        let method = "Guard.allEmpty"

//        let value = "value"
//        let emptyValue = ""
//
//        let array: [String]? = [emptyValue]
//        let nilArray: [String]? = nil
//        let emptyArray = [String]()
//
//
//        guardThrowsException("\(method)_Array") {
//            Guard.allEmpty([value])
//        }
//        guardThrowsException("\(method)_Array") {
//            Guard.allEmpty([emptyValue, value])
//        }
//
//        guardNotThrowsException("\(method)_Array") {
//            Guard.allEmpty(array)
//        }
//        guardNotThrowsException("\(method)_Array") {
//            Guard.allEmpty(nilArray)
//        }
//        guardNotThrowsException("\(method)_Array") {
//            Guard.allEmpty(emptyArray)
//        }

        XCTFail(method)
    }

    func testAllEmpty_ArrayOfOptionals() {
        let method = "Guard.allEmpty"

//        let value: String? = "value"
//        let nilValue: String? = nil
//        let emptyValue: String? = ""
//
//        let array: [String?]? = [nilValue, emptyValue]
//        let nilArray: [String?]? = nil
//        let emptyArray = [String?]()
//
//
//        guardThrowsException("\(method)_ArrayOfOptionals") {
//            Guard.allEmpty([value])
//        }
//        guardThrowsException("\(method)_ArrayOfOptionals") {
//            Guard.allEmpty([nilValue, value])
//        }
//        guardThrowsException("\(method)_ArrayOfOptionals") {
//            Guard.allEmpty([emptyValue, value])
//        }
//
//        guardNotThrowsException("\(method)_ArrayOfOptionals") {
//            Guard.allEmpty(array)
//        }
//        guardNotThrowsException("\(method)_ArrayOfOptionals") {
//            Guard.allEmpty(nilArray)
//        }
//        guardNotThrowsException("\(method)_ArrayOfOptionals") {
//            Guard.allEmpty(emptyArray)
//        }

        XCTFail(method)
    }
}

// ----------------------------------------------------------------------------
