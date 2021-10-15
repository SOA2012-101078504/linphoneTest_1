
import linphonesw

enum LinphoneError: Error {
	case timeout
	case loggingServiceUninitialized
}

class LinphoneLoggingServiceManager: LoggingServiceDelegate {
	init(config: Config, log: LoggingService?, domain: String) throws {
		if let log = log {
			let debugLevel = config.getInt(section: "app", key: "debugenable_preference", defaultValue: LogLevel.Debug.rawValue)
			let debugEnabled = (debugLevel >= LogLevel.Debug.rawValue && debugLevel < LogLevel.Error.rawValue)

			Factory.Instance.logCollectionPath = Factory.Instance.getDownloadDir(context: UnsafeMutablePointer<Int8>(mutating: (APP_GROUP_ID as NSString).utf8String))
			Factory.Instance.enableLogCollection(state: debugEnabled ? LogCollectionState.Enabled : LogCollectionState.Disabled)
			log.domain = domain
			log.logLevel = debugLevel==0 ? LogLevel.Fatal : LogLevel(rawValue: debugLevel)
			log.addDelegate(delegate: self)
		} else {
			throw LinphoneError.loggingServiceUninitialized
		}
	}

	func onLogMessageWritten(logService: LoggingService, domain: String, level: LogLevel, message: String) {
		let levelStr: String

		switch level {
		case .Debug:
			levelStr = "Debug"
		case .Trace:
			levelStr = "Trace"
		case .Message:
			levelStr = "Message"
		case .Warning:
			levelStr = "Warning"
		case .Error:
			levelStr = "Error"
		case .Fatal:
			levelStr = "Fatal"
		default:
			levelStr = "unknown"
		}

		NSLog("\(levelStr) [\(domain)] \(message)\n")
	}
}
