/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import XCTest
@testable import Datadog

internal class VitalMemoryReaderTest: XCTestCase {
    func testReadMemory() throws {
        let reader = VitalMemoryReader()

        let result = reader.readVitalData()

        XCTAssertNotNil(result)
    }

    func testWhenMemoryConsumptionGrows() {
        // Given
        let reader = VitalMemoryReader()
        let threshold = reader.readVitalData()
        let allocatedSize = 128 * 1_024

        // When
        let intPointer = UnsafeMutablePointer<Int>.allocate(capacity: allocatedSize)
        for i in 0..<allocatedSize {
            (intPointer + i).initialize(to: i)
        }
        let measure = reader.readVitalData()
        intPointer.deallocate()

        // Then
        XCTAssertNotNil(threshold)
        XCTAssertNotNil(measure)
        let delta = measure! - threshold!
        XCTAssertGreaterThanOrEqual(delta, Double(allocatedSize))
    }

    func testWhenMemoryConsumptionShrinks() {
        // Given
        let reader = VitalMemoryReader()
        let allocatedSize = 128 * 1_024
        let intPointer = UnsafeMutablePointer<Int>.allocate(capacity: allocatedSize)
        for i in 0..<allocatedSize {
            (intPointer + i).initialize(to: i)
        }
        let threshold = reader.readVitalData()

        // When
        intPointer.deallocate()
        let measure = reader.readVitalData()

        // Then
        XCTAssertNotNil(threshold)
        XCTAssertNotNil(measure)
        let delta = threshold! - measure!
        XCTAssertGreaterThanOrEqual(delta, Double(allocatedSize))
    }
}
