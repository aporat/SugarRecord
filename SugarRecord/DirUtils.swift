import Foundation

extension String {
    static var documentDirectory: String {
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    }
}
