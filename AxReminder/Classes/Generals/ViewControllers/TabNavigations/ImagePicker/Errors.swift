//
//  Errors.swift
//  AxReminder
//
//  Created by devedbox on 2017/8/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

public enum CaptureVideoPreviewViewError: Error {
    public enum ConfiguragionError: Error {
        case noneOfAvailableDevices
        case sessionCannotAddInput
    }
    case configuration(ConfiguragionError)
}
