//
//  UIWindowExtension.swift
//  DuckDuckGo
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

import UIKit

public let kTagForScene: Int = 34567
extension UIWindow {

    static func makeBlank() -> UIWindow {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white

        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .white
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        return window
    }

}


extension UIWindow {
    static var currentWindow: UIWindow? {
        UIApplication.shared.windows.filter({$0.tag == kTagForScene}).first
    }
    
    static var statusBarFrame: CGRect {
        currentWindow?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
    }
    
    static var statusBarHeight: CGFloat {
        statusBarFrame.size.height
    }
    
    static var isSmallDevice: Bool {
        UIScreen.main.bounds.height <= 667.0
    }
    
    static var safeAreaTop: CGFloat {
        currentWindow?.safeAreaInsets.top ?? 0.0
    }
    
    static var safeAreaBottom: CGFloat {
        currentWindow?.safeAreaInsets.bottom ?? 0.0
    }
    
    static var safeArea: UIEdgeInsets {
        currentWindow?.safeAreaInsets ?? .zero
    }
    
    static var topWithStatusOrSafeArea: CGFloat {
        if safeAreaTop == 0.0 {
            return statusBarHeight
        } else {
            return safeAreaTop
        }
    }
}
