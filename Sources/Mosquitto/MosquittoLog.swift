//
//  MosquittoLog.swift
//  SwiftMosquitto
//
//  Created by Rene Hexel on 19/11/17.
//
import Clibmosquitto

public typealias MosquittoLogLevel = CInt
public extension MosquittoLogLevel {
    public static let info = MOSQ_LOG_INFO
    public static let notice = MOSQ_LOG_NOTICE
    public static let warning = MOSQ_LOG_WARNING
    public static let error = MOSQ_LOG_ERR
    public static let debug = MOSQ_LOG_DEBUG
}
