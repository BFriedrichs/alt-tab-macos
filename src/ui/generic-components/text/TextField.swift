import Cocoa

class TextField: NSTextField {
    let insets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    convenience init(_ attributedString: NSAttributedString) {
        self.init(labelWithAttributedString: TextField.forceLeftToRight(attributedString))
    }

    // we know the content to display should be left-to-right, so we force it to avoid displayed it right-to-left
    static func forceLeftToRight(_ attributedString: NSAttributedString) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.baseWritingDirection = .leftToRight
        let forced = NSMutableAttributedString(attributedString: attributedString)
        forced.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: forced.length))
        return forced
    }

    // NSTextField has 2px insets left and right by default; we remove those
    override var alignmentRectInsets: NSEdgeInsets { insets }
}
