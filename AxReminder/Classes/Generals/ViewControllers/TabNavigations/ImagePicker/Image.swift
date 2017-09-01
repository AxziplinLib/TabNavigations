//
//  Image.swift
//  AxReminder
//
//  Created by devedbox on 2017/8/31.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import ImageIO
import Accelerate
import CoreGraphics
import AVFoundation

// MARK: - General.

extension UIView {
    /// Creates and render a snapshot of the view hierarchy into the current context. Returns nil if the snapshot is missing image data, an image object if the snapshot is complete.
    public var contents: UIImage! {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, UIScreen.main.scale)
        if #available(iOS 7.0, *) {
            if !drawHierarchy(in: bounds, afterScreenUpdates: false) {
                guard let context = UIGraphicsGetCurrentContext() else { return nil }
                layer.render(in: context)
            }
        } else {
            guard let context = UIGraphicsGetCurrentContext() else { return nil }
            layer.render(in: context)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - Blur.

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

// MARK: - CMSampleBuffer.

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

// MARK: - Alpha.

extension UIImage {
    /// A boolean value indicates whether the image has alpha channel.
    public var hasAlpha: Bool {
        guard let alp = self.cgImage?.alphaInfo else { return false }
        let alp_ops: [CGImageAlphaInfo] = [.first, .last, .premultipliedFirst, .premultipliedLast]
        return alp_ops.contains(alp)
    }
    /// Returns a copied instance based on the receiver if the receiver image contains no any alpha channels.
    ///
    /// Nil will be returned if the new image context cannot be created or any other errors occured.
    public var alpha: UIImage! {
        guard !hasAlpha else { return self }
        guard let cgImage = self.cgImage, let colorSpace = cgImage.colorSpace else { return nil }
        // The bitsPerComponent and bitmapInfo values are hard-coded to prevent an "unsupported parameter combination" error
        guard let context = CGContext(data: nil, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: (CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo(rawValue: (0 << 12)).rawValue)) else { return nil }
        // Draw the image into the context and retrieve the new image, which will now have an alpha layer
        context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: cgImage.width, height: cgImage.height)))
        guard let alp_img = context.makeImage() else { return nil }
        return UIImage(cgImage: alp_img)
    }
    /// Creates a copy of the image with a transparent border of the given size added around its edges.
    ///
    /// If the image has no alpha layer, one will be added to it.
    ///
    /// - Parameter transparentBorderWidth: The arounded border size.
    /// - Returns: A copy of the image with a transparent border of the given size added around its edges.
    public func bordered(_ transparentBorderWidth: CGFloat) -> UIImage! {
        // If the image does not have an alpha layer, add one.
        guard let cgImage = self.alpha.cgImage, let colorSpace = cgImage.colorSpace else { return nil }
        let newRect = CGRect(origin: .zero, size: CGSize(width: size.width + transparentBorderWidth * 2.0, height: size.height + transparentBorderWidth * 2.0))
        // Build a context that's the same dimensions as the new size
        guard let context = CGContext(data: nil, width: Int(newRect.width), height: Int(newRect.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue) else { return nil }
        // Draw the image in the center of the context, leaving a gap around the edges
        let croppingRect = newRect.insetBy(dx: transparentBorderWidth, dy: transparentBorderWidth)
        context.draw(cgImage, in: croppingRect)
        guard let centeredImg = context.makeImage() else { return nil }
        // Create a mask to make the border transparent, and combine it with the image
        guard let mask = type(of: self)._borderedMask(newRect.size, borderWidth: transparentBorderWidth) else { return nil }
        
        guard let maskedCgImg = centeredImg.masking(mask) else { return nil }
        return UIImage(cgImage: maskedCgImg)
    }
    /// Creates a mask that makes the outer edges transparent and everything else opaque
    ///
    /// The size must include the entire mask (opaque part + transparent border)
    ///
    /// - Parameter size: The outter size of the mask image to drawing.
    /// - Parameter borderWidth: The border width of the transparent part.
    ///
    /// - Returns: An image with inner opaque part and transparent border.
    private class func _borderedMask(_ size: CGSize, borderWidth: CGFloat) -> CGImage! {
        // Early fatal checking.
        guard size.width > borderWidth && size.height > borderWidth && borderWidth >= 0.0 else { return nil }
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        // Build a context that's the same dimensions as the new size
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: (CGImageAlphaInfo.none.rawValue | CGBitmapInfo(rawValue: (0 << 12)).rawValue)) else { return nil }
        // Start with a mask that's entirely transparent
        let rect = CGRect(origin: .zero, size: size)
        context.setFillColor(UIColor.black.cgColor)
        context.fill(rect)
        // Make the inner part (within the border) opaque
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect.insetBy(dx: borderWidth, dy: borderWidth))
        // Get an image of the context
        guard let mask = context.makeImage() else { return nil }
        return mask
    }
}

// MARK: - RoundedCorner.

extension UIImage {
    /// Returns an copy of the receiver with critical rounding.
    public var cornered: UIImage! { return round(min(size.width, size.height) * 0.5, border: 0.0) }
    /// Creates a copy of this image with rounded corners
    ///
    /// If borderWidth is non-zero, a transparent border of the given size will also be added
    ///
    /// Original author: Björn Sållarp. Used with permission. See: [http://blog.sallarp.com/iphone-uiimage-round-corners/](http://blog.sallarp.com/iphone-uiimage-round-corners/)
    ///
    /// - Parameter cornerWidth: The width of the corner drawing. The value must not be negative.
    /// - Parameter borderWidth: The width of border drawing. The value must not be negative. The value is 0.0 by default.
    ///
    /// - Returns: An image with rounded corners.
    public func round(_ cornerRadius: CGFloat, border borderWidth: CGFloat = 0.0) -> UIImage! {
        // Early fatal checking.
        guard cornerRadius >= 0.0 && borderWidth >= 0.0 else { return nil }
        
        // If the image does not have an alpha layer, add one
        guard let cgImage = self.alpha.cgImage, let colorSpace = cgImage.colorSpace else { return nil }
        // Build a context that's the same dimensions as the new size
        guard let context = CGContext(data: nil, width: cgImage.width, height: cgImage.height, bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue) else { return nil }
        // Create a clipping path with rounded corners
        context.beginPath()
        let roundedRect = CGRect(x: borderWidth, y: borderWidth, width: size.width - borderWidth * 2.0, height: size.height - borderWidth * 2.0)
        if cornerRadius == 0 {
            context.addRect(roundedRect)
        } else {
            context.saveGState()
            context.translateBy(x: roundedRect.minX, y: roundedRect.minY)
            context.scaleBy(x: cornerRadius, y: cornerRadius)
            
            let wr = roundedRect.width  / cornerRadius
            let hr = roundedRect.height / cornerRadius
            
            context.move(to: CGPoint(x: wr, y: hr * 0.5))
            context.addArc(tangent1End: CGPoint(x: wr, y: hr), tangent2End: CGPoint(x: wr * 0.5, y: hr), radius: 1.0)
            context.addArc(tangent1End: CGPoint(x: 0.0, y: hr), tangent2End: CGPoint(x: 0.0, y: hr * 0.5), radius: 1.0)
            context.addArc(tangent1End: CGPoint(x: 0.0, y: 0.0), tangent2End: CGPoint(x: wr * 0.5, y: 0.0), radius: 1.0)
            context.addArc(tangent1End: CGPoint(x: wr, y: 0.0), tangent2End: CGPoint(x: wr, y: hr * 0.5), radius: 1.0)
            context.closePath()
            context.restoreGState()
        }
        context.closePath()
        context.clip()
        // Draw the image to the context; the clipping path will make anything outside the rounded rect transparent
        context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height)))
        // Create a CGImage from the context
        guard let clippedImage = context.makeImage() else { return nil }
        
        // Create a UIImage from the CGImage
        return UIImage(cgImage: clippedImage)
    }
}

// MARK: - Resizing.

extension UIImage {
    /// A type reprensting the calculating mode of the image's resizing.
    public enum ResizingMode: Int {
        case scaleToFill
        case scaleAspectFit // contents scaled to fit with fixed aspect. remainder is transparent
        case scaleAspectFill // contents scaled to fill with fixed aspect. some portion of content may be clipped.
        case center // contents remain same size. positioned adjusted.
        case top
        case bottom
        case left
        case right
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    /// Creates a copy of the receiver that is cropped to the given rectangle.
    ///
    /// The bounds will be adjusted using `CGRectIntegral`.
    ///
    /// This method ignores the image's imageOrientation setting.
    ///
    /// - Parameter rect: The rectangle area coordinates in the receiver. The value
    ///                   of the rectangle must not be zero or negative sizing.
    ///
    /// - Returns: An copy of the receiver cropped to the given rectangle.
    public func crop(to rect: CGRect) -> UIImage! {
        // Early fatal checking.
        guard rect.width > 0.0 && rect.height > 0.0 else { return nil }
        
        guard let cgImage = self.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    /// Creates a copy of the receiver that is cropped to the given size with a specific resizing mode.
    ///
    /// The size will be adjusted using `CGRectIntegral`.
    ///
    /// This method ignores the image's imageOrientation setting.
    ///
    /// - Parameter size: The size you want to crop the image. The values of
    ///                   the size must not be zero or negative.
    /// - Parameter mode: The resizing mode to decide the rectangle to crop.
    ///                   The value will use `.center` by default.
    ///
    /// - Returns: An copy of the receiver cropped to the given size and resizing mode.
    public func crop(fits size: CGSize, using mode: ResizingMode = .center) -> UIImage! {
        var croppingRect = CGRect(origin: .zero, size: size)
        switch mode {
        case .scaleToFill:
            return resize(fits: size, quality: .default)
        case .scaleAspectFill: fallthrough
        case .scaleAspectFit :
            return resize(fits: size, using: mode, quality: .default)
        case .center:
            croppingRect.origin.x = (self.size.width  - croppingRect.width)  * 0.5
            croppingRect.origin.y = (self.size.height - croppingRect.height) * 0.5
        case .top:
            croppingRect.origin.x = (self.size.width  - croppingRect.width)  * 0.5
        case .bottom:
            croppingRect.origin.x = (self.size.width  - croppingRect.width)  * 0.5
            croppingRect.origin.y =  self.size.height - croppingRect.height
        case .left:
            croppingRect.origin.y = (self.size.height - croppingRect.height) * 0.5
        case .right:
            croppingRect.origin.x =  self.size.width  - croppingRect.width
            croppingRect.origin.y = (self.size.height - croppingRect.height) * 0.5
        case .topLeft: break
        case .topRight:
            croppingRect.origin.x = self.size.width  - croppingRect.width
        case .bottomLeft:
            croppingRect.origin.y = self.size.height - croppingRect.height
        case .bottomRight:
            croppingRect.origin.x = self.size.width  - croppingRect.width
            croppingRect.origin.y = self.size.height - croppingRect.height
        }
        
        return crop(to: croppingRect)
    }
    /// Creates a copy of this image that is squared to the thumbnail size using `QuartzCore` redrawing.
    ///
    /// If borderWidth is non-zero, a transparent border of the given size will
    /// be added around the edges of the thumbnail. (Adding a transparent border
    /// of at least one pixel in size has the side-effect of antialiasing the
    /// edges of the image when rotating it using Core Animation.)
    ///
    /// - Parameter sizet       : A size of thumbnail to fit and square to.
    /// - Parameter borderWidth : A value indicates the width of the transparent border. Using 0.0 by default.
    /// - Parameter cornerRadius: A value indicates the radius of rounded corner. Using 0.0 by default.
    /// - Parameter quality     : An instance of `CGInterpolationQuality` indicates the
    ///                           interpolation of the receiver. Defaults to `.default.`
    ///
    /// - Returns: A copy of the receiver that is squared to the thumbnail size.
    public func thumbnail(squaresTo sizet: CGFloat, borderWidth: CGFloat = 0.0, cornerRadius: CGFloat = 0.0, quality: CGInterpolationQuality = .default) -> UIImage! {
        // Resize the original image.
        guard let resizedImage = resize(fits: CGSize(width: sizet, height: sizet), using: .scaleAspectFill, quality: quality) else { return nil }
        // Crop out any part of the image that's larger than the thumbnail size
        // The cropped rect must be centered on the resized image
        // Round the origin points so that the size isn't altered when CGRectIntegral is later invoked
        let croppedRect = CGRect(x: ((resizedImage.size.width - sizet) * 0.5).rounded(), y: ((resizedImage.size.height - sizet) * 0.5).rounded(), width: sizet, height: sizet)
        guard let croppedImage = resizedImage.crop(to: croppedRect) else { return nil }
        var borderedImage = croppedImage
        if borderWidth > 0.0 { borderedImage = croppedImage.bordered(borderWidth) }
        
        return borderedImage.round(cornerRadius, border: borderWidth)
    }
    /// Creates a copy of this image that is scale-aspect-fit to the thumbnail size using `ImageIO`.
    ///
    /// - Parameter size: A size of thumbnail to scale-aspect-fit to.
    ///
    /// - Returns: A copy of the receiver that is squared to the thumbnail size.
    public func thumbnail(scalesToFit size: CGFloat) -> UIImage! {
        guard let data = UIImageJPEGRepresentation(self, 1.0) as CFData? else { return nil }
        // Create an image source from NSData; no options.
        guard let imageSource = CGImageSourceCreateWithData(data, nil) else { return nil }
        // Package the integer as a  CFNumber object. Using CFTypes allows you
        // to more easily create the options dictionary later.
        var intSize = Int(size)
        guard let thumbnailSize = CFNumberCreate(nil, .intType, &intSize) else { return nil }
        // Set up the thumbnail options.
        let keys  : [CFString]  = [kCGImageSourceCreateThumbnailWithTransform, kCGImageSourceCreateThumbnailFromImageIfAbsent, kCGImageSourceThumbnailMaxPixelSize]
        let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue, thumbnailSize]
        let options = NSDictionary(objects: values, forKeys: keys as! [NSCopying]) as CFDictionary
        // Create the thumbnail image using the specified options.
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else { return nil }
        
        return UIImage(cgImage: thumbnail)
    }
    /// Resizes the image according to the given content mode, taking into account the image's orientation.
    ///
    /// - Parameter size        : A value of `CGSize` indicates the size to draw of the image.
    /// - Parameter resizingMode: An instance of `UIImage.ResizingMode` using to decide the size of the resizing.
    /// - Parameter quality     : An instance of `CGInterpolationQuality` indicates the
    ///                           interpolation of the receiver. Defaults to `.default.`
    ///
    /// - Returns: A copy of the receiver resized to the given size.
    public func resize(fits size: CGSize, using resizingMode: ResizingMode, quality: CGInterpolationQuality = .default) -> UIImage! {
        let horizontalRatio = size.width  / self.size.width
        let verticalRatio   = size.height / self.size.height
        var ratio: CGFloat
        
        switch resizingMode {
        case .scaleAspectFill:
            ratio = max(horizontalRatio, verticalRatio)
        case .scaleAspectFit:
            ratio = min(horizontalRatio, verticalRatio)
        default:
            return resize(fits: size, quality: quality)
        }
        
        let newSize = CGSize(width: (self.size.width * ratio).rounded(), height: (self.size.height * ratio).rounded())
        return resize(fits: newSize, quality: quality)
    }
    /// Creates a rescaled copy of the image, taking into account its orientation.
    ///
    /// The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter.
    ///
    /// - Parameter size   : A CGSize object to resize the scaling of the receiver with.
    /// - Parameter quality: An instance of `CGInterpolationQuality` indicates the
    ///                      interpolation of the receiver. Defaults to `.default.`
    ///
    /// - Returns: A rescaled copy of the receiver.
    public func resize(fits size: CGSize, quality: CGInterpolationQuality = .default) -> UIImage! {
        var transposed = false
        switch imageOrientation {
        case .left         : fallthrough
        case .leftMirrored : fallthrough
        case .right        : fallthrough
        case .rightMirrored:
            transposed = true
        default: break
        }
        
        return _resize(fits: size, applying: _transform(forOrientation: size), transposed: transposed, quality: quality)
    }
    /// Returns a copy of the image that has been transformed using the given affine transform and scaled to the new size
    ///
    /// The new image's orientation will be UIImageOrientationUp, regardless of the current image's orientation
    ///
    /// If the new size is not integral, it will be rounded up.
    private func _resize(fits newSize: CGSize, applying transform: CGAffineTransform, transposed: Bool, quality: CGInterpolationQuality) -> UIImage! {
        let newRect        = CGRect(origin: .zero, size: newSize).integral
        let transposedRect = CGRect(origin: .zero, size: CGSize(width: newRect.height, height: newRect.width))
        guard let cgImage = self.cgImage, let colorSpace = cgImage.colorSpace else { return nil }
        // Build a context that's the same dimensions as the new size
        var bitmap = cgImage.bitmapInfo
        let containing: [CGImageAlphaInfo] = [.first, .none]
        if  containing.map({ $0.rawValue }).contains(bitmap.rawValue) {
            bitmap = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        }
        
        guard let context = CGContext(data: nil, width: Int(newRect.width), height: Int(newRect.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmap.rawValue) else { return nil }
        // Rotate and/or flip the image if required by its orientation
        context.concatenate(transform)
        // Set the quality level to use when rescaling
        context.interpolationQuality = quality
        // Draw into the context, this scales the image
        context.draw(cgImage, in: transposed ? transposedRect : newRect)
        // Get the resized image from the context and a UIImage
        guard let resized_img = context.makeImage() else { return nil }
        return UIImage(cgImage: resized_img)
    }
    /// Returns an affine transform that takes into account the image orientation when drawing a scaled image.
    private func _transform(forOrientation size: CGSize) -> CGAffineTransform {
        let transform = CGAffineTransform.identity
        switch imageOrientation {
        case .down: fallthrough  // EXIF = 3
        case .downMirrored:      // EXIF = 4
            transform.translatedBy(x: size.width, y: size.height).rotated(by: CGFloat.pi)
        case .left: fallthrough  // EXIF = 6
        case .leftMirrored:      // EXIF = 5
            transform.translatedBy(x: size.width, y: 0.0).rotated(by: CGFloat.pi * 0.5)
        case .right: fallthrough // EXIF = 8
        case .rightMirrored:     // EXIF = 7
            transform.translatedBy(x: 0.0, y: size.height).rotated(by: -CGFloat.pi * 0.5)
        default: break
        }
        
        switch imageOrientation {
        case .upMirrored: fallthrough   // EXIF = 2
        case .downMirrored:             // EXIF = 4
            transform.translatedBy(x: size.width, y: 0.0).scaledBy(x: -1.0, y: 1.0)
        case .leftMirrored: fallthrough // EXIF = 5
        case .rightMirrored:            // EXIF = 7
            transform.translatedBy(x: size.height, y: 0.0).scaledBy(x: -1.0, y: 1.0)
        default: break
        }
        return transform
    }
}

// MARK: - Compressing.

extension UIImage {
    /// Creates a data stream of the receiver by compressing to the specific max allowed 
    /// bits length and max allowed width of size using `JPEGRepresentation`.
    ///
    /// - Parameter length: An integer value indicates the max allowed bits length to compress to.
    ///                     The length to compress to can not be negative or zero.
    /// - Parameter width : A float value indicates the max allowed width of the size of the reveiver.
    ///                     The width to compress to can not be negative or zero.
    ///
    /// - Returns: A compressed data stream of the receiver if any.
    public func compress(toBits length: Int, scalesToFit width: CGFloat? = nil) -> Data! {
        guard length > 0 else { return nil }
        // Scales the image to fit the specific size if any.
        var scaled = self
        if let maxSize = width {
            guard maxSize > 0.0 else { return nil }
            scaled = thumbnail(scalesToFit: maxSize)
        }
        // Do compress.
        var compressionQuality: CGFloat = 0.9
        var data              : Data?   = UIImageJPEGRepresentation(scaled, compressionQuality)
        
        while data?.count ?? 0 > length && compressionQuality > 0.01 {
            compressionQuality -= 0.02
            data                = UIImageJPEGRepresentation(scaled, compressionQuality)
        }
        
        return data
    }
}

// MARK: - Merging.

extension UIImage {
    /// A type representing the mode of the merging of images. Currently supporting `overlay`, `horizontal` and `vertical`.
    public enum MergingMode {
        /// A type representing the direction on the horizontal.
        public enum Horizontal {
            /// Indicates from-left-to-right direction.
            case leftToRight
            /// Indicates from-right-to-left direction.
            case rightToLeft
        }
        /// A type representing the direction on the vertical.
        public enum Vertical {
            /// Indicates from-top-to-bottom direction.
            case topToBottom
            /// Indicates from-bottom-to-top direction.
            case bottomToTop
        }
        /// Indicates the merged image will over lay on the original image.
        case overlay(ResizingMode)
        /// Indicates the images to merge will lay on the horizontal stack.
        case horizontally(Horizontal, ResizingMode)
        /// Indicates the images to merge will lay on the vertical stack.
        case vertically(Vertical, ResizingMode)
    }
    /// Creates a new instance of UIImage with the given images merged to the receiver by using the merging mode.
    /// The same direction resizing mode of the horizontal or vertical merging mode act just like the overlay mode.
    ///
    /// - Parameter images: A collection of instance of UIImage to merge with.
    /// - Parameter mode  : A value defined in the type `MergingMode` used to calculate the rectangle area of the images.
    ///
    /// - Returns: A new image object with all the images merged using the specific merging mode.
    public func merge(with images: [UIImage], using mode: MergingMode) -> UIImage! {
        var resultImage: UIImage = self
        images.forEach { (image) in autoreleasepool{
            var resultRect = CGRect(origin: .zero, size: resultImage.size)
            var pageRect   = CGRect(origin: .zero, size: image.size)
            var imageRect  : CGRect = .zero
            switch mode {
            case .overlay(let resizing):
                imageRect = CGRect(origin: .zero, size: CGSize(width: max(resultRect.width, pageRect.width), height: max(resultRect.height, pageRect.height)))
                switch resizing {
                case .scaleToFill:
                    resultRect = imageRect
                    pageRect   = imageRect
                case .scaleAspectFit:
                    resultRect = _rect(scales: resultRect, toFit: imageRect)
                    pageRect   = _rect(scales: pageRect  , toFit: imageRect)
                case .scaleAspectFill:
                    resultRect = _rect(scales: resultRect, toFill: imageRect)
                    pageRect   = _rect(scales: pageRect  , toFill: imageRect)
                case .center:
                    resultRect.origin.x = (imageRect.width  - resultRect.width ) * 0.5
                    resultRect.origin.y = (imageRect.height - resultRect.height) * 0.5
                    pageRect.origin.x   = (imageRect.width  - pageRect.width   ) * 0.5
                    pageRect.origin.y   = (imageRect.height - pageRect.height  ) * 0.5
                case .top:
                    resultRect.origin.x = (imageRect.width  - resultRect.width ) * 0.5
                    pageRect.origin.x   = (imageRect.width  - pageRect.width   ) * 0.5
                case .bottom:
                    resultRect.origin.x = (imageRect.width  - resultRect.width ) * 0.5
                    resultRect.origin.y = (imageRect.height - resultRect.height) * 1.0
                    pageRect.origin.x   = (imageRect.width  - pageRect.width   ) * 0.5
                    pageRect.origin.y   = (imageRect.height - pageRect.height  ) * 1.0
                case .left:
                    resultRect.origin.y = (imageRect.height - resultRect.height) * 0.5
                    pageRect.origin.y   = (imageRect.height - pageRect.height  ) * 0.5
                case .right:
                    resultRect.origin.x = (imageRect.width  - resultRect.width ) * 1.0
                    resultRect.origin.y = (imageRect.height - resultRect.height) * 0.5
                    pageRect.origin.x   = (imageRect.width  - pageRect.width   ) * 1.0
                    pageRect.origin.y   = (imageRect.height - pageRect.height  ) * 0.5
                case .topLeft: break
                case .topRight:
                    resultRect.origin.x = (imageRect.width  - resultRect.width ) * 1.0
                    pageRect.origin.x   = (imageRect.width  - pageRect.width   ) * 1.0
                case .bottomLeft:
                    resultRect.origin.y = (imageRect.height - resultRect.height) * 1.0
                    pageRect.origin.y   = (imageRect.height - pageRect.height  ) * 1.0
                case .bottomRight:
                    resultRect.origin.x = (imageRect.width  - resultRect.width ) * 1.0
                    resultRect.origin.y = (imageRect.height - resultRect.height) * 1.0
                    pageRect.origin.x   = (imageRect.width  - pageRect.width   ) * 1.0
                    pageRect.origin.y   = (imageRect.height - pageRect.height  ) * 1.0
                }
                resultImage = resultImage._merge(with: image, size: imageRect.size, beginsRect: resultRect, endsRect: pageRect)
            case .horizontally(let horizontal, let resizing):
                imageRect.size.width = resultRect.width + pageRect.width
                if horizontal == .leftToRight { pageRect.origin.x = resultRect.width } else {
                    resultRect.origin.x = pageRect.width
                }
                switch resizing {
                case .scaleToFill:
                    imageRect.size.height  = max(resultRect.height, pageRect.height)
                    resultRect.size.height = imageRect.height
                    pageRect.size.height   = imageRect.height
                case .scaleAspectFit : fallthrough
                case .scaleAspectFill:
                    let scalesToFitResult  = _rect(equalHeightScales: horizontal == .leftToRight ? resultRect : pageRect, toFit: horizontal == .leftToRight ? pageRect : resultRect)
                    resultRect             = horizontal == .leftToRight ? scalesToFitResult.0 : scalesToFitResult.1
                    pageRect               = horizontal == .leftToRight ?  scalesToFitResult.1: scalesToFitResult.0
                    imageRect.size.width   = scalesToFitResult.0.width + scalesToFitResult.1.width
                    imageRect.size.height  = max(scalesToFitResult.0.height, scalesToFitResult.1.height)
                case .center:
                    imageRect.size.height  = max(resultRect.height, pageRect.height)
                    resultRect.origin.y    = (imageRect.height - resultRect.height) * 0.5
                    pageRect.origin.y      = (imageRect.height - pageRect.height  ) * 0.5
                case .top:
                    imageRect.size.height  = max(resultRect.height, pageRect.height)
                case .bottom:
                    imageRect.size.height  = max(resultRect.height, pageRect.height)
                    resultRect.origin.y    = (imageRect.height - resultRect.height) * 1.0
                    pageRect.origin.y      = (imageRect.height - pageRect.height  ) * 1.0
                case .left:
                    imageRect.size.width   = max(resultRect.width, pageRect.width)
                    imageRect.size.height  = max(resultRect.height, pageRect.height)
                    if horizontal == .leftToRight { pageRect.origin.x =               0.0 } else {
                       resultRect.origin.x =                                          0.0
                    }
                    resultRect.origin.y    = (imageRect.height - resultRect.height) * 0.5
                    pageRect.origin.y      = (imageRect.height - pageRect.height  ) * 0.5
                case .right:
                    imageRect.size.width   = max(resultRect.width, pageRect.width)
                    imageRect.size.height  = max(resultRect.height, pageRect.height)
                    resultRect.origin.x    = (imageRect.width - resultRect.width)   * 1.0
                    resultRect.origin.y    = (imageRect.height - resultRect.height) * 0.5
                    pageRect.origin.x      = (imageRect.width  - pageRect.width   ) * 1.0
                    pageRect.origin.y      = (imageRect.height - pageRect.height  ) * 0.5
                case .topLeft:
                    imageRect.size.width   = max(resultRect.width, pageRect.width)
                    imageRect.size.height  = max(resultRect.height, pageRect.height)
                    if horizontal == .leftToRight { pageRect.origin.x =               0.0 } else {
                       resultRect.origin.x =                                          0.0
                    }
                case .topRight:
                    imageRect.size.width   = max(resultRect.width, pageRect.width)
                    imageRect.size.height  = max(resultRect.height, pageRect.height)
                    resultRect.origin.x    = (imageRect.width - resultRect.width)   * 1.0
                    pageRect.origin.x      = (imageRect.width  - pageRect.width )   * 1.0
                case .bottomLeft:
                    imageRect.size.width   = max(resultRect.width, pageRect.width)
                    imageRect.size.height  = max(resultRect.height, pageRect.height)
                    if horizontal == .leftToRight { pageRect.origin.x =               0.0 } else {
                       resultRect.origin.x =                                          0.0
                    }
                    resultRect.origin.y    = (imageRect.height - resultRect.height) * 1.0
                    pageRect.origin.y      = (imageRect.height - pageRect.height  ) * 1.0
                case .bottomRight:
                    imageRect.size.width   = max(resultRect.width, pageRect.width)
                    imageRect.size.height  = max(resultRect.height, pageRect.height)
                    resultRect.origin.x    = (imageRect.width - resultRect.width)   * 1.0
                    resultRect.origin.y    = (imageRect.height - resultRect.height) * 1.0
                    pageRect.origin.x      = (imageRect.width  - pageRect.width   ) * 1.0
                    pageRect.origin.y      = (imageRect.height - pageRect.height  ) * 1.0
                }
                resultImage = resultImage._merge(with: image, size: imageRect.size, beginsRect: resultRect, endsRect: pageRect)
            case .vertically(let vertical, let resizing):
                imageRect.size.height = resultRect.height + pageRect.height
                if vertical == .topToBottom { pageRect.origin.y = resultRect.height } else {
                    resultRect.origin.y = pageRect.height
                }
                switch resizing {
                case .scaleToFill:
                    imageRect.size.width  = max(resultRect.width, pageRect.width)
                    resultRect.size.width = imageRect.width
                    pageRect.size.width   = imageRect.width
                case .scaleAspectFit : fallthrough
                case .scaleAspectFill:
                    let scalesToFitResult = _rect(equalWidthScales: vertical == .topToBottom ? resultRect : pageRect, toFit: vertical == .topToBottom ? pageRect : resultRect)
                    resultRect            = vertical == .topToBottom ? scalesToFitResult.0 : scalesToFitResult.1
                    pageRect              = vertical == .topToBottom ? scalesToFitResult.1 : scalesToFitResult.0
                    imageRect.size.width  = max(scalesToFitResult.0.width, scalesToFitResult.1.width)
                    imageRect.size.height = scalesToFitResult.0.height + scalesToFitResult.1.height
                case .center:
                    imageRect.size.width  = max(resultRect.width, pageRect.width)
                    resultRect.origin.x   = (imageRect.width - resultRect.width)   * 0.5
                    pageRect.origin.x     = (imageRect.width - pageRect.width  )   * 0.5
                case .top:
                    imageRect.size.width  = max(resultRect.width, pageRect.width)
                    imageRect.size.height = max(resultRect.height, pageRect.height)
                    resultRect.origin.x   = (imageRect.width - resultRect.width)   * 0.5
                    pageRect.origin.x     = (imageRect.width - pageRect.width  )   * 0.5
                    if vertical == .topToBottom { pageRect.origin.y =                0.0 } else {
                       resultRect.origin.y =                                         0.0
                    }
                case .bottom:
                    imageRect.size.width  = max(resultRect.width, pageRect.width)
                    imageRect.size.height = max(resultRect.height, pageRect.height)
                    resultRect.origin.x   = (imageRect.width - resultRect.width  ) * 0.5
                    resultRect.origin.y   = (imageRect.height - resultRect.height) * 1.0
                    pageRect.origin.x     = (imageRect.width - pageRect.width    ) * 0.5
                    pageRect.origin.y     = (imageRect.height - pageRect.height  ) * 1.0
                case .left:
                    imageRect.size.width  = max(resultRect.width, pageRect.width)
                case .right:
                    imageRect.size.width  = max(resultRect.width, pageRect.width)
                    imageRect.size.width  = max(resultRect.width, pageRect.width)
                    resultRect.origin.x   = (imageRect.width - resultRect.width )  * 1.0
                    pageRect.origin.x     = (imageRect.width  - pageRect.width  )  * 1.0
                case .topLeft:
                    imageRect.size.width  = max(resultRect.width, pageRect.width)
                    imageRect.size.height = max(resultRect.height, pageRect.height)
                    if vertical == .topToBottom { pageRect.origin.y =                0.0 } else {
                       resultRect.origin.y =                                         0.0
                    }
                case .topRight:
                    imageRect.size.width  = max(resultRect.width, pageRect.width)
                    imageRect.size.height = max(resultRect.height, pageRect.height)
                    resultRect.origin.x   = (imageRect.width - resultRect.width)   * 1.0
                    pageRect.origin.x     = (imageRect.width  - pageRect.width )   * 1.0
                    if vertical == .topToBottom { pageRect.origin.y =                0.0 } else {
                       resultRect.origin.y =                                         0.0
                    }
                case .bottomLeft:
                    imageRect.size.width  = max(resultRect.width, pageRect.width)
                    imageRect.size.height = max(resultRect.height, pageRect.height)
                    resultRect.origin.y   = (imageRect.height - resultRect.height) * 1.0
                    pageRect.origin.y     = (imageRect.height - pageRect.height  ) * 1.0
                case .bottomRight:
                    imageRect.size.width  = max(resultRect.width, pageRect.width)
                    imageRect.size.height = max(resultRect.height, pageRect.height)
                    resultRect.origin.x   = (imageRect.width - resultRect.width)   * 1.0
                    resultRect.origin.y   = (imageRect.height - resultRect.height) * 1.0
                    pageRect.origin.x     = (imageRect.width  - pageRect.width   ) * 1.0
                    pageRect.origin.y     = (imageRect.height - pageRect.height  ) * 1.0
                }
                resultImage = resultImage._merge(with: image, size: imageRect.size, beginsRect: resultRect, endsRect: pageRect)
            }
        } }
        return resultImage
    }
    
    private func _merge(with image: UIImage, size: CGSize, beginsRect: CGRect, endsRect: CGRect) -> UIImage! {
        guard let cgImage = self.cgImage, let mergingCgImage = image.cgImage else { return nil }
        var mergedImage: UIImage! = self
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        let transform = CGAffineTransform(scaleX: 1.0, y: -1.0).translatedBy(x: 0.0, y: -size.height)
        context.concatenate(transform)
        
        context.draw(cgImage, in: beginsRect.applying(transform))
        context.draw(mergingCgImage, in: endsRect.applying(transform))
        mergedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return mergedImage
    }
    
    private func _rect(equalHeightScales rect1: CGRect, toFit rect2: CGRect) -> (CGRect, CGRect) {
        var resultRect1 = rect1
        var resultRect2 = rect2
        
        if resultRect1.height >= resultRect2.height {
            let ratio = resultRect1.height / resultRect2.height
            resultRect2.size.width  = resultRect2.width * ratio
            resultRect2.size.height = resultRect1.height
        } else {
            let ratio = resultRect2.height / resultRect1.height
            resultRect1.size.width  = resultRect1.width * ratio
            resultRect1.size.height = resultRect2.height
        }
        resultRect1.origin.y = 0.0
        resultRect2.origin.y = 0.0
        resultRect2.origin.x = resultRect1.width
        
        return (resultRect1, resultRect2)
    }
    
    private func _rect(equalWidthScales rect1: CGRect, toFit rect2: CGRect) -> (CGRect, CGRect) {
        var resultRect1 = rect1
        var resultRect2 = rect2
        
        if resultRect1.width >= resultRect2.width {
            let ratio = resultRect1.width / resultRect2.width
            resultRect2.size.height = resultRect2.height * ratio
            resultRect2.size.width  = resultRect1.width
        } else {
            let ratio = resultRect2.width / resultRect1.width
            resultRect1.size.height = resultRect1.height * ratio
            resultRect1.size.width  = resultRect2.width
        }
        resultRect1.origin.x = 0.0
        resultRect2.origin.x = 0.0
        resultRect2.origin.y = resultRect1.height
        
        return (resultRect1, resultRect2)
    }
    
    private func _rect(scales rect1: CGRect, toFit rect2: CGRect) -> CGRect {
        let maxRect = CGRect(origin: .zero, size: CGSize(width: max(rect1.width, rect2.width), height: max(rect1.height, rect2.height)))
        
        var resultRect = rect1
        
        if resultRect.height >= resultRect.width { // Aspect fit height.
            let ratio = maxRect.height / resultRect.height
            resultRect.size.width  = resultRect.width * ratio
            resultRect.size.height = maxRect.height
            resultRect.origin.x    = (maxRect.width - resultRect.width) * 0.5
        } else {
            let ratio = maxRect.width / resultRect.width
            resultRect.size.height = resultRect.height * ratio
            resultRect.size.width  = maxRect.width
            resultRect.origin.y    = (maxRect.height - resultRect.height) * 0.5
        }
        
        return resultRect
    }
    
    private func _rect(scales rect1: CGRect, toFill rect2: CGRect) -> CGRect {
        let maxRect = CGRect(origin: .zero, size: CGSize(width: max(rect1.width, rect2.width), height: max(rect1.height, rect2.height)))
        
        var resultRect = rect1
        
        if resultRect.height < resultRect.width { // Aspect fill width.
            let ratio = maxRect.height / resultRect.height
            resultRect.size.width  = resultRect.width * ratio
            resultRect.size.height = maxRect.height
            resultRect.origin.x    = (maxRect.width - resultRect.width) * 0.5
        } else {
            let ratio = maxRect.width / resultRect.width
            resultRect.size.height = resultRect.height * ratio
            resultRect.size.width  = maxRect.width
            resultRect.origin.y    = (maxRect.height - resultRect.height) * 0.5
        }
        
        return resultRect
    }
}

// MARK: - Vector.

extension UIImage {
    /// Creates an image from any instances of `String` with the specific font and tint color.
    /// The `String` contents' count should not be zero. If so, nil will be returned.
    ///
    /// - Parameter content: An instance of `String` to generate `UIImage` with.
    /// - Parameter font   : The font used to draw image with. Using `.systemFont(ofSize: 17)` by default.
    /// - Parameter color  : The color used to fill image with. Using `.black` by default.
    ///
    /// - Returns: A `String` contents image created with specific font and color.
    public class func image(from content: String, using font: UIFont = .systemFont(ofSize: 17), tint color: UIColor = .black) -> UIImage! {
        let ligature = NSMutableAttributedString(string: content)
        ligature.setAttributes([(kCTLigatureAttributeName as String): 2, (kCTFontAttributeName as String): font], range: NSMakeRange(0, content.lengthOfBytes(using: .utf8)))
        
        var imageSize    = ligature.size()
        imageSize.width  = ceil(imageSize.width)
        imageSize.height = ceil(imageSize.height)
        guard !imageSize.equalTo(.zero) else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        ligature.draw(at: .zero)
        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else { return nil }
        
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -imageSize.height)
        let rect = CGRect(origin: .zero, size: imageSize)
        context.clip(to: rect, mask: cgImage)
        color.setFill()
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    /// Creates an image from any instances of `CGPDFDocument` with the specific size and tint color.
    ///
    /// - Parameter pdf  : An instance of `CGPDFDocument` to generate `UIImage` with.
    /// - Parameter size : The size used to draw image fitting with.
    /// - Parameter color: The color used to fill image with. Using nil by default.
    ///
    /// - Returns: A `CGPDFDocument` contents image created with specific size and color.
    public class func image(fromPDFDocument pdf: CGPDFDocument, scalesToFit size: CGSize, pageCountLimits: Int, tint color: UIColor? = nil) -> UIImage! {
        var pageIndex = 1
        var image: UIImage!
        while pageIndex <= min(pdf.numberOfPages, pageCountLimits), let page = pdf.page(at: pageIndex) { autoreleasepool {
            let mediaRect = page.getBoxRect(.cropBox)
            // Calculate the real fits size of the image.
            var imageSize = mediaRect.size
            if  imageSize.height < size.height && size.height != CGFloat.greatestFiniteMagnitude {
                imageSize.width = (size.height / imageSize.height * imageSize.width).rounded()
                imageSize.height = size.height
            }
            if  imageSize.width < size.width && size.width != CGFloat.greatestFiniteMagnitude {
                imageSize.height = (size.width / imageSize.width  * imageSize.height).rounded()
                imageSize.width = size.width
            }
            if  imageSize.height > size.height {
                imageSize.width = (size.height / imageSize.height * imageSize.width).rounded()
                imageSize.height = size.height
            }
            if  imageSize.width > size.width {
                imageSize.height = (size.width / imageSize.width  * imageSize.height).rounded()
                imageSize.width  =  size.width
            }
            // Draw the current page image.
            UIGraphicsBeginImageContextWithOptions(imageSize, false, UIScreen.main.scale)
            guard let context = UIGraphicsGetCurrentContext() else { return }
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0.0, y: -imageSize.height)
            let scale = min(imageSize.width / mediaRect.width, imageSize.height / mediaRect.height)
            context.scaleBy(x: scale, y: scale)
            context.drawPDFPage(page)
            let currentImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            // Merge the former and current page image.
            if let resultImage = image, let pageImage = currentImage {
                image = resultImage.merge(with: [pageImage], using: .vertically(.topToBottom, .scaleAspectFill))
            } else {
                image = currentImage
            }
            
            pageIndex += 1
        } }
        
        if let tintColor = color, let cgImage = image.cgImage {
            UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.main.scale)
            guard let context = UIGraphicsGetCurrentContext() else { return image }
            context.scaleBy(x: 1.0, y: -1.0)
            context.translateBy(x: 0.0, y: -image.size.height)
            let rect = CGRect(origin: .zero, size: image.size)
            context.clip(to: rect, mask: cgImage)
            tintColor.setFill()
            context.fill(rect)
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return image
    }
    public class func image(fromPDFData pdfData: Data, scalesToFit size: CGSize, pageCountLimits: Int = 12, tint color: UIColor? = nil) -> UIImage! {
        // Creates the pdg document from the data.
        guard let dataProvider = CGDataProvider(data: pdfData as CFData) else { return nil }
        guard let pdf = CGPDFDocument(dataProvider) else { return nil }
        
        return image(fromPDFDocument: pdf, scalesToFit: size, pageCountLimits: pageCountLimits, tint: color)
    }
    public class func image(fromPDFUrl pdfUrl: URL, scalesToFit size: CGSize, pageCountLimits: Int = 12, tint color: UIColor? = nil) -> UIImage! {
        // Creates the pdg document from the url.
        guard let pdf = CGPDFDocument(pdfUrl as CFURL) else { return nil }
        
        return image(fromPDFDocument: pdf, scalesToFit: size, pageCountLimits: pageCountLimits, tint: color)
    }
    public class func image(fromPDFAtPath pdfPath: String, scalesToFit size: CGSize, pageCountLimits: Int = 12, tint color: UIColor? = nil) -> UIImage! {
        return image(fromPDFUrl: URL(fileURLWithPath: pdfPath), scalesToFit: size, pageCountLimits: pageCountLimits, tint: color)
    }
    public class func image(fromPDFNamed pdfName: String, scalesToFit size: CGSize, pageCountLimits: Int = 12, tint color: UIColor? = nil) -> UIImage! {
        guard let path = Bundle.main.path(forResource: pdfName, ofType: "pdf") else { return nil }
        
        return image(fromPDFAtPath: path, scalesToFit: size, pageCountLimits: pageCountLimits, tint: color)
    }
}

// MARK: - Orientation.

extension UIImage {
    /// Creates a copy of the receiver image with orientation fixed if the image orientation
    /// is not the `.up`.
    public var orientationFixed: UIImage! {
        guard imageOrientation != .up else { return self }
        
        let transform: CGAffineTransform = .identity
        switch imageOrientation {
        case .down: fallthrough
        case .downMirrored:
            transform.translatedBy(x: size.width, y: size.height).rotated(by: CGFloat.pi)
        case .left: fallthrough
        case .leftMirrored:
            transform.translatedBy(x: size.width, y: 0.0).rotated(by: CGFloat.pi * 0.5)
        case .right: fallthrough
        case .rightMirrored:
            transform.translatedBy(x: 0.0, y: size.height).rotated(by: -CGFloat.pi * 0.5)
        default: break
        }
        
        switch imageOrientation {
        case .upMirrored: fallthrough
        case .downMirrored:
            transform.translatedBy(x: size.width, y: 0.0).scaledBy(x: -1.0, y: 1.0)
        case .leftMirrored: fallthrough
        case .rightMirrored:
            transform.translatedBy(x: size.height, y: 0.0).scaledBy(x: -1.0, y: 0.0)
        default: break
        }
        
        guard let cgImage = self.cgImage, let colorSpace = cgImage.colorSpace, let context = CGContext(data: nil, width: cgImage.width, height: cgImage.height, bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue) else { return nil }
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left: fallthrough
        case .leftMirrored: fallthrough
        case .right: fallthrough
        case .rightMirrored:
            context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: size.height, height: size.width)))
        default:
            context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height)))
        }
        guard let image = context.makeImage() else { return nil }
        
        return UIImage(cgImage: image)
    }
    /// Creates and returns a copy of the receiver image with flipped vertically.
    public var verticallyFlipped: UIImage! { return _flip(horizontally: false) }
    /// Creates and returns a copy of the receiver image with flipped horizontally.
    public var horizontallyFlipped: UIImage! { return _flip(horizontally: true) }
    /// Creates a copy of the receiver image by the given angle.
    /// 
    /// - Parameter angle: A float value indicates the angle to rotate by.
    ///
    /// - Returns: A new image with the given angle rotated.
    public func rotate(by angle: CGFloat) -> UIImage! {
        // Calculate the size of the rotated view's containing box for our drawing space.
        let transform = CGAffineTransform(rotationAngle: angle)
        let rotatedBox = CGRect(origin: .zero, size: size).applying(transform)
        // Create the bitmap context.
        UIGraphicsBeginImageContextWithOptions(rotatedBox.size, false, UIScreen.main.scale)
        guard let cgImage = self.cgImage, let context = UIGraphicsGetCurrentContext() else { return nil }
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        context.translateBy(x: rotatedBox.width * 0.5, y: rotatedBox.height * 0.5)
        // Rotate the image context.
        context.rotate(by: angle)
        // Now, draw the rotated/scaled image into the context.
        context.scaleBy(x: 1.0, y: -1.0)
        
        context.draw(cgImage, in: CGRect(x: -size.width * 0.5, y: -size.height * 0.5, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func _flip(horizontally: Bool) -> UIImage! {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        guard let cgImage = self.cgImage, let context = UIGraphicsGetCurrentContext() else { return nil }
        context.clip(to: rect)
        if horizontally {
            context.rotate(by: CGFloat.pi)
            context.translateBy(x: -rect.width, y: -rect.height)
        }
        context.draw(cgImage, in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
