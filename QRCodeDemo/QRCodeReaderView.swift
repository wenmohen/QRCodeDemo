//
//  QRCodeReaderView.swift
//  CodeScanner
//
//  Created by zhuxuhong on 2017/4/19.
//  Copyright © 2017年 zhuxuhong. All rights reserved.
//

import UIKit

class QRCodeReaderView: UIView {
// MARK: - IBOutlet
    @IBOutlet weak var overlayIV: UIImageView!
    @IBOutlet weak var lineIV: UIImageView!
    @IBOutlet weak var lineIVTopCons: NSLayoutConstraint!
    @IBOutlet weak var tipsLable: UILabel!

// MARK: - properties
    fileprivate var scanningFromTop = true
    fileprivate var cons: CGFloat = 0
    public lazy var reader: QRCodeReader = {
        let v = QRCodeReader()
        return v
    }()
    fileprivate var timer: Timer?
    fileprivate lazy var container: UIView = {
        guard let v: UIView = Bundle.main.loadNibNamed("QRCodeReaderView", owner: self, options: nil)?.first as? UIView else { return QRCodeReaderView()}
        v.frame = self.bounds
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return v
    }()

    deinit
    {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
}

extension QRCodeReaderView{
    public func setup(completion: @escaping QRCodeReaderCompletion){
        layer.addSublayer(self.reader.previewLayer)
        addSubview(container)
        startOverlayAnimation()
        reader.startScanning(completion: completion)
    }
    
    public func updateRectOfOutput(){
        let inset = reader.previewLayer.metadataOutputRectConverted(fromLayerRect: overlayIV.frame)
        reader.output.rectOfInterest = inset
    }
}

extension QRCodeReaderView{
    fileprivate func startOverlayAnimation(){
        timer = Timer.scheduledTimer(timeInterval: 0.004, target: self, selector: #selector(didTimerChange), userInfo: nil, repeats: true)
         timer?.fire()
    }
    
    fileprivate func isIpad() -> Bool{
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    @objc func didTimerChange() {
        // 动画
        let h: CGFloat = isIpad() ? 300 : 200
        if self.cons <= 10{
            self.scanningFromTop = true
        }
        else if self.cons >= h - 10{
            self.scanningFromTop = false
        }
        
        if self.scanningFromTop {
            self.cons += 1
        }
        else{
            self.cons -= 1
        }
        
        self.lineIVTopCons.constant = self.cons
        self.layoutIfNeeded()
    }
}

extension QRCodeReaderView{
    override func layoutSubviews() {
        super.layoutSubviews()
        reader.previewLayer.frame = bounds
    }
}

