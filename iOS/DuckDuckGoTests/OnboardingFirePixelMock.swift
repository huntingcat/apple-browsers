//
//  OnboardingFirePixelMock.swift
//  DuckDuckGo
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import Core
import BrowserServicesKit
import PixelExperimentKit
@testable import DuckDuckGo

final class OnboardingPixelFireMock: OnboardingPixelFiring {
    static private(set) var didCallFire = false
    static private(set) var capturedPixelEvent: Pixel.Event?
    static private(set) var capturedParams: [String: String] = [:]
    static private(set) var capturedIncludeParameters: [Pixel.QueryParameters] = []

    static func fire(pixel: Pixel.Event, withAdditionalParameters params: [String: String], includedParameters: [Pixel.QueryParameters]) {
        didCallFire = true
        capturedPixelEvent = pixel
        capturedParams = params
        capturedIncludeParameters = includedParameters
    }

    static func tearDown() {
        didCallFire = false
        capturedPixelEvent = nil
        capturedParams = [:]
        capturedIncludeParameters = []
    }
}

final class OnboardingUniquePixelFireMock: OnboardingPixelFiring {
    static private(set) var didCallFire = false
    static private(set) var capturedPixelEvent: Pixel.Event?
    static private(set) var capturedParams: [String: String] = [:]
    static private(set) var capturedIncludeParameters: [Pixel.QueryParameters] = []

    static private(set) var capturedPixelEventHistory: [Pixel.Event] = []

    static func fire(pixel: Pixel.Event, withAdditionalParameters params: [String: String], includedParameters: [Pixel.QueryParameters]) {
        didCallFire = true
        capturedPixelEvent = pixel
        capturedParams = params
        capturedIncludeParameters = includedParameters
        capturedPixelEventHistory.append(pixel)
    }

    static func tearDown() {
        didCallFire = false
        capturedPixelEvent = nil
        capturedParams = [:]
        capturedIncludeParameters = []
        capturedPixelEventHistory = []
    }
}

final class OnboardingExperimentPixelFireMock: ExperimentPixelFiring {
    struct FiredPixel {
        let subfeatureID: SubfeatureID
        let metric: String
        let conversionWindow: ConversionWindow
        let value: String
    }

    static private(set) var firedMetrics: [FiredPixel] = []

    static func fireExperimentPixel(for subfeatureID: SubfeatureID, metric: String, conversionWindowDays: ConversionWindow, value: String) {

        let firedPixel = FiredPixel(
            subfeatureID: subfeatureID,
            metric: metric,
            conversionWindow: conversionWindowDays,
            value: value
        )
        firedMetrics.append(firedPixel)
    }

    static func tearDown() {
        firedMetrics.removeAll()
    }
}
