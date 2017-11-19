//
//  ConnectionStatus.swift
//  SwiftMosquitto
//
//  Created by Rene Hexel on 19/11/17.
//
public typealias ConnectionStatus = CInt
public extension ConnectionStatus {
    public static let success = ConnectionStatus(0)
    public static let unacceptableProtocol = ConnectionStatus(1)
    public static let identifierReject = ConnectionStatus(2)
}

public typealias DisconnectionStatus = CInt
public extension DisconnectionStatus {
    public static let disconnected = DisconnectionStatus(0)
}

public typealias MessageId = CInt

