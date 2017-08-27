//
//  Utility.swift
//  TabNavigations/ImagePicker
//
//  Created by devedbox on 2017/8/25.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import Accelerate
import AVFoundation

public extension UIEdgeInsets {
    /// A value indicate the horizontal length of the edge insets.
    ///
    /// - Returns: `.left` + `.right`.
    public var width: CGFloat { return left + right }
    /// A value indicate the vertical length of the edge insets.
    ///
    /// - Returns: `.top` + `.bottom`.
    public var height: CGFloat { return top + bottom }
    /// Initialize a new `UIEdgeInsets` instance with horizontal length.
    /// The values of `.left` and `.right` will both be `width * 0.5`.
    ///
    /// - Parameter width: The hotizontal length of the edge insets.
    /// - Returns: A new instance of `UIEdgeInsets` both `.left` and `.right` are width * 0.5.
    public init(width : CGFloat) { self.init(top: 0.0, left: width * 0.5, bottom: 0.0, right: width * 0.5) }
    /// Initialize a new `UIEdgeInsets` instance with vertical length.
    /// The values of `.top` and `.bottom` will both be `width * 0.5`.
    ///
    /// - Parameter height: The vertical length of the edge insets.
    /// - Returns: A new instance of `UIEdgeInsets` both `.top` and `.bottom` are height * 0.5.
    public init(height: CGFloat) { self.init(top: height * 0.5, left: 0.0, bottom: height * 0.5, right: 0.0) }
    /// Initialize a new `UIEdgeInsets` instance with left length.
    ///
    /// - Parameter left: The left length of the edge insets.
    /// - Returns: A new instance of `UIEdgeInsets` with only left length.
    public init(left  : CGFloat) { self.init(top: 0.0, left: left, bottom: 0.0, right: 0.0) }
    /// Initialize a new `UIEdgeInsets` instance with right length.
    ///
    /// - Parameter right: The right length of the edge insets.
    /// - Returns: A new instance of `UIEdgeInsets` with only right length.
    public init(right : CGFloat) { self.init(top: 0.0, left: 0.0, bottom: 0.0, right: right) }
    /// Initialize a new `UIEdgeInsets` instance with top length.
    ///
    /// - Parameter top: The top length of the edge insets.
    /// - Returns: A new instance of `UIEdgeInsets` with only top length.
    public init(top   : CGFloat) { self.init(top: top, left: 0.0, bottom: 0.0, right: 0.0) }
    /// Initialize a new `UIEdgeInsets` instance with bottom length.
    ///
    /// - Parameter bottom: The bottom length of the edge insets.
    /// - Returns: A new instance of `UIEdgeInsets` with only bottom length.
    public init(bottom: CGFloat) { self.init(top: 0.0, left: 0.0, bottom: bottom, right: 0.0) }
}

internal extension UIView {
    /// Remove the specified constraint from the receiver if the constraint is not nil.
    /// And do nothing if the constraint is nil.
    ///
    /// - Parameter constraint: The target constraint to be removed if any.
    ///
    func removeConstraintIfNotNil(_ constraint: NSLayoutConstraint?) { if let const_ = constraint { removeConstraint(const_) } }
}

public extension UIImage {
    /// Get the light-blured image from the original image. Nil if blur failed.
    public var lightBlur: UIImage? { return _blur(radius: 40.0, tintColor: UIColor(white: 1.0, alpha: 0.3), saturationDeltaFactor: 1.8, mask: nil) }
    /// Get the extra-light-blured image from the original image. Nil if blur failed.
    public var extraLightBlur: UIImage? { return _blur(radius: 40.0, tintColor: UIColor(white: 0.97, alpha: 0.82), saturationDeltaFactor: 1.8, mask: nil) }
    /// Get the dark-blured image from the original image. Nil if blur failed.
    public var darkBlur: UIImage? { return _blur(radius: 40.0, tintColor: UIColor(white: 0.11, alpha: 0.73), saturationDeltaFactor: 1.8, mask: nil) }
    /// Blur the receive image to an image with the tint color as "mask".
    ///
    /// - Parameter tintColor: The color used to be the "mask".
    /// - Returns: A color-blured image or nil if blur failed.
    public func blur(tint tintColor: UIColor) -> UIImage? { return _blur(radius: 20.0, tintColor: tintColor.withAlphaComponent(0.6), saturationDeltaFactor: -1.0, mask: nil) }
    /// Blur the receive image to an image with blur radius.
    ///
    /// - Parameter radius: The radius used to blur.
    /// - Returns: A blured image or nil if blur failed.
    public func blur(radius: CGFloat) -> UIImage? { return _blur(radius: radius, tintColor: nil, saturationDeltaFactor: -1.0, mask: nil) }
    /// Create a blured image from the original with parameters.
    ///
    /// - Parameter radius: The blur radius.
    /// - Parameter tintColor: The color used as "mask".
    /// - Parameter saturationDeltaFactor: A value for factor of saturation.
    /// - Parameter mask: The mask image used to mask the blured image.
    ///
    /// - Returns: A blured image from the params or nil if blur failed.
    private func _blur(radius: CGFloat, tintColor: UIColor?, saturationDeltaFactor: CGFloat, mask: UIImage?) -> UIImage? {
        // Check pre-conditions.
        guard size.width >= 1.0 && size.height >= 1.0 else { return nil }
        guard let input = cgImage else { return nil }
        if let _ = mask { guard let _ = mask?.cgImage else { return nil } }
        
        let hasBlur = radius > .ulpOfOne
        let hasSaturationChange = fabs(saturationDeltaFactor - 1.0) > .ulpOfOne
        
        let inputScale = scale
        let inputBitmapInfo = input.bitmapInfo
        let inputAlphaInfo = CGImageAlphaInfo(rawValue: inputBitmapInfo.intersection([.alphaInfoMask]).rawValue)
        
        let outputSizeInPoints = size
        let outputRectInPoints = CGRect(origin: .zero, size: outputSizeInPoints)
        
        // Set up output context.
        var useOpaqueContext: Bool
        if inputAlphaInfo == .none || inputAlphaInfo == .noneSkipLast || inputAlphaInfo == .noneSkipFirst {
            useOpaqueContext = true
        } else {
            useOpaqueContext = false
        }
        UIGraphicsBeginImageContextWithOptions(outputSizeInPoints, useOpaqueContext, inputScale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -outputSizeInPoints.height)
        
        if hasBlur || hasSaturationChange {
            var effectInBuffer: vImage_Buffer = vImage_Buffer()
            var scratchBuffer1: vImage_Buffer = vImage_Buffer()
            var inputBuffer: vImage_Buffer
            var outputBuffer: vImage_Buffer
            
            var format = vImage_CGImageFormat(
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                colorSpace: nil,
                // (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little)
                // requests a BGRA buffer.
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
                version: 0,
                decode: nil,
                renderingIntent: .defaultIntent)
            
            let e = vImageBuffer_InitWithCGImage(&effectInBuffer, &format, nil, input, vImage_Flags(kvImagePrintDiagnosticsToConsole))
            if e != kvImageNoError {
                UIGraphicsEndImageContext()
                return nil
            }
            
            vImageBuffer_Init(&scratchBuffer1, effectInBuffer.height, effectInBuffer.width, format.bitsPerPixel, vImage_Flags(kvImageNoFlags))
            
            inputBuffer = effectInBuffer
            outputBuffer = scratchBuffer1
            
            if hasBlur {
                // A description of how to compute the box kernel width from the Gaussian
                // radius (aka standard deviation) appears in the SVG spec:
                // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
                //
                // For larger values of 's' (s >= 2.0), an approximation can be used: Three
                // successive box-blurs build a piece-wise quadratic convolution kernel, which
                // approximates the Gaussian kernel to within roughly 3%.
                //
                // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
                //
                // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
                //
                var inputRadius = radius * inputScale
                if inputRadius - 2.0 < .ulpOfOne { inputRadius = 2.0 }
                let _tmpRadius = floor((Double(inputRadius) * 3.0 * sqrt(Double.pi * 2.0) / 4.0 + 0.5) / 2.0)
                let _radius = UInt32(_tmpRadius) | 1 // force radius to be odd so that the three box-blur methodology works.
                
                let tempBufferSize = vImageBoxConvolve_ARGB8888(&inputBuffer, &outputBuffer, nil, 0, 0, _radius, _radius, nil, vImage_Flags(kvImageGetTempBufferSize | kvImageEdgeExtend))
                
                let tempBuffer = malloc(tempBufferSize)
                defer { free(tempBuffer) }
                
                vImageBoxConvolve_ARGB8888(&inputBuffer, &outputBuffer, tempBuffer, 0, 0, _radius, _radius, nil, vImage_Flags(kvImageEdgeExtend))
                vImageBoxConvolve_ARGB8888(&outputBuffer, &inputBuffer, tempBuffer, 0, 0, _radius, _radius, nil, vImage_Flags(kvImageEdgeExtend))
                vImageBoxConvolve_ARGB8888(&inputBuffer, &outputBuffer, tempBuffer, 0, 0, _radius, _radius, nil, vImage_Flags(kvImageEdgeExtend))
                
                let tmpBuffer = inputBuffer
                inputBuffer = outputBuffer
                outputBuffer = tmpBuffer
            }
            
            if hasSaturationChange {
                let s = saturationDeltaFactor
                // These values appear in the W3C Filter Effects spec:
                // https://dvcs.w3.org/hg/FXTF/raw-file/default/filters/index.html#grayscaleEquivalent
                //
                let floatingPointSaturationMatrix: [CGFloat] = [
                    0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0.0,
                    0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0.0,
                    0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0.0,
                    0.0,                  0.0,                  0.0,                  1.0,
                    ]
                let divisor: Int32 = 256
                // let matrixSize = MemoryLayout.size(ofValue: floatingPointSaturationMatrix) / MemoryLayout.size(ofValue: floatingPointSaturationMatrix[0])
                // let matrixSize = floatingPointSaturationMatrix.count
                var saturationMatrix: [Int16] = []
                for /*i in 0 ..< matrixSize*/ floatingPointSaturation in floatingPointSaturationMatrix {
                    saturationMatrix.append(Int16(roundf(Float(/*floatingPointSaturationMatrix[i]*/floatingPointSaturation * CGFloat(divisor)))))
                }
                vImageMatrixMultiply_ARGB8888(&inputBuffer, &outputBuffer, saturationMatrix, divisor, nil, nil, vImage_Flags(kvImageNoFlags))
                
                let tmpBuffer = inputBuffer
                inputBuffer = outputBuffer
                outputBuffer = tmpBuffer
            }
            
            func cleanupBuffer(userData: UnsafeMutableRawPointer?, buf_data: UnsafeMutableRawPointer?) {
                if let buffer = buf_data { free(buffer) }
            }
            var effectCGImage = vImageCreateCGImageFromBuffer(&inputBuffer, &format, cleanupBuffer, nil, vImage_Flags(kvImageNoAllocate), nil)
            if effectCGImage == nil {
                effectCGImage = vImageCreateCGImageFromBuffer(&inputBuffer, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil)
                free(inputBuffer.data)
            }
            
            if mask != nil {
                // Only need to draw the base image if the effect image will be masked.
                context.__draw(in: outputRectInPoints, image: input)
            }
            // draw effect image
            context.saveGState()
            if let maskCGImage = mask?.cgImage {
                context.clip(to: outputRectInPoints, mask: maskCGImage)
            }
            if let _cgImage = effectCGImage?.takeUnretainedValue() {
                context.__draw(in: outputRectInPoints, image: _cgImage)
            }
            context.restoreGState()
            
            // Cleanup
            // CGImageRelease(effectCGImage as! CGImage)
            effectCGImage?.release()
            free(outputBuffer.data)
        } else {
            // draw base image
            context.__draw(in: outputRectInPoints, image: input)
        }
        
        // Add in color tint.
        if tintColor != nil {
            context.saveGState()
            context.setFillColor(tintColor!.cgColor)
            context.fill(outputRectInPoints)
            context.restoreGState()
        }
        // Output image is ready.
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

extension UIImage {
    /// Create an image from the core media sample buffer by applying a affine transform.
    ///
    /// - Parameter sampleBuffer: The buffer data representing the original basal image data.
    /// - Parameter applying: The closure to apply affine transform.
    ///
    /// - Returns: An image instance from the sample buffer.
    public class func image(from sampleBuffer: CMSampleBuffer, applying: ((CGSize) -> CGAffineTransform)? = nil) -> UIImage? {
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        // Get the number of bytes per row for the pixel buffer
        guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else { return nil }
        
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Create a bitmap graphics context with the sample buffer data
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else { return nil }
        // Create a Quartz image from the pixel data in the bitmap graphics context
        guard let _originalImage = context.makeImage() else { return nil }
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        guard let rotateCtx = CGContext(data: nil, width: height, height: width, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {return nil }
        if let transform = applying?(CGSize(width: width, height: height)) {
            rotateCtx.concatenate(transform)
        } else {
            rotateCtx.translateBy(x: 0.0, y: CGFloat(width))
            rotateCtx.rotate(by: -CGFloat.pi * 0.5)
        }
        rotateCtx.draw(_originalImage, in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        guard let _image = rotateCtx.makeImage() else { return nil }
        
        // Free up the context and color space
        // CGContextRelease(context);
        // CGColorSpaceRelease(colorSpace);
        
        // Create an image object from the Quartz image
        let image = UIImage(cgImage: _image, scale: UIScreen.main.scale, orientation: .up)
        return image
    }
}
