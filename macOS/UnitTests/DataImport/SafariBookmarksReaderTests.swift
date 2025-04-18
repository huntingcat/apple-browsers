//
//  SafariBookmarksReaderTests.swift
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
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
import XCTest
@testable import DuckDuckGo_Privacy_Browser

class SafariBookmarksReaderTests: XCTestCase {

    func testImportingBookmarks() {
        let bookmarksReader = SafariBookmarksReader(safariBookmarksFileURL: bookmarksFileURL())
        let bookmarks = bookmarksReader.readBookmarks()

        guard case let .success(bookmarks) = bookmarks else {
            XCTFail("Failed to decode bookmarks")
            return
        }

        XCTAssertEqual(bookmarks.topLevelFolders.bookmarkBar?.type, .folder)
        XCTAssertEqual(bookmarks.topLevelFolders.otherBookmarks?.type, .folder)
    }

    private func bookmarksFileURL() -> URL {
        let bundle = Bundle(for: FirefoxBookmarksReaderTests.self)
        return bundle.resourceURL!.appendingPathComponent("DataImportResources/TestSafariData/Bookmarks.plist")
    }

}
