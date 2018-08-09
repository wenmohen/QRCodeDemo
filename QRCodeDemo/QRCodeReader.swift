//
//  QRCodeReader.swift
//  CodeScanner
//
//  Created by zhuxuhong on 2017/4/19.
//  Copyright © 2017年 zhuxuhong. All rights reserved.
//

import UIKit
import AVFoundation
import Photos


typealias QRCodeReaderCompletion = ((_ result: String) -> Void)

class QRCodeReader: NSObject {
    fileprivate var completion: QRCodeReaderCompletion?
    
    public let device = AVCaptureDevice.default(for: .video)
    
    public lazy var output: AVCaptureMetadataOutput = {
        let v = AVCaptureMetadataOutput()
        v.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        return v
    }()
    
    public lazy var session: AVCaptureSession = {
        let v = AVCaptureSession()
        v.sessionPreset = AVCaptureSession.Preset.high
        
        if let tempDevice = self.device, let input = try? AVCaptureDeviceInput(device: tempDevice),
            v.canAddInput(input){
            v.addInput(input)
        }
        if v.canAddOutput(self.output) {
            v.addOutput(self.output)
            if !self.output.availableMetadataObjectTypes.isEmpty {
                self.output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            }
        }
        
        return v
    }()
    
    public lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let v = AVCaptureVideoPreviewLayer(session: self.session)
        v.videoGravity = AVLayerVideoGravity.resizeAspectFill
        v.connection?.videoOrientation = self.videoOrientation(interfaceOrientation: UIApplication.shared.statusBarOrientation)
        
        return v
    }()
    
    override init() {
        super.init()
        
        // 监听转屏，调整摄像头方向
        NotificationCenter.default.addObserver(self, selector: #selector(notification(_:)), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopScanning()
    }
}

extension QRCodeReader{
    @objc fileprivate func notification(_ sender: NSNotification){
        guard let _  = previewLayer.connection?.isVideoOrientationSupported  else {
            return
        }
        previewLayer.connection?.videoOrientation = videoOrientation(interfaceOrientation: UIApplication.shared.statusBarOrientation)
       
    }
    
    fileprivate func videoOrientation(interfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation{
        
        switch interfaceOrientation {
        case .landscapeLeft:
            return .landscapeLeft;
        case .landscapeRight:
            return .landscapeRight;
        case .portrait:
            return .portrait;
        default:
            return .portraitUpsideDown;
        }
    }
    
    public func startScanning(completion: QRCodeReaderCompletion?){
        self.completion = completion
        self.session.startRunning()
    }
    
    public func stopScanning(){
        self.session.stopRunning()
    }
    
    public static func isDeviceAvailable() -> Bool{
        return AVCaptureDevice.default(for: .video) != nil
    }
    
    public static func isCameraUseAuthorized() -> Bool{
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    public static func isCameraUseDenied() -> Bool{
        return AVCaptureDevice.authorizationStatus(for: .video) == .denied
    }
    
    public static func isAlbumUseDenied() -> Bool{
        return PHPhotoLibrary.authorizationStatus() == .denied
    }
    
    public static func isTorchAvailable() -> Bool{
        if let device = AVCaptureDevice.default(for: .video) {
            return device.isTorchAvailable
        }
        return false
    }
    
    public static func toggleTorch() -> Bool{
        let device = AVCaptureDevice.default(for: .video)
        let isOn = device?.torchMode == .on
        device?.torchMode = isOn ? .off : .on
        return isOn
    }
}

extension QRCodeReader: AVCaptureMetadataOutputObjectsDelegate{
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if !metadataObjects.isEmpty,
            let data = metadataObjects.first as? AVMetadataMachineReadableCodeObject
        {
            stopScanning()
            completion?(data.stringValue ?? "")
        }
    }
}
