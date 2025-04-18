//
//  MaliciousSiteProtectionMocks.swift
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

import Combine
import Foundation
import MaliciousSiteProtection
import XCTest

@testable import DuckDuckGo_Privacy_Browser

class MockMaliciousSiteDataProvider: MaliciousSiteProtection.EmbeddedDataProviding {

    var embeddedFilterSet: Set<Filter> = []
    var embeddedHashPrefixes: Set<String> = []
    var embeddedRevision: Int = 0
    var didLoadFilterSet: Bool = false
    var didLoadHashPrefixes: Bool = false

    public func revision(for detectionKind: MaliciousSiteProtection.DataManager.StoredDataType) -> Int {
        embeddedRevision
    }

    func url(for dataType: MaliciousSiteProtection.DataManager.StoredDataType) -> URL {
        switch dataType {
        case .filterSet:
            return URL(string: "filterSet")!
        case .hashPrefixSet:
            return URL(string: "hashPrefixSet")!
        }
    }

    func hash(for dataType: MaliciousSiteProtection.DataManager.StoredDataType) -> String {
        let url = url(for: dataType)
        let data = try! data(withContentsOf: url)
        let sha = data.sha256
        return sha
    }

    func data(withContentsOf url: URL) throws -> Data {
        switch url.absoluteString {
        case "filterSet":
            self.didLoadFilterSet = true
            return "[]".utf8data
        case "hashPrefixSet":
            self.didLoadHashPrefixes = true
            return "[]".utf8data
        default:
            fatalError("Unexpected url \(url.absoluteString)")
        }
    }
}

class MockMaliciousSiteFileStore: MaliciousSiteProtection.FileStoring {
    private var storage: [String: Data] = [:]
    var didWriteToDisk: Bool = false
    var didReadFromDisk: Bool = false

    func write(data: Data, to filename: String) throws {
        didWriteToDisk = true
        storage[filename] = data
    }

    func read(from filename: String) -> Data? {
        didReadFromDisk = true
        return storage[filename]
    }
}

final class MockMaliciousSiteDetector: MaliciousSiteProtection.MaliciousSiteDetecting {

    var isMalicious: (URL) -> MaliciousSiteProtection.ThreatKind? = { url in
        if url.absoluteString.contains("phishing") {
            .phishing
        } else if url.absoluteString.contains("malware") {
            .malware
        } else if url.absoluteString.contains("scam") {
            .scam
        } else {
            nil
        }
    }

    init(isMalicious: ((URL) -> MaliciousSiteProtection.ThreatKind?)? = nil) {
        if let isMalicious {
            self.isMalicious = isMalicious
        }
    }

    func evaluate(_ url: URL) async -> MaliciousSiteProtection.ThreatKind? {
        return isMalicious(url)
    }
}
