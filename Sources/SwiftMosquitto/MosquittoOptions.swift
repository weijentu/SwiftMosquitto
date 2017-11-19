//
//  MosquittoOptions.swift
//  SwiftMosquitto
//
//  Created by Rene Hexel on 19/11/17.
//
import Clibmosquitto

/// MQTT protocol version
public typealias MQTTProtocolVersion = CInt

public extension MQTTProtocolVersion {
    public static let v31 = MQTT_PROTOCOL_V31
    public static let v311 = MQTT_PROTOCOL_V311
}

public extension mosq_opt_t {
    public static let mqttProtocol = MOSQ_OPT_PROTOCOL_VERSION
}
