//
//  MosquittoError.swift
//  SwiftMosquitto
//
//  Created by Rene Hexel on 19/11/17.
//

import Clibmosquitto

extension mosq_err_t: Error {
    public static let connectionPending = MOSQ_ERR_CONN_PENDING
    public static let success = MOSQ_ERR_SUCCESS
    public static let noMemory = MOSQ_ERR_NOMEM
    public static let protocolError = MOSQ_ERR_PROTOCOL
    public static let invalid = MOSQ_ERR_INVAL
    public static let noConnection = MOSQ_ERR_NO_CONN
    public static let connectionRefused = MOSQ_ERR_CONN_REFUSED
    public static let notFound = MOSQ_ERR_NOT_FOUND
    public static let connectionLost = MOSQ_ERR_CONN_LOST
    public static let transportLayerSecurity = MOSQ_ERR_TLS
    public static let payloadSize = MOSQ_ERR_PAYLOAD_SIZE
    public static let authentication = MOSQ_ERR_AUTH
    public static let accessDenied = MOSQ_ERR_ACL_DENIED
    public static let unknown = MOSQ_ERR_UNKNOWN
    public static let errno = MOSQ_ERR_ERRNO
    public static let addrInfo = MOSQ_ERR_EAI
    public static let proxy = MOSQ_ERR_PROXY
}

/// Enumeration representing an error condition
public typealias MosquittoError = mosq_err_t
