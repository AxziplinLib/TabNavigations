//
//  Errors.swift
//  AxReminder
//
//  Created by devedbox on 2017/8/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

/// An error type descriping the errors occured in the CaptureVideoPreviewView type.
public enum CaptureVideoPreviewViewError: Error {
    /// An error type descriping the errors occured in the Configuragion modules.
    public enum ConfiguragionError: Error {
        /// Indicates no available camera devices found during the video capture session's configuration.
        case noneOfAvailableDevices
        /// Indicates the input cannot be added to the video capture session.
        case sessionCannotAddInput
    }
    /// Indicates the errors occured during session's configuration.
    case configuration(ConfiguragionError)
}
