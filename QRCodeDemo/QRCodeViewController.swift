//
//  QRCodeViewController.swift
//  QRCodeDemo
//
//  Created by ning on 2018/8/9.
//  Copyright © 2018年 ning. All rights reserved.
//

import UIKit

class QRCodeViewController: UIViewController {
   
    fileprivate lazy var readerView: QRCodeReaderView = {
        let h = CGFloat(64)
        let frame = CGRect(x: 0, y: h, width: self.view.bounds.width, height: self.view.bounds.height-h)
        let v = QRCodeReaderView(frame: frame)
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return v
    }()
    public var completion: QRCodeReaderCompletion?
    convenience init(completion: QRCodeReaderCompletion?) {
        self.init()
        self.completion = completion
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let leftBtn = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(didBackButtonTouchUpInside))
        let rightBtn = UIBarButtonItem(title: "相册", style: .plain, target: self, action: #selector(didAlbumButtonTouchUpInside))
        self.navigationItem.leftBarButtonItem = leftBtn
        self.navigationItem.rightBarButtonItem = rightBtn
        if QRCodeReader.isDeviceAvailable() && !QRCodeReader.isCameraUseDenied(){
            setupReader()
        }
    }
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        guard QRCodeReader.isDeviceAvailable() else{
            let alert = UIAlertController(title: "Error", message: "相机无法使用", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .cancel, handler: {
                _ in
                self.navigationController?.popViewController(animated: true)
            }))
            present(alert, animated: true, completion: nil)
            return
        }
        if QRCodeReader.isCameraUseDenied(){
            hanldeAlertForAuthorization(isCamera: true)
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if QRCodeReader.isCameraUseAuthorized(){
            readerView.updateRectOfOutput()
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    //打开相册
    @objc func didAlbumButtonTouchUpInside(_ sender: Any) {
        handleActionForImagePicker()
    }
    //点击返回
    @objc func didBackButtonTouchUpInside(_ sender: Any) {
        completionFor(result: nil, isCancel: true)
    }
}

extension QRCodeViewController {
    fileprivate func completionFor(result: String?, isCancel: Bool){
        readerView.reader.stopScanning()
        self.navigationController?.popViewController(animated: true)
        isCancel ? nil : self.completion?(result ?? "没有发现任何信息")
    }
}
extension QRCodeViewController{
    fileprivate func handleActionForImagePicker(){
        if QRCodeReader.isAlbumUseDenied() {
            hanldeAlertForAuthorization(isCamera: false)
            return
        }
        readerView.reader.stopScanning()
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        picker.allowsEditing = false
        present(picker, animated: true, completion: nil)
    }
    
    fileprivate func setupReader(){
        view.addSubview(readerView)
        readerView.setup(completion: {[unowned self]
            (result) in
            self.completionFor(result: result, isCancel: false)
        })
    }
    
    fileprivate func openSystemSettings(){
        guard let url = URL(string: UIApplicationOpenSettingsURLString) else {
            return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    fileprivate func hanldeAlertForAuthorization(isCamera: Bool){
        let str = isCamera ? "相机" : "相册"
        let alert = UIAlertController(title: "\(str)没有授权", message: "在[设置]中找到应用，开启[允许访问\(str)]", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "去设置", style: .cancel, handler: { _ in
            self.openSystemSettings()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func handleQRCodeScanningFor(image: UIImage){
        let ciimage = CIImage(cgImage: image.cgImage!)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        if let features = detector?.features(in: ciimage),
            let first = features.first as? CIQRCodeFeature{
            self.completionFor(result: first.messageString, isCancel: false)
        }
    }
}

extension QRCodeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        readerView.reader.startScanning(completion: completion)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            picker.dismiss(animated: true, completion: {
                self.handleQRCodeScanningFor(image: image)
            })
        }
    }
}

extension QRCodeViewController{
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if QRCodeReader.isDeviceAvailable() && QRCodeReader.isCameraUseAuthorized() {
            readerView.updateRectOfOutput()
        }
    }
}
