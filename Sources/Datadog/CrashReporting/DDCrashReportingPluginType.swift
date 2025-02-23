/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

#if DD_SDK_ENABLE_EXPERIMENTAL_APIS
/// Crash Report format supported by Datadog SDK.
@objc
public class DDCrashReport: NSObject {
    /// The date of the crash occurrence.
    internal let date: Date?
    /// Crash report type - used to group similar crash reports.
    internal let type: String
    /// Crash report message - if possible, it should provide additional troubleshooting information in addition to the crash type.
    internal let message: String
    /// Unsymbolicated stack trace of the crash.
    internal let stackTrace: String
    /// The last context injected through `inject(context:)`
    internal let context: Data?

    #if DD_SDK_ENABLE_INTERNAL_MONITORING
    /// Additional diagnostic information about the crash report, collected for `DatadogCrashReporting` observability.
    /// Available only if internal monitoring is enabled, disabled by default.
    /// See: `Datadog.Configuration.Builder.enableInternalMonitoring(clientToken:)`.
    public var diagnosticInfo: [String: Encodable] = [:]
    #endif

    public init(
        date: Date?,
        type: String,
        message: String,
        stackTrace: String,
        context: Data?
    ) {
        self.date = date
        self.type = type
        self.message = message
        self.stackTrace = stackTrace
        self.context = context
    }
}

/// An interface for enabling crash reporting feature in Datadog SDK.
/// It is implemented by `DDCrashReportingPlugin` from `DatadogCrashReporting` framework.
///
/// The SDK calls each API on a background thread and succeeding calls are synchronized.
@objc
public protocol DDCrashReportingPluginType: class {
    /// Reads unprocessed crash report if available.
    /// - Parameter completion: the completion block called with the value of `DDCrashReport` if a crash report is available
    /// or with `nil` otherwise. The value returned by the receiver should indicate if the crash report was processed correctly (`true`)
    /// or something went wrong (`false)`. Depending on the returned value, the crash report will be purged or perserved for future read.
    ///
    /// The SDK calls this method on a background thread. The implementation is free to choice any thread
    /// for executing the  `completion`.
    func readPendingCrashReport(completion: (DDCrashReport?) -> Bool)

    /// Injects custom data for describing the application state in the crash report.
    /// This data will be attached to produced crash report and will be available in `DDCrashReport`.
    ///
    /// The SDK calls this method for each significant application state change.
    /// It is called on a background thread and succeeding calls are synchronized.
    func inject(context: Data)
}

#else

@objc
internal class DDCrashReport: NSObject {
    internal let date: Date?
    internal let type: String
    internal let message: String
    internal let stackTrace: String
    internal let context: Data?
    #if DD_SDK_ENABLE_INTERNAL_MONITORING
    internal var diagnosticInfo: [String: Encodable] = [:]
    #endif
    internal init(
        date: Date?,
        type: String,
        message: String,
        stackTrace: String,
        context: Data?
    ) {
        self.date = date
        self.type = type
        self.message = message
        self.stackTrace = stackTrace
        self.context = context
    }
}

@objc
internal protocol DDCrashReportingPluginType: class {
    func readPendingCrashReport(completion: (DDCrashReport?) -> Bool)
    func inject(context: Data)
}

#endif
