import UIKit


class OdometerLabel: UIView {

    private static let digits = "0\n1\n2\n3\n4\n5\n6\n7\n8\n9\n0\n1\n2\n3\n4\n5\n6\n7\n8\n9\n0\n1\n2\n3\n4\n5\n6\n7\n8\n9"

    /* Customization

     1. Animation Duration
     2. Text Alignment, left, right or center
     3. Font
     4. Text Color
     5. Horizontal Spacing
     */
    var animationDuration: TimeInterval = 0.5

    var textAlignment: NSTextAlignment = .center {
        didSet {
            self.setNumber(self.number, animated: false)
        }
    }

    var font: UIFont = UIFont.systemFont(ofSize: 20) {
        didSet {
            /* Measure single digit size */
            let attributes = [NSAttributedString.Key.font: self.font]
            let attributedText = NSAttributedString(string: OdometerLabel.digits,
                                                    attributes: attributes)
            let textLayer = self.obtainDigitTextLayer()
            textLayer.font = self.font
            textLayer.fontSize = self.font.pointSize
            textLayer.contentsScale = UIScreen.main.scale

            let size = attributedText.size()
            let preferedSize = textLayer.preferredFrameSize()
            self.singleDigitSize = CGSize(width: size.width, height: preferedSize.height / 30)
            self.recycleTextLayer(textLayer)

            for layer in self.digitLayers {
                layer.font = self.font
                layer.fontSize = self.font.pointSize
            }

            for layer in self.textLayers {
                layer.font = self.font
                layer.fontSize = self.font.pointSize
            }

            self.setNumber(self.number, animated: false)
        }
    }

    var textColor: UIColor = UIColor.red {
        didSet {
            for layer in self.digitLayers {
                layer.foregroundColor = self.textColor.cgColor
            }
            for textLayer in self.textLayers {
                textLayer.foregroundColor = self.textColor.cgColor
            }
            self.setNumber(self.number, animated: false)
        }
    }

    var horizontalSpacing: CGFloat = 0 {
        didSet {
            self.setNumber(self.number, animated: false)
        }
    }

    /* Private attributes */

    private(set) var number: String = "0"
    private(set) var contentLayer = CALayer()

    /* Digit layer must be wrapped inside scroll layer,
     scroll layer will have 1-1 relationship to digit layer */
    private var scrollLayers = [OLScrollLayer]()
    private var digitLayers = [CATextLayer]()
    private var textLayers = [CATextLayer]()

    /* All Layers in order */
    private var allLayers = [CALayer]()

    /* Each digit size, measured when font is set */
    private var singleDigitSize: CGSize?

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
        self.layer.masksToBounds = true
        self.contentLayer.masksToBounds = true
        self.font = UIFont.systemFont(ofSize: 20)
        self.setNumber(self.number, animated: false)
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        self.doLayoutNumber()
        self.calculateScrollPositions(animationMode: false)
    }

    override func sizeToFit() {
        let size = self.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        self.bounds = CGRect(origin: CGPoint.zero, size: size)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var wantedWidth: CGFloat = 0

        let digitWidth = self.singleDigitSize?.width ?? 0
        let digitHeight = self.singleDigitSize?.height ?? 0

        wantedWidth += digitWidth * CGFloat(self.scrollLayers.count)
        for textLayer in self.textLayers {
            wantedWidth += textLayer.preferredFrameSize().width
        }
        wantedWidth += CGFloat(self.allLayers.count - 1) * self.horizontalSpacing
        return CGSize(width: min(size.width, wantedWidth),
                      height: min(size.height, digitHeight))
    }

    private func doLayoutNumber(measureSize: Int? = nil) {
        let width = layer.bounds.width
        let height = layer.bounds.height

        let digitHeight = self.singleDigitSize?.height ?? 0
        /* Layout all layers */
        var xStart: CGFloat = width
        var xMin: CGFloat = 0
        for index in self.allLayers.indices {
            let layerSize = self.sizeForLayer(self.allLayers[index])
            self.allLayers[index].frame = CGRect(x: xStart - layerSize.width,
                                                 y: (digitHeight - layerSize.height) / 2,
                                                 width: layerSize.width,
                                                 height: layerSize.height)
            xStart -= self.horizontalSpacing
            xStart -= layerSize.width
            /* for animation */
            if index < (measureSize ?? Int.max) {
                xMin = xStart
            }
        }
        /* Layout Content based on alignment */
        if self.textAlignment == .left {
            self.contentLayer.frame = CGRect(x: -xMin,
                                             y: (height - digitHeight) / 2,
                                             width: width,
                                             height: digitHeight)
        } else if self.textAlignment == .center {
            let textWidth = width - xMin
            self.contentLayer.frame = CGRect(x: -(width - textWidth) / 2,
                                             y: (height - digitHeight) / 2,
                                             width: width,
                                             height: digitHeight)
        } else {
            self.contentLayer.frame = CGRect(x: 0,
                                             y: (height - digitHeight) / 2,
                                             width: width,
                                             height: digitHeight)
        }
    }

    private func calculateScrollPositions(animationMode: Bool) {
        let height = layer.bounds.height

        /* Calculate scroll position */
        let numbersOnly = Array(self.number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
        var layerIndex = 0

        let digitHeight = self.singleDigitSize?.height ?? 0
        while layerIndex >= 0 && layerIndex < numbersOnly.count {
            let digit = Int(String(numbersOnly[numbersOnly.count - layerIndex - 1]))!
            var yPos = CGFloat(digit) * digitHeight - (height - digitHeight) / 2

            if animationMode {
                let topPos = yPos
                let bottom = yPos + digitHeight * 20
                let center = yPos + digitHeight * 10
                let curr = self.scrollLayers[layerIndex].contentOffset.y
                if abs(topPos - curr) < abs(bottom - curr) && abs(topPos - curr) < abs(center - curr) {
                    yPos = topPos
                } else if abs(bottom - curr) < abs(topPos - curr) && abs(bottom - curr) < abs(center - curr) {
                    yPos = bottom
                } else {
                    yPos = center
                }
            } else {
                yPos += digitHeight * 10
            }

            self.scrollLayers[layerIndex].scroll(to: CGPoint(x: 0, y: yPos))
            layerIndex += 1
        }

        /* For any scroll layer not used, scroll to blank */
        while layerIndex < self.scrollLayers.count {
            self.scrollLayers[layerIndex].scroll(to: CGPoint(x: 0, y: -height))
            layerIndex += 1
        }
    }

    /* Get size for given layer */
    private func sizeForLayer(_ layer: CALayer) -> CGSize {
        if let scrollLayer = layer as? CAScrollLayer {
            /* It's a digit */
            if let digitLayer = scrollLayer.sublayers?.first {
                digitLayer.frame = CGRect(x: 0,
                                          y: 0,
                                          width: self.singleDigitSize?.width ?? 0,
                                          height: (self.singleDigitSize?.height ?? 0) * 30)
            }
            return CGSize(width: self.singleDigitSize?.width ?? 0,
                          height: self.bounds.height)
        } else if let textLayer = layer as? CATextLayer {
            /* It's a text */
            return textLayer.preferredFrameSize()
        }
        return CGSize.zero
    }

    public func setNumber(_ number: String, animated: Bool) {
        let result = decode_segments(from: number)

        /* Remove any extra text layers */
        while self.textLayers.count > result.textCount {
            let last = self.textLayers.removeLast()
            last.removeFromSuperlayer()
        }
        /* Add in any missing text layers */
        while self.textLayers.count < result.textCount {
            let textLayer = self.obtainTextLayer()
            self.textLayers.append(textLayer)
            self.contentLayer.addSublayer(textLayer)
        }

        /* Add in any missing digit layer (wrapped inside scroll layer) */
        if self.scrollLayers.count < result.digitCount {
            for _ in 0..<(result.digitCount - self.scrollLayers.count) {
                let digitLayer = self.obtainDigitTextLayer()
                let scrollLayer = self.obtainScrollLayer()
                self.digitLayers.append(digitLayer)
                self.scrollLayers.append(scrollLayer)
                scrollLayer.addSublayer(digitLayer)
                self.contentLayer.addSublayer(scrollLayer)
            }
        }

        /* Reorder all layers */
        self.allLayers.removeAll()
        var posDigit = 0
        var posText = 0
        for segment in result.segments.reversed() {
            if segment.isDigit {
                self.allLayers.append(self.scrollLayers[posDigit])
                posDigit += 1
            } else {
                self.textLayers[posText].string = segment.content
                self.allLayers.append(self.textLayers[posText])
                posText += 1
            }
        }

        while posDigit < self.scrollLayers.count {
            self.allLayers.append(self.scrollLayers[posDigit])
            posDigit += 1
        }

        if animated {
            /* Render current number again without any animation */
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            let currResult = decode_segments(from: self.number)
            self.doLayoutNumber(measureSize: currResult.digitCount + currResult.textCount)
            self.calculateScrollPositions(animationMode: false)
            CATransaction.commit()

            self.number = number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                CATransaction.begin()
                CATransaction.setAnimationDuration(self.animationDuration)
                CATransaction.setCompletionBlock {
                    self.recycleUnusedLayersIfAny()

                    /* Move scroll position back to center */
                    CATransaction.begin()
                    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                    self.calculateScrollPositions(animationMode: false)
                    CATransaction.commit()
                }
                self.doLayoutNumber(measureSize: result.digitCount + result.textCount)
                self.calculateScrollPositions(animationMode: true)
                CATransaction.commit()
            }
        } else {
            self.number = number
            for layer in self.allLayers {
                layer.opacity = 0
            }
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            CATransaction.setCompletionBlock {
                for layer in self.allLayers {
                    layer.opacity = 1
                }
            }
            self.doLayoutNumber(measureSize: result.digitCount + result.textCount)
            self.calculateScrollPositions(animationMode: false)
            CATransaction.commit()
            self.recycleUnusedLayersIfAny()
        }
    }

    private func recycleUnusedLayersIfAny() {
        let result = decode_segments(from: self.number)
        let currCount = self.scrollLayers.count
        let neededCount = result.digitCount
        if currCount > neededCount {
            for _ in 0..<(currCount - neededCount) {
                let last = self.digitLayers.removeLast()
                last.removeFromSuperlayer()
                let lastScroll = self.scrollLayers.removeLast()
                lastScroll.removeFromSuperlayer()
                self.allLayers.removeAll(where: {$0 == lastScroll})
                self.recycleTextLayer(last)
            }
        }
    }

    /* Text Layer Management */

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
        //        textLayer!.truncationMode = kCATruncationMiddle
        textLayer!.backgroundColor = UIColor.clear.cgColor
        textLayer!.contentsScale = UIScreen.main.scale
        textLayer!.font = self.font
        textLayer!.fontSize = self.font.pointSize
        textLayer!.foregroundColor = self.textColor.cgColor
        textLayer?.alignmentMode = .center
        return textLayer!
    }

    private func obtainDigitTextLayer() -> CATextLayer {
        let textLayer = self.obtainTextLayer()
        textLayer.string = OdometerLabel.digits
        return textLayer
    }

    private func obtainScrollLayer() -> OLScrollLayer {
        let scrollLayer = OLScrollLayer()
        return scrollLayer
    }
}

private let digits = CharacterSet.decimalDigits

private class OLScrollLayer: CAScrollLayer {
    var contentOffset = CGPoint.zero

    override func scroll(to point: CGPoint) {
        super.scroll(to: point)
        self.contentOffset = point
    }
}

private struct Segment {
    var content: String
    var isDigit: Bool
}

private func decode_segments(from: String) -> (segments: [Segment], digitCount: Int, textCount: Int) {
    var segments = [Segment]()
    var curr = ""
    var digitCount = 0
    var textCount = 0
    for char in from.unicodeScalars {
        if digits.contains(char) {
            if !curr.isEmpty {
                segments.append(Segment(content: curr,
                                        isDigit: false))
                curr = ""
                textCount += 1
            }
            segments.append(Segment(content: String(char),
                                    isDigit: true))
            digitCount += 1
        } else {
            curr += String(char)
        }
    }
    if !curr.isEmpty {
        segments.append(Segment(content: curr, isDigit: false))
        textCount += 1
    }
    return (segments: segments, digitCount: digitCount, textCount: textCount)
}
