import Foundation

public enum WebBluetoothJavaScript {
    public static var injectSource: String {
        guard let filepath = Bundle.module.path(forResource: "inject", ofType: "js"),
              let js = try? String(contentsOfFile: filepath) else {
            return ""
        }
        return js
    }
}
