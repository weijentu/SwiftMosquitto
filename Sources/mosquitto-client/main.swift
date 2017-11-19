import Foundation
import Mosquitto

let args = CommandLine.arguments
let cmd = args[0]                   ///< command name
var name = convert(cmd, using: basename)
var broker = "192.168.1.3"
var port = 1883
if let host = getenv("MQTT_HOST") {
    broker = String(cString: host)
}

fileprivate func usage() -> Never {
    print("Usage: \(cmd) [options] <subscription_topics>")
    print("options are:")
    print("  -h <broker>        MQTT broker [\(broker)]")
    print("  -p <port>          MQTT port [\(port)]")
    exit(EXIT_FAILURE)
}

while let result = get(options: "h:p:") {
    let option = result.0
    let arg = result.1
    switch option {
    case "h": broker = arg!
    case "p": if let p = Int(arg!) {
        port = p
    } else { usage() }
    default: usage()
    }
}

let optInd = Int(optind)
guard optInd + 1 == args.count else { usage() }
let topics = args[optInd]

let mosquitto = Mosquitto(id: name)
mosquitto.logCallback = { logLevel, logMessage in
    print("\(logLevel): \(String(cString: logMessage))")
}
mosquitto.subscribeCallback = { msgID, subscriptions in
    var qos: [String] = []
    for i in 0..<subscriptions.count {
        qos.append("QoS: \(subscriptions[i])")
    }
    print("Got subscription \(msgID): \(qos)")
}
do {
    try mosquitto.connect(to: broker, port: port)
    try mosquitto.subscribe(to: topics)
} catch {
    print("Caught exception: \(error)")
}
var status: MosquittoError
repeat {
    status = mosquitto.loopForever()
} while (status == .success)
exit(status.rawValue)
