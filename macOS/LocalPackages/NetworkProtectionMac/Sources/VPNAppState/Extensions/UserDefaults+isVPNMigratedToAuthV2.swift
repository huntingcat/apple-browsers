//
//  UserDefaults+isVPNMigratedToAuthV2.swift
//
//  Copyright © 2025 DuckDuckGo. All rights reserved.
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

extension UserDefaults {
    @objc
    public dynamic var isVPNMigratedToAuthV2: Bool {
        get {
            bool(forKey: #keyPath(isVPNMigratedToAuthV2))
        }

        set {
            guard newValue != bool(forKey: #keyPath(isVPNMigratedToAuthV2)) else {
                return
            }

            guard newValue else {
                removeObject(forKey: #keyPath(isVPNMigratedToAuthV2))
                return
            }

            set(newValue, forKey: #keyPath(isVPNMigratedToAuthV2))
        }
    }

    func resetIsVPNMigratedToAuthV2() {
        removeObject(forKey: #keyPath(isVPNMigratedToAuthV2))
    }

    @objc
    public dynamic var isAuthV2Enabled: Bool {
        get {
            bool(forKey: #keyPath(isAuthV2Enabled))
        }

        set {
            guard newValue != bool(forKey: #keyPath(isAuthV2Enabled)) else {
                return
            }

            guard newValue else {
                removeObject(forKey: #keyPath(isAuthV2Enabled))
                return
            }

            set(newValue, forKey: #keyPath(isAuthV2Enabled))
        }
    }

    func resetIsAuthV2Enabled() {
        removeObject(forKey: #keyPath(isAuthV2Enabled))
    }
}
