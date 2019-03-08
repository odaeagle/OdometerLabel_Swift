import UIKit

class OdometerLabelDemoViewController: UITableViewController {

    @IBOutlet weak var dateOdometerLabel: OdometerLabel!
    var timer: Timer?

    @IBOutlet weak var currencySlider1: UISlider!
    @IBOutlet weak var currencyLabel1: OdometerLabel!

    @IBOutlet weak var animationSwitch: UISwitch!
    @IBOutlet weak var odometerStyleLabel: OdometerLabel!
    @IBOutlet weak var odometerStyleSlider: UISlider!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dateOdometerLabel.textAlignment = .center
        self.updateDateLabel()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.updateDateLabel()
        })

        self.currencyLabel1.textAlignment = .right
        self.currencySlider1.addTarget(self, action: #selector(sliderValueChanged(sender:)), for: .valueChanged)
        self.odometerStyleSlider.addTarget(self, action: #selector(sliderValueChanged(sender:)), for: .valueChanged)
        self.sliderValueChanged(sender: self.currencySlider1)

        self.odometerStyleLabel.horizontalSpacing = 4
        self.odometerStyleLabel.animationDuration = 2
    }

    private func updateDateLabel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = dateFormatter.string(from: Date())
        self.dateOdometerLabel.setNumber(timeString, animated: true)
    }

    @objc func sliderValueChanged(sender: UIControl) {
        if self.currencySlider1 == sender {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "en_CA")
            let number = Int(self.currencySlider1.value)
            self.currencyLabel1.setNumber(formatter.string(from: number as NSNumber)!, animated: true)
        } else if self.odometerStyleSlider == sender {
            let number = Int(self.odometerStyleSlider.value)
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.locale = Locale(identifier: "en_CA")
            self.odometerStyleLabel.setNumber(formatter.string(from: number as NSNumber)!, animated: self.animationSwitch.isOn)

            if !self.animationSwitch.isOn {
                print("show", number)
                DispatchQueue.main.async {
                    self.odometerStyleLabel.setNumber(formatter.string(from: (number + 22) as NSNumber)!, animated: true)
                }
            }
        }
    }
}

