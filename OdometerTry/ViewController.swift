//
//  ViewController.swift
//  OdometerTry
//
//  Created by Eagle Diao on 2019-01-22.
//  Copyright © 2019 oneHook. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var odometer: OdometerLabelV2!

    @IBOutlet weak var odometer2: OdometerLabelV2!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.odometer.setNumber("123,234,456$", animated: false)
    }

    @IBAction func valueChanged(_ sender: Any) {

//        self.odometer.setNumber(Int(self.slider.value), animated: true)
    }

    @IBAction func stopSlider(_ sender: Any) {
        print(self.slider.value)

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let newNumber = Int.random(in: Int(truncating: pow(10, Int(self.slider.value) - 1) as NSDecimalNumber) ..< Int(truncating: pow(10, Int(self.slider.value)) as NSDecimalNumber))
        formatter.locale = Locale(identifier: "fr_CA")
        formatter.groupingSeparator = " "
        let pstring = formatter.string(from: newNumber as! NSNumber) ?? ""
        print(formatter.locale)
        self.odometer.setNumber(pstring, animated: true)
        self.label.text = pstring

        formatter.locale = Locale(identifier: "en_CA")
        formatter.groupingSeparator = " "
        let pstring2 = formatter.string(from: newNumber as! NSNumber) ?? ""
        self.odometer2.setNumber(pstring2, animated: true)
    }
    @IBAction func valueEditingEnd(_ sender: Any) {

    }
}

