import Foundation
import Clibmosquitto

public class Mosquitto {
    static var initialisationStatus = mosquitto_lib_init()
    let mosquitto: OpaquePointer!
    public var connectionCallback: (ConnectionStatus) -> Void = { _ in }
    public var disconnectionCallback: (ConnectionStatus) -> Void = { _ in }
    public var publishCallback: (MessageId) -> Void = { _ in }
    public var subscribeCallback: (MessageId, UnsafeBufferPointer<CInt>) -> Void = { _, _ in }
    public var unsubscribeCallback: (MessageId) -> Void = { _ in }
    public var messageCallback: (MosquittoMessage) -> Void = { _ in }
    public var logCallback: (MosquittoLogLevel, UnsafePointer<CChar>) -> Void = { _, _ in }

    /// Create a new Mosquitto client instance
    ///
    /// - Parameters:
    ///   - id: client ID to use (if `nil`, a random client will be used and `cleanOnDisconnect` must be `true`).
    ///   - cleanOnDisconnect: whether to clean all messages and subscriptions on disconnect.
    public init(id: UnsafePointer<CChar>? = nil, cleanOnDisconnect: Bool = true) {
        precondition(cleanOnDisconnect || id != nil)
        mosquitto = mosquitto_new(id, cleanOnDisconnect, nil)
        let this = Unmanaged.passUnretained(self).toOpaque()
        mosquitto_user_data_set(mosquitto, this)
        mosquitto_connect_callback_set(mosquitto) {
            guard let ptr = UnsafeRawPointer($1) else { return }
            let this = Unmanaged<Mosquitto>.fromOpaque(ptr).takeUnretainedValue()
            assert(this.mosquitto == $0)
            this.connectionCallback($2)
        }
        mosquitto_disconnect_callback_set(mosquitto) {
            guard let ptr = UnsafeRawPointer($1) else { return }
            let this = Unmanaged<Mosquitto>.fromOpaque(ptr).takeUnretainedValue()
            assert(this.mosquitto == $0)
            this.disconnectionCallback($2)
        }
        mosquitto_publish_callback_set(mosquitto) {
            guard let ptr = UnsafeRawPointer($1) else { return }
            let this = Unmanaged<Mosquitto>.fromOpaque(ptr).takeUnretainedValue()
            assert(this.mosquitto == $0)
            this.publishCallback($2)
        }
        mosquitto_subscribe_callback_set(mosquitto) {
            guard let ptr = UnsafeRawPointer($1) else { return }
            let this = Unmanaged<Mosquitto>.fromOpaque(ptr).takeUnretainedValue()
            assert(this.mosquitto == $0)
            this.subscribeCallback($2, UnsafeBufferPointer(start: $4, count: Int($3)))
        }
        mosquitto_unsubscribe_callback_set(mosquitto) {
            guard let ptr = UnsafeRawPointer($1) else { return }
            let this = Unmanaged<Mosquitto>.fromOpaque(ptr).takeUnretainedValue()
            assert(this.mosquitto == $0)
            this.unsubscribeCallback($2)
        }
        mosquitto_message_callback_set(mosquitto) {
            guard let ptr = UnsafeRawPointer($1), let msg = $2 else { return }
            let this = Unmanaged<Mosquitto>.fromOpaque(ptr).takeUnretainedValue()
            assert(this.mosquitto == $0)
            this.messageCallback(MosquittoMessage(message: msg))
        }
        mosquitto_log_callback_set(mosquitto) {
            guard let ptr = UnsafeRawPointer($1), let msg = $3 else { return }
            let this = Unmanaged<Mosquitto>.fromOpaque(ptr).takeUnretainedValue()
            assert(this.mosquitto == $0)
            this.logCallback($2, msg)
        }
    }

    deinit {
        mosquitto_destroy(mosquitto)
    }

    /// Reuse client with a new connection.
    ///
    /// - Parameters:
    ///   - id: new connection ID (if `nil`, a random client will be used and `cleanOnDisconnect` must be `true`)
    ///   - cleanOnDisconnect: whether to clean all messages and subscriptions on disconnect.
    /// - Returns: `.success` if successful, `.invalid` if the input parameters were invalid, or `.noMemory` if an out-of-memory condition occurred.
    @discardableResult
    public func reinitialise(id: UnsafePointer<CChar>? = nil, cleanOnDisconnect: Bool = true) -> MosquittoError {
        let rv = mosquitto_reinitialise(mosquitto, id, cleanOnDisconnect, Unmanaged.passUnretained(self).toOpaque())
        return MosquittoError(rawValue: rv)
    }

    /// Configure will information for a mosquitto instance.  By default, clients do not have a will.  This must be called before calling `connect()`.
    ///
    /// - Parameters:
    ///   - topic: the topic representing the will
    ///   - payload: payload to use
    ///   - length: size of the payload in bytes (string length if `nil`)
    ///   - qos: value 0, 1 or 2 indicating the Quality of Service to be used for the will.
    ///   - lastWill: retain this payload as the last will for the topic
    /// - Returns: `.success` if successful, `.invalid` if the input parameters were invalid, `.noMemory` if an out-of-memory condition occurred, `.payloadSize` if the payload is too large.
    @discardableResult
    public func set(will topic: UnsafePointer<CChar>, payload: UnsafePointer<CChar>, length: Int? = nil, qos: MosquittoQoS = .atMostOnce, retain lastWill: Bool = false) -> MosquittoError {
        let len = CInt(length ?? strlen(payload))
        let rv = mosquitto_will_set(mosquitto, topic, len, payload, qos.rawValue, lastWill)
        return MosquittoError(rawValue: rv)
    }

    /// Remove a previously configured will.  This must be called before calling `connect()`.
    ///
    /// - Returns: `.success` if successful, `.invalid` if the input parameters were invalid.
    @discardableResult
    public func clearWill() -> MosquittoError {
        let rv = mosquitto_will_clear(mosquitto)
        return MosquittoError(rawValue: rv)
    }

    /// Configure username and password.
    /// This is only supported by brokers that implement the MQTT spec v3.1.
    /// By default, no username or password will be sent.
    /// This must be called before calling `connect()`.
    ///
    /// - Parameters:
    ///   - username: the user name to send (`nil` to disable authentication)
    ///   - password: the password to send (`nil` to only send a user name, but no password)
    /// - Returns: `.success` if successful, `.invalid` if the input parameters were invalid, or `.noMemory` if an out-of-memory condition occurred.
    @discardableResult
    public func set(username: UnsafePointer<CChar>?, password: UnsafePointer<CChar>?) -> MosquittoError {
        let rv = mosquitto_username_pw_set(mosquitto, username, password)
        return MosquittoError(rawValue: rv)
    }

    /// Connect to MQTT broker.
    ///
    /// - Parameters:
    ///   - host: broker host name or IP address to connect to.
    ///   - port: network port to connect to.
    ///   - interval: keep-alive interval for sending PING messages
    /// - Throws: `.invalid` if the input parameters were invalid, or `.errno` if a a system error occurred
    public func connect(to host: UnsafePointer<CChar>, port: Int = 1883, keepAlive interval: Int = 120) throws {
        let rv = mosquitto_connect(mosquitto, host, CInt(port), CInt(interval))
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// Connect to an MQTT broker, binding to a specific interface address.
    ///
    /// - Parameters:
    ///   - host: broker host name or IP address to connect to.
    ///   - port: network port to connect to.
    ///   - interval: keep-alive interval for sending PING messages
    ///   - address: interface address to bind to
    /// - Throws: `.invalid` if the input parameters were invalid, or `.errno` if a a system error occurred
    public func connect(to host: UnsafePointer<CChar>, port: Int = 1883, keepAlive interval: Int = 120, bindTo address: UnsafePointer<CChar>) throws {
        let rv = mosquitto_connect_bind(mosquitto, host, CInt(port), CInt(interval), address)
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// Asynchronously connect to an MQTT broker.
    ///
    /// - Parameters:
    ///   - host: broker host name or IP address to connect to.
    ///   - port: network port to connect to.
    ///   - interval: keep-alive interval for sending PING messages
    /// - Thows: `.invalid` if the input parameters were invalid, or `.errno` if a system error occurred
    public func connectAsync(to host: UnsafePointer<CChar>, port: Int = 1883, keepAlive interval: Int = 120) throws {
        let rv = mosquitto_connect_async(mosquitto, host, CInt(port), CInt(interval))
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// Asynchrounously connect to an MQTT broker, binding to a specific interface address.
    ///
    /// - Parameters:
    ///   - host: broker host name or IP address to connect to.
    ///   - port: network port to connect to.
    ///   - interval: keep-alive interval for sending PING messages
    ///   - address: interface address to bind to
    /// - Throws: `.invalid` if the input parameters were invalid, or `.errno` if a system error occurred
    public func connectAsync(to host: UnsafePointer<CChar>, port: Int = 1883, keepAlive interval: Int = 120, bindTo address: UnsafePointer<CChar>) throws {
        let rv = mosquitto_connect_bind_async(mosquitto, host, CInt(port), CInt(interval), address)
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// Asynchrounously connect to MQTT server on the default port, binding to a specific interface address.
    ///
    /// - Parameters:
    ///   - host: broker host name or IP address to connect to.
    ///   - interval: keep-alive interval for sending PING messages
    ///   - address: interface address to bind to
    /// - Returns: `.success` if successful, `.invalid` if the input parameters were invalid, or `.errno` if a system error occurred
    public func connectSrv(to host: UnsafePointer<CChar>, keepAlive interval: Int = 120, bindTo address: UnsafePointer<CChar>) throws {
        let rv = mosquitto_connect_srv(mosquitto, host, CInt(interval), address)
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// Reconnect to a broker after disconnection.
    /// Must not be called before `connect()`.
    ///
    /// - Returns: `.success` if successful, `.invalid` if the input parameters were invalid, or `.errno` if a system error occurred
    public func reconnect() throws {
        let rv = mosquitto_reconnect(mosquitto)
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// Asynchronously reconnect to a broker after disconnection.
    /// Must not be called before `connect()`.
    ///
    /// - Returns: `.success` if successful, `.invalid` if the input parameters were invalid, or `.errno` if a a system error occurred
    public func reconnectAsync() throws {
        let rv = mosquitto_reconnect_async(mosquitto)
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// Disconnect from the broker.
    /// Must not be called before `connect()`.
    ///
    /// - Returns: `.success` if successful, `.invalid` if the input parameters were invalid, or `.noConnect` if the client is not connected
    @discardableResult
    public func disconnect() -> MosquittoError {
        let rv = mosquitto_reconnect(mosquitto)
        return MosquittoError(rawValue: rv)
    }

    /// Publish a message on a given topic.
    ///
    /// - Parameters:
    ///   - topic: the topic to publish.
    ///   - payload: message content.
    ///   - length: message length (`strlen(payload)` if `nil`)
    ///   - qos: quality of service to be used
    ///   - lastWill: retain the message as last will if true
    /// - Returns: ID of the message to be published
    /// - Throws: `.invalid` if the input parameters were invalid, `.noMemory` if an out-of-memory condition occurred, `.payloadSize` if the payload is too large.
    @discardableResult
    public func publish(topic: UnsafePointer<CChar>, payload: UnsafePointer<CChar>, length: Int? = nil, qos: MosquittoQoS = .atMostOnce, retain lastWill: Bool = false) throws -> MessageId {
        var message_id = MessageId(-1)
        let len = CInt(length ?? strlen(payload))
        let rv = mosquitto_publish(mosquitto, &message_id, topic, len, payload, qos.rawValue, lastWill)
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
        return message_id
    }

    /// Subscribe to a given topic pattern.
    ///
    /// - Parameters:
    ///   - pattern: the topic pattern to subscribe to.
    ///   - qos: quality of service to be used
    /// - Returns: ID of the subscription message
    /// - Throws: `.invalid` if the input parameters were invalid, `.noMemory` if an out-of-memory condition occurred, `.payloadSize` if the payload is too large.
    @discardableResult
    public func subscribe(to pattern: UnsafePointer<CChar>, qos: MosquittoQoS = .atMostOnce) throws -> MessageId {
        var message_id = MessageId(-1)
        let rv = mosquitto_subscribe(mosquitto, &message_id, pattern, qos.rawValue)
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
        return message_id
    }

    /// Unsubscribe from a given topic pattern.
    ///
    /// - Parameters:
    ///   - pattern: the topic pattern to subscribe to.
    /// - Returns: ID of the unsubscribe message
    /// - Throws: `.invalid` if the input parameters were invalid, `.noMemory` if an out-of-memory condition occurred, `.payloadSize` if the payload is too large.
    @discardableResult
    public func unsubscribe(from pattern: UnsafePointer<CChar>) throws -> MessageId {
        var message_id = MessageId(-1)
        let rv = mosquitto_unsubscribe(mosquitto, &message_id, pattern)
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
        return message_id
    }

    /// The main network loop for the client.
    /// This must be called frequently in order to keep communication between the client and broker working.
    /// This calls select() to monitor the client network socket.
    /// See `loopStart()` as an alternative to run the client loop in its own thread.
    /// If you want to integrate the mosquitto client operation with your own select() call,
    /// `socket`, `loopRead()`, `loopWrite()`, and/or `loopMisc()`.
    ///
    /// - Parameters:
    ///   - timeout: number of milliseconds (maximum) to wait (Use `0` for an instant return or use a negative value for the mosquitto default timeout)
    ///   - maxPackets: unused, use 1 for future compatibility
    /// - Throws: `.invalid` if the input parameters were invalid `.noMemory` if an out-of-memory condition occurred, `.noConnect` if the client is not connected to a broker, `.connectionLost` if the client lost its connection, `.protocol` if a communication protocol error occurred, or `.errno` if a system error occurred
    public func loop(timeout: Int = -1, maxPackets: Int = 1) throws {
        let rv = mosquitto_loop(mosquitto, CInt(timeout), CInt(maxPackets))
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// The main network loop for the client.
    /// This calls `loop()` forenver in an infinite, blocking loop.
    /// See `loopStart()` as an alternative to run the client loop in its own thread.
    /// If you want to integrate the mosquitto client operation with your own select() call,
    /// `socket()`, `loopRead()`, `loopWrite()`, and/or `loopMisc()`.
    ///
    /// - Parameters:
    ///   - timeout: number of milliseconds (maximum) to wait (Use `0` for an instant return or use a negative value for the mosquitto default timeout)
    ///   - maxPackets: unused, use 1 for future compatibility
    /// - Returns: `.invalid` if the input parameters were invalid `.noMemory` if an out-of-memory condition occurred, `.noConnect` if the client is not connected to a broker, `.connectionLost` if the client lost its connection, `.protocol` if a communication protocol error occurred, or `.errno` if a system error occurred
    public func loopForever(timeout: Int = -1, maxPackets: Int = 1) -> MosquittoError {
        let rv = mosquitto_loop(mosquitto, CInt(timeout), CInt(maxPackets))
        return MosquittoError(rawValue: rv)
    }

    /// Indicates thread support
    var threaded: Bool = false

    /// Start a new thread to process network traffic
    ///
    /// - Throws: `.invalid` if the input parameters were invalid or `.notSupported` if thread support is not available
    public func loopStart() throws {
        threaded = true
        let rv = mosquitto_loop_start(mosquitto)
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// Stop network thread
    ///
    /// - Parameters:
    ///   - force: set to `true` to force thread cancellation.  If `false`, mosquitto_disconnect must have already been called.
    /// - Throws: `.invalid` if the input parameters were invalid or `.notSupported` if thread support is not available
    public func loopStop(force: Bool = true) throws {
        let rv = mosquitto_loop_stop(mosquitto, force)
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// Carry out a network read operation.
    /// This should only be used if you are not using `loop()` and are monitoring
    /// the client network socket for activity yourself.
    ///
    /// - Parameters:
    ///   - maxPackets: unused, use 1 for future compatibility
    /// - Throws: `.invalid` if the input parameters were invalid `.noMemory` if an out-of-memory condition occurred, `.noConnect` if the client is not connected to a broker, `.connectionLost` if the client lost its connection, `.protocol` if a communication protocol error occurred, or `.errno` if a system error occurred
    public func loopRead(maxPackets: Int = 1) throws {
        let rv = mosquitto_loop_read(mosquitto, CInt(maxPackets))
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// Carry out a network write operation.
    /// This should only be used if you are not using `loop()` and are monitoring
    /// the client network socket for activity yourself.
    ///
    /// - Parameters:
    ///   - maxPackets: unused, use 1 for future compatibility
    /// - Throws: `.invalid` if the input parameters were invalid `.noMemory` if an out-of-memory condition occurred, `.noConnect` if the client is not connected to a broker, `.connectionLost` if the client lost its connection, `.protocol` if a communication protocol error occurred, or `.errno` if a system error occurred
    public func loopWrite(maxPackets: Int = 1) throws {
        let rv = mosquitto_loop_write(mosquitto, CInt(maxPackets))
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// Carry out miscellaneous network operations.
    /// This should only be used if you are not using `loop()` and are monitoring
    /// the client network socket for activity yourself.
    ///
    /// - Parameters:
    ///   - maxPackets: unused, use 1 for future compatibility
    /// - Throws: `.invalid` if the input parameters were invalid `.noMemory` if an out-of-memory condition occurred, `.noConnect` if the client is not connected to a broker, `.connectionLost` if the client lost its connection, `.protocol` if a communication protocol error occurred, or `.errno` if a system error occurred
    public func loopMisc() throws {
        let rv = mosquitto_loop_misc(mosquitto)
        guard rv == 0 else { throw MosquittoError(rawValue: rv) }
    }

    /// Socket file handle for the receiver.
    /// Useful if you want to include a mosquitto client in your own `select()` calls.
    public var socket: CInt { return mosquitto_socket(mosquitto) }

    /// `true` if there are data ready to be written to the socket
    public var wantWrite: Bool { return mosquitto_want_write(mosquitto) }

    /// Set to `true` to activate thread support
    public var isThreaded: Bool {
        get { return threaded }
        set {
            threaded = newValue
            mosquitto_threaded_set(mosquitto, threaded)
        }
    }

    /// MQTT protocol version
    public var mqttProtocol: MQTTProtocolVersion = .v31 {
        didSet {
            mosquitto_opts_set(mosquitto, .mqttProtocol, UnsafeMutableRawPointer(&mqttProtocol))
        }
    }
}
