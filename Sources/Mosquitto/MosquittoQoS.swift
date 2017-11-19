//
//  MosquittoQoS.swift
//  SwiftMosquitto
//
//  Created by Rene Hexel on 19/11/17.
//

/// MQTT Quality of service
///
/// - atMostOnce: message will be attempted to be delivered once, with no confirmation.
/// - atLeastOnce: message will be delivered at least once until confirmed.
/// - exactlyOnce: message will be delivered exactly once using a four-step handshake.
public enum MosquittoQoS: CInt, RawRepresentable {
    case atMostOnce = 0
    case atLeastOnce = 1
    case exactlyOnce = 2
}
