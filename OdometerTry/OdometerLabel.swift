import UIKit

class OdometerLabel: UIView {

    var animationDuration: TimeInterval = 0.50
    var textAlignment: NSTextAlignment = .center {
        didSet {
            self.setNumber(self.number, animated: false)
        }
    }

    var font: UIFont = UIFont.systemFont(ofSize: 20) {
        didSet {
            /* Measure single digit size */
            let attributes = [NSAttributedString.Key.font: self.font]
            let attributedText = NSAttributedString(string: "0\n1\n2\n3\n4\n5\n6\n7\n8\n9",
                                                    attributes: attributes)
            let textLayer = self.obtainDigitTextLayer()
            textLayer.font = self.font
            textLayer.fontSize = self.font.pointSize
            textLayer.contentsScale = UIScreen.main.scale

            let size = attributedText.size()
            let preferedSize = textLayer.preferredFrameSize()
            self.singleDigitSize = CGSize(width: size.width, height: preferedSize.height / 10)
            self.recycleTextLayer(textLayer)

            self.prefixTextLayer?.font = font
            self.prefixTextLayer?.fontSize = font.pointSize
            self.suffixTextLayer?.font = font
            self.suffixTextLayer?.fontSize = font.pointSize
            self.setNumber(self.number, animated: false)
        }
    }

    var textColor: UIColor = UIColor.red {
        didSet {
            for textLayer in self.textLayers {
                textLayer.foregroundColor = self.textColor.cgColor
            }
            for textLayer in self.seperatorLayers {
                textLayer.foregroundColor = self.textColor.cgColor
            }
            self.prefixTextLayer?.foregroundColor = self.textColor.cgColor
            self.suffixTextLayer?.foregroundColor = self.textColor.cgColor
            self.setNumber(self.number, animated: false)
        }
    }

    var horizontalSpacing: CGFloat = 0 {
        didSet {
            self.setNumber(self.number, animated: false)
        }
    }

    var seperatorText: String = "," {
        didSet {
            for textLayer in self.seperatorLayers {
                textLayer.string = self.seperatorText
            }
            self.setNumber(self.number, animated: false)
        }
    }

    var prefix: String? {
        didSet {
            if self.prefix?.isEmpty ?? true {
                self.prefixTextLayer?.removeFromSuperlayer()
                self.prefixTextLayer = nil
            } else {
                if self.prefixTextLayer == nil {
                    let textLayer = self.obtainTextLayer()
                    self.prefixTextLayer = textLayer
                    self.contentLayer.addSublayer(textLayer)
                    textLayer.string = self.prefix!
                } else {
                    self.prefixTextLayer!.string = self.prefix!
                }
            }
        }
    }

    var suffix: String? {
        didSet {
            if self.suffix?.isEmpty ?? true {
                self.suffixTextLayer?.removeFromSuperlayer()
                self.suffixTextLayer = nil
            } else {
                if self.suffixTextLayer == nil {
                    let textLayer = self.obtainTextLayer()
                    self.suffixTextLayer = textLayer
                    self.contentLayer.addSublayer(textLayer)
                    textLayer.string = self.suffix!
                }
            }
        }
    }

    private(set) var number: Int = 0

    private var contentLayer = CALayer()
    private var scrollLayers = [CAScrollLayer]()
    private var textLayers = [CATextLayer]()
    private var seperatorLayers = [CATextLayer]()

    private var singleDigitSize: CGSize?

    private var prefixTextLayer: CATextLayer?
    private var suffixTextLayer: CATextLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        self.layer.addSublayer(self.contentLayer)
        self.font = UIFont.systemFont(ofSize: 20)
        self.setNumber(self.number, animated: false)
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        self.doLayoutNumber(number: self.number)
        print("HELLO")
    }

    private func doLayoutNumber(number: Int) {
        let width = layer.bounds.width
        let height = layer.bounds.height

        let numberString = String(number)
        let digitWidth = self.singleDigitSize?.width ?? 0
        let digitHeight = self.singleDigitSize?.height ?? 0
        let seperatorWidth = self.singleDigitSize?.width ?? 0

        var xStart: CGFloat = width - digitWidth

        /* Layout Prefix */
        if let suffixLayer = self.suffixTextLayer {
            let preferedSize = suffixLayer.preferredFrameSize()
            suffixLayer.frame = CGRect(x: width - preferedSize.width,
                                       y: (height - preferedSize.height) / 2,
                                       width: preferedSize.width,
                                       height: preferedSize.height)
            xStart = width - preferedSize.width - digitWidth
        }

        let xOffset: CGFloat = -digitWidth - self.horizontalSpacing
        let xSeperatorOffset: CGFloat = -seperatorWidth
        var seperatorIndex = 0

        for index in self.scrollLayers.indices {
            self.scrollLayers[index].frame = CGRect(x: xStart, y: 0, width: digitWidth, height: height)
            self.textLayers[index].frame = CGRect(origin: CGPoint.zero, size: self.textLayers[index].preferredFrameSize())
            if (index + 1) % 3 == 0 {
                xStart += xSeperatorOffset
                if self.seperatorLayers.indices.contains(seperatorIndex) {
                    self.seperatorLayers[seperatorIndex].frame = CGRect(x: xStart, y: (height - digitHeight) / 2, width: seperatorWidth, height: digitHeight)
                }
                xStart += xOffset
                seperatorIndex += 1
            } else {
                xStart += xOffset
            }
        }

        /* Calculate scroll position */
        var xMin: CGFloat = 0
        var leftMostIndex = 0
        for index in self.scrollLayers.indices where index < numberString.count {
            let base = Int(truncating: pow(10, index) as NSDecimalNumber)
            let digit = number / base % 10
            self.scrollLayers[index].scroll(to: CGPoint(x: 0, y: CGFloat(digit) * digitHeight - (height - digitHeight) / 2))
            leftMostIndex = index + 1
            xMin = self.scrollLayers[index].frame.minX
        }

        /* Layout Prefix */
        if let prefixLayer = self.prefixTextLayer {
            let preferedSize = prefixLayer.preferredFrameSize()
            prefixLayer.frame = CGRect(x: xMin - preferedSize.width,
                                       y: (height - preferedSize.height) / 2,
                                       width: preferedSize.width,
                                       height: preferedSize.height)
            xMin = prefixLayer.frame.minX
        }

        /* if we have extra scroll layers that will not be used, scroll them to empty */
        while leftMostIndex < self.scrollLayers.count {
            self.scrollLayers[leftMostIndex].scroll(to: CGPoint(x: 0, y: -height))
            leftMostIndex += 1
        }

        /* Layout Content */
        if self.textAlignment == .left {
            self.contentLayer.frame = CGRect(x: -xMin, y: 0, width: width, height: height)
        } else if self.textAlignment == .center {
            let textWidth = width - xMin
            self.contentLayer.frame = CGRect(x: -(width - textWidth) / 2, y: 0, width: width, height: height)
        } else {
            self.contentLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }
    }

    override func sizeToFit() {
        let size = self.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        self.bounds = CGRect(origin: CGPoint.zero, size: size)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var wantedWidth: CGFloat = 0

        if let suffixLayer = self.suffixTextLayer {
            let preferedSize = suffixLayer.preferredFrameSize()
            wantedWidth += preferedSize.width
        }

        let digitWidth = self.singleDigitSize?.width ?? 0
        let digitHeight = self.singleDigitSize?.height ?? 0
        let seperatorWidth = self.singleDigitSize?.width ?? 0

        wantedWidth += digitWidth * CGFloat(self.scrollLayers.count)
        wantedWidth += seperatorWidth * CGFloat(self.seperatorLayers.count)

        if let prefixLayer = self.prefixTextLayer {
            let preferedSize = prefixLayer.preferredFrameSize()
            wantedWidth += preferedSize.width
        }
        return CGSize(width: min(size.width, wantedWidth),
                      height: min(size.height, digitHeight))
    }

    public func setNumber(_ number: Int, animated: Bool) {
        print("SET NUMBER", number)
        let currCount = self.textLayers.count
        let neededCount = String(number).count
        let seperatorNeededCount = Int(floor(Double(neededCount - 1) / 3))

        while self.seperatorLayers.count > seperatorNeededCount {
            self.seperatorLayers.removeLast().removeFromSuperlayer()
        }
        while self.seperatorLayers.count < seperatorNeededCount {
            let textLayer = self.obtainSeperatorLayer()
            self.seperatorLayers.append(textLayer)
            self.contentLayer.addSublayer(textLayer)
        }

        /* First try to add in more scrolllayer/textlayer if not enough */
        if currCount < neededCount {
            for _ in 0..<(neededCount - currCount) {
                let textLayer = self.obtainDigitTextLayer()
                let scrollLayer = self.obtainScrollLayer()
                self.textLayers.append(textLayer)
                self.scrollLayers.append(scrollLayer)
                scrollLayer.addSublayer(textLayer)
                self.contentLayer.addSublayer(scrollLayer)
            }
        }

        /* Render current number again without any animation */
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        self.doLayoutNumber(number: self.number)
        CATransaction.commit()

        self.number = number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if animated {
                CATransaction.begin()
                CATransaction.setAnimationDuration(self.animationDuration)
                CATransaction.setCompletionBlock {
                    self.recycleUnusedLayersIfAny()
                }
                self.doLayoutNumber(number: self.number)
                CATransaction.commit()
            } else {
                CATransaction.begin()
                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                self.doLayoutNumber(number: self.number)
                CATransaction.commit()
                self.recycleUnusedLayersIfAny()
            }
        }
    }

    private func recycleUnusedLayersIfAny() {
        let currCount = self.textLayers.count
        let neededCount = String(number).count
        if currCount > neededCount {
            for _ in 0..<(currCount - neededCount) {
                self.scrollLayers.removeLast().removeFromSuperlayer()
                let textLayer = self.textLayers.removeLast()
                textLayer.removeFromSuperlayer()
                self.recycleTextLayer(textLayer)
            }
        }
    }

    var recycledTextLayers = [CATextLayer]()

    private func recycleTextLayer(_ textLayer: CATextLayer) {
        self.recycledTextLayers.append(textLayer)
    }

    private func obtainTextLayer() -> CATextLayer {
        var textLayer: CATextLayer?
        if self.recycledTextLayers.isEmpty {
            textLayer = CATextLayer()
        } else {
            textLayer = self.recycledTextLayers.removeLast()
        }
        textLayer!.truncationMode = CATextLayerTruncationMode.middle
        textLayer!.backgroundColor = UIColor.clear.cgColor
        textLayer!.contentsScale = UIScreen.main.scale
        textLayer!.font = self.font
        textLayer!.fontSize = self.font.pointSize
        textLayer!.foregroundColor = self.textColor.cgColor
        textLayer?.alignmentMode = CATextLayerAlignmentMode.left
        return textLayer!
    }

    private func obtainDigitTextLayer() -> CATextLayer {
        let textLayer = self.obtainTextLayer()
        textLayer.string = "0\n1\n2\n3\n4\n5\n6\n7\n8\n9"
        return textLayer
    }

    private func obtainSeperatorLayer() -> CATextLayer {
        let textLayer = self.obtainTextLayer()
        textLayer.string = self.seperatorText
        return textLayer
    }

    private func obtainScrollLayer() -> CAScrollLayer {
        let scrollLayer = CAScrollLayer()
        return scrollLayer
    }
}
