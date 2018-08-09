//
//  ViewController.swift
//  QRCodeDemo
//
//  Created by ning on 2018/8/9.
//  Copyright © 2018年 ning. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let dest = segue.destination as? QRCodeViewController{
            dest.completion = {[unowned self](result)in
                print(result)
                let alert = UIAlertController(title: "扫描结果", message: result, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

