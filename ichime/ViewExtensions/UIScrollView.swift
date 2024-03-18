import UIKit

/// Disable clipping content by ScrollView
extension UIScrollView {
    override open var clipsToBounds: Bool {
        get { false }
        set {}
    }
}
