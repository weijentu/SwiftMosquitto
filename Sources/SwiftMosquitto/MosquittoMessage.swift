//
//  MosquittoMessage.swift
//  SwiftMosquitto
//
//  Created by Rene Hexel on 19/11/17.
//
import Foundation
import Clibmosquitto

public class MosquittoMessage {
    let msg: UnsafePointer<mosquitto_message>
    public var topic: String { return String(cString: msg.pointee.topic) }
    public var payload: UnsafeRawPointer { return UnsafeRawPointer(msg.pointee.payload) }
    public var length: Int { return Int(msg.pointee.payloadlen) }
    public var content: String {
        let len = Int(msg.pointee.payloadlen)
        guard len > 0 else { return "" }
        let payload = msg.pointee.payload.bindMemory(to: CChar.self, capacity: len)
        guard payload[len-1] == 0 else {
            let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: len+1)
            let s = UnsafeMutableRawPointer(buffer)
            memcpy(s, msg.pointee.payload, len)
            buffer[len] = 0
            return String(bytesNoCopy: s, length: len, encoding: .utf8, freeWhenDone: true) ?? ""
        }
        return String(cString: payload)
    }

    init(message: UnsafePointer<mosquitto_message>) {
        msg = message
    }

    deinit {
        var msg: UnsafeMutablePointer<mosquitto_message>? = UnsafeMutablePointer(mutating: self.msg)
        mosquitto_message_free(&msg)
    }

    /// Clone a MosquittoMessage
    ///
    /// - Parameter other: message to copy
    public convenience init(_ other: MosquittoMessage) {
        let ptr = UnsafeMutablePointer<mosquitto_message>.allocate(capacity: 1)
        mosquitto_message_copy(ptr, other.msg)
        self.init(message: ptr)
    }
}
