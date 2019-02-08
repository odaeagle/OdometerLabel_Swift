import UIKit

class OdometerLabelDemoViewController: UITableViewController {

    @IBOutlet weak var dateOdometerLabel: OdometerLabel!
    var timer: Timer?

    @IBOutlet weak var currencySlider1: UISlider!
    @IBOutlet weak var currencyLabel1: OdometerLabel!


    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateDateLabel()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.updateDateLabel()
        })

        self.currencySlider1.addTarget(self, action: #selector(sliderValueChanged(sender:)), for: .valueChanged)

        self.sliderValueChanged(sender: self.currencySlider1)
    }

    private func updateDateLabel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = dateFormatter.string(from: Date())
        self.dateOdometerLabel.setNumber(timeString, animated: true)
    }

    @objc func sliderValueChanged(sender: UIControl) {
        if self.currencySlider1 == currencySlider1 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "en_CA")
            let number = Int(self.currencySlider1.value)
            self.currencyLabel1.setNumber(formatter.string(from: number as NSNumber)!, animated: true)
        }

    }
}

