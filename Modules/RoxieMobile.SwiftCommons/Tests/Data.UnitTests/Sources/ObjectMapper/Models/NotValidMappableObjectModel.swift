// ----------------------------------------------------------------------------
//
//  NotValidMappableObjectModel.swift
//
//  @author     Natalia Mamunina <MamuninaNV@ekassir.com>
//  @copyright  Copyright (c) 2018, Roxie Mobile Ltd. All rights reserved.
//  @link       http://www.roxiemobile.com/
//
// ----------------------------------------------------------------------------

import SwiftCommonsData

// ----------------------------------------------------------------------------

internal final class NotValidMappableObjectModel: Mappable
{
// MARK: - Construction

    init() {
        // Do nothing
    }

    required init?(map: Map) {
        // Required method of protocol Mappable
    }

// MARK: - Properties

    var date = Constants.invalidDateObject

// MARK: - Methods

    func mapping(map: Map) {
        self.date <~ map[JsonKeys.date]
    }
}

// ----------------------------------------------------------------------------
