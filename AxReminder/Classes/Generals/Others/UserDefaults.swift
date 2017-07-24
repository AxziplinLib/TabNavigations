//
//  UserDefaults.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/24.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import Foundation

/// Get and set values of type of [String: CGFloat].
public struct UserDefaultsKey {
    public struct LastUserLocation {
        static public var key: String { return "_LastUserLocation" }
        static public var coordinateLatitudeKey: String { return "_LastUserLocationCoordinateLatitude" }
        static public var coordinateLongitudeKey: String { return "_LastUserLocationCoordinateLongitude" }
    }
}
