//
//  CameraService.swift
//  ImageFilter
//
//  Created by vd-rahim on 1/10/18.
//  Copyright © 2018 venturedive. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class CameraService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    
    var captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    
    var filter:CIFilter?
    
    var currentCameraPosition: CameraPosition?
    var frontDeviceInput: AVCaptureDeviceInput?
    var backDeviceInput: AVCaptureDeviceInput?
    
    var photoOutput: AVCapturePhotoOutput?
    var orientation: AVCaptureVideoOrientation = .portrait
    
    var delegate: photoCaptureDelegate?
    let context = CIContext()

    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    public enum CameraPosition {
        case front
        case rear
    }
    
    func setupInputIfAuthorized(){
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != .authorized
        {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
                { (authorized) in
                    DispatchQueue.main.async
                        {
                            if authorized
                            {
                                self.setupInputOutput()
                            }
                    }
            })
        }
    }
    
    func setupDevice() throws{
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
                backDeviceInput = try AVCaptureDeviceInput(device: backCamera!)
            }
            else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
                frontDeviceInput = try AVCaptureDeviceInput(device: frontCamera!)
            }else{
                throw CameraControllerError.noCamerasAvailable
            }
        }
        currentCamera = backCamera
        currentCameraPosition = CameraPosition.rear
    }
    
    func setupInputOutput() {
        do {
            setupCorrectFramerate(currentCamera: currentCamera!)
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
            if captureSession.canAddInput(backDeviceInput!) {
                captureSession.addInput(backDeviceInput!)
            }
            let videoOutput = AVCaptureVideoDataOutput()
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            captureSession.startRunning()
        } catch {
            print(error)
        }
    }
    
    func setupCorrectFramerate(currentCamera: AVCaptureDevice) {
        for vFormat in currentCamera.formats {

            var ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
            let frameRates = ranges[0]
            
            do {
                //set to 240fps - available types are: 30, 60, 120 and 240 and custom
                // lower framerates cause major stuttering
                if frameRates.maxFrameRate == 240 {
                    try currentCamera.lockForConfiguration()
                    currentCamera.activeFormat = vFormat as AVCaptureDevice.Format
                    //for custom framerate set min max activeVideoFrameDuration to whatever you like, e.g. 1 and 180
                    currentCamera.activeVideoMinFrameDuration = frameRates.minFrameDuration
                    currentCamera.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                }
            }
            catch {
                print("Could not set active format")
                print(error)
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = orientation
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvImageBuffer: pixelBuffer!)
        getFilteredOutput(cameraImg: cameraImage)
        
    }
    
    func getFilteredOutput(cameraImg: CIImage){
        if let _ = filter{
            filter!.setValue(cameraImg, forKey: kCIInputImageKey)
            let cgImage = self.context.createCGImage(filter!.outputImage!, from: cameraImg.extent)!
            self.delegate?.previewFilteredImage(image: UIImage(cgImage: cgImage))
        }else{
            self.delegate?.previewFilteredImage(image: UIImage(ciImage: cameraImg))
        }
        
    }
    
    func updateFilter(filter:String){
        if !filter.elementsEqual("Default"){
            self.filter = CIFilter(name: filter)
        }else{
            self.filter = nil
        }
        
    }
}


protocol photoCaptureDelegate {
    func previewFilteredImage(image:UIImage)
}
