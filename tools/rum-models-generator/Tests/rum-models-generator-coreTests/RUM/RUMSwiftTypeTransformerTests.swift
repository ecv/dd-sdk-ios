/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Datadog (https://www.datadoghq.com/).
* Copyright 2019-2020 Datadog, Inc.
*/

import XCTest
@testable import RUMModelsGeneratorCore

final class RUMSwiftTypeTransformerTests: XCTestCase {
    func testTransformingSwiftStruct() throws {
        let `struct` = SwiftStruct(
            name: "FooBar",
            comment: "Description of FooBar.",
            properties: [
                SwiftStruct.Property(
                    name: "bar",
                    comment: "Description of Bar.",
                    type: SwiftStruct(
                        name: "bar",
                        comment: "Description of Bar.",
                        properties: [
                            SwiftStruct.Property(
                                name: "property1",
                                comment: "Description of Bar's `property1`.",
                                type: SwiftPrimitive<String>(),
                                isOptional: true,
                                isMutable: false,
                                defaultVaule: nil,
                                codingKey: "property1"
                            ),
                            SwiftStruct.Property(
                                name: "property2",
                                comment: "Description of Bar's `property2`.",
                                type: SwiftPrimitive<String>(),
                                isOptional: false,
                                isMutable: true,
                                defaultVaule: nil,
                                codingKey: "property2"
                            )
                        ],
                        conformance: []
                    ),
                    isOptional: true,
                    isMutable: false,
                    defaultVaule: nil,
                    codingKey: "bar"
                ),
                SwiftStruct.Property(
                    name: "property1",
                    comment: "Description of FooBar's `property1`.",
                    type: SwiftEnum(
                        name: "property1",
                        comment: "Description of FooBar's `property1`.",
                        cases: [
                            SwiftEnum.Case(label: "case 1", rawValue: "case 1"),
                            SwiftEnum.Case(label: "case 2", rawValue: "case 2"),
                            SwiftEnum.Case(label: "case 3", rawValue: "case 3"),
                            SwiftEnum.Case(label: "case 4", rawValue: "case 4"),
                        ],
                        conformance: []
                    ),
                    isOptional: false,
                    isMutable: false,
                    defaultVaule: SwiftEnum.Case(label: "case2", rawValue: "case2"),
                    codingKey: "property1"
                ),
                SwiftStruct.Property(
                    name: "property2",
                    comment: "Description of FooBar's `property2`.",
                    type: SwiftArray(
                        element: SwiftEnum(
                            name: "property2",
                            comment: nil,
                            cases: [
                                SwiftEnum.Case(label: "option-1", rawValue: "option-1"),
                                SwiftEnum.Case(label: "option-2", rawValue: "option-2"),
                                SwiftEnum.Case(label: "option-3", rawValue: "option-3"),
                                SwiftEnum.Case(label: "option-4", rawValue: "option-4"),
                            ],
                            conformance: []
                        )
                    ),
                    isOptional: true,
                    isMutable: true,
                    defaultVaule: nil,
                    codingKey: "property2"
                )
            ],
            conformance: []
        )

        let actual = RUMSwiftTypeTransformer().transform(type: `struct`)

        let expected = SwiftStruct(
            name: "FooBar",
            comment: "Description of FooBar.",
            properties: [
                SwiftStruct.Property(
                    name: "bar",
                    comment: "Description of Bar.",
                    type: SwiftStruct(
                        name: "BAR",
                        comment: "Description of Bar.",
                        properties: [
                            SwiftStruct.Property(
                                name: "property1",
                                comment: "Description of Bar's `property1`.",
                                type: SwiftPrimitive<String>(),
                                isOptional: true,
                                isMutable: false,
                                defaultVaule: nil,
                                codingKey: "property1"
                            ),
                            SwiftStruct.Property(
                                name: "property2",
                                comment: "Description of Bar's `property2`.",
                                type: SwiftPrimitive<String>(),
                                isOptional: false,
                                isMutable: true,
                                defaultVaule: nil,
                                codingKey: "property2"
                            )
                        ],
                        conformance: [codableProtocol]
                    ),
                    isOptional: true,
                    isMutable: false,
                    defaultVaule: nil,
                    codingKey: "bar"
                ),
                SwiftStruct.Property(
                    name: "property1",
                    comment: "Description of FooBar's `property1`.",
                    type: SwiftEnum(
                        name: "Property1",
                        comment: "Description of FooBar's `property1`.",
                        cases: [
                            SwiftEnum.Case(label: "case1", rawValue: "case 1"),
                            SwiftEnum.Case(label: "case2", rawValue: "case 2"),
                            SwiftEnum.Case(label: "case3", rawValue: "case 3"),
                            SwiftEnum.Case(label: "case4", rawValue: "case 4"),
                        ],
                        conformance: [codableProtocol]
                    ),
                    isOptional: false,
                    isMutable: false,
                    defaultVaule: SwiftEnum.Case(label: "case2", rawValue: "case2"),
                    codingKey: "property1"
                ),
                SwiftStruct.Property(
                    name: "property2",
                    comment: "Description of FooBar's `property2`.",
                    type: SwiftArray(
                        element: SwiftEnum(
                            name: "Property2",
                            comment: nil,
                            cases: [
                                SwiftEnum.Case(label: "option1", rawValue: "option-1"),
                                SwiftEnum.Case(label: "option2", rawValue: "option-2"),
                                SwiftEnum.Case(label: "option3", rawValue: "option-3"),
                                SwiftEnum.Case(label: "option4", rawValue: "option-4"),
                            ],
                            conformance: [codableProtocol]
                        )
                    ),
                    isOptional: true,
                    isMutable: true,
                    defaultVaule: nil,
                    codingKey: "property2"
                )
            ],
            conformance: [SwiftProtocol(name: "RUMDataModel", conformance: [codableProtocol])]
        )

        XCTAssertEqual(expected, try XCTUnwrap(actual as? SwiftStruct))
    }
}
