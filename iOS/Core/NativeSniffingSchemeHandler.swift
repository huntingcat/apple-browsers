//
//  NativeSniffingSchemeHandler.swift
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

import WebKit
import ObjectiveC
import Common

// MARK: - 核心 Scheme 处理类
final class NativeSniffingSchemeHandler: NSObject, WKURLSchemeHandler {
    private let activeTasks = NSMutableArray()
    private let session = NativeSessionManager.shared
    private let cookieSyncQueue = DispatchQueue(label: "com.sniffing.cookie", attributes: .concurrent)
    
    // MARK: - URL Scheme 处理协议实现
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        activeTasks.add(urlSchemeTask)
        processRequest(urlSchemeTask.request, webView: webView, task: urlSchemeTask)
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        activeTasks.remove(urlSchemeTask)
    }
    
    // MARK: - 请求处理管道
    private func processRequest(_ request: URLRequest,
                               webView: WKWebView,
                               task: WKURLSchemeTask) {
        guard var mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else { return }
        
        // 域名特异性 Cookie 同步（参考网页5）
        if let host = request.url?.host, host.contains("qq.com") {
            syncCookies(for: mutableRequest, webView: webView) { [weak self] in
                self?.startNetworkTask(mutableRequest as URLRequest,
                                      webView: webView,
                                      task: task)
            }
        } else {
            startNetworkTask(mutableRequest as URLRequest,
                            webView: webView,
                            task: task)
        }
    }
    
    // MARK: - 网络请求核心逻辑（参考网页6）
    private func startNetworkTask(_ request: URLRequest,
                                  webView: WKWebView,
                                  task: WKURLSchemeTask) {
        let dataTask = session.dataTask(with: request) { [weak self] data, response, error in
            print("NativeSniffingSchemeHandler dataTask \(data) \(response) \(error)")
            guard let self = self, self.activeTasks.contains(task) else { return }
            // 响应处理管道
            if let response = response {
                // 同步响应Cookie到WKWebView（参考网页8）
                self.syncResponseCookies(response, webView: webView)
                // 上报分析数据
                self.postAnalytics(for: task, request: request, response: response)
                self.handleResponse(response, task: task)
            }
            
            if let data = data {
                self.handleData(data, task: task)
            }
            
            if data == nil && response == nil {
                self.handleCompletion(error, task: task)
            }
           
        }
        dataTask.resume()
    }
}

// MARK: - 分析数据模型
class SniffingAnalyticsInfo {
    let timestamp: Date
    let url: URL?
    let method: String?
    let requestHeaders: [String: String]
    let responseHeaders: [String: String]
    
    init(task: WKURLSchemeTask, response: URLResponse?) {
        self.timestamp = Date()
        self.url = task.request.url
        self.method = task.request.httpMethod
        self.requestHeaders = task.request.allHTTPHeaderFields ?? [:]
        self.responseHeaders = (response as? HTTPURLResponse)?.allHeaderFields as? [String: String] ?? [:]
    }
}

// MARK: - 通知扩展
extension NativeSniffingSchemeHandler {
    private func postAnalytics(for task: WKURLSchemeTask,
                             request: URLRequest,
                             response: URLResponse?) {
        let info = SniffingAnalyticsInfo(task: task, response: response)
        print("postAnalytics \(info.url?.absoluteString ?? "") ")
        /*
        NotificationCenter.default.post(
            name: .init("NativeSniffingAnalyticsNotification"),
            object: nil,
            userInfo: ["analytics": info]
        )
        */
    }
}

// MARK: - 响应状态跟踪（修复hasReceivedResponse错误）
private var ResponseKey: UInt8 = 0
extension WKURLSchemeTask {
    var hasReceivedResponse: Bool {
        get { objc_getAssociatedObject(self, &ResponseKey) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &ResponseKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}

// MARK: - 响应处理扩展
extension NativeSniffingSchemeHandler {
    private func handleResponse(_ response: URLResponse?, task: WKURLSchemeTask) {
        guard let response = response, !task.hasReceivedResponse else { return }
        print("NativeSniffingSchemeHandler handleResponse 1")
        DispatchQueue.main.async {
            task.didReceive(response)
            task.hasReceivedResponse = true
        }
    }
    
    private func handleData(_ data: Data?, task: WKURLSchemeTask) {
        print("NativeSniffingSchemeHandler handleData 2 \(data)")
        data.map { chunk in
            DispatchQueue.main.async {
                task.didReceive(chunk)
            }
        }
    }
    
    private func handleCompletion(_ error: Error?, task: WKURLSchemeTask) {
        print("NativeSniffingSchemeHandler handleCompletion 3 \(error)")
        DispatchQueue.main.async { [weak self] in
            guard self?.activeTasks.contains(task) == true else { return }
            error.map { task.didFailWithError($0) } ?? task.didFinish()
            self?.activeTasks.remove(task)
        }
    }
}

// MARK: - Cookie 同步扩展（参考网页5、网页8）
extension NativeSniffingSchemeHandler {
    private func syncCookies(for request: NSMutableURLRequest,
                           webView: WKWebView,
                           completion: @escaping () -> Void) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            let cookieHeader = cookies
                .filter { request.url?.host?.contains($0.domain) ?? false }
                .map { "\($0.name)=\($0.value)" }
                .joined(separator: "; ")
            
            if !cookieHeader.isEmpty {
                request.addValue(cookieHeader, forHTTPHeaderField: "Cookie")
            }
            completion()
        }
    }
    
    private func syncResponseCookies(_ response: URLResponse?, webView: WKWebView) {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        let headers = httpResponse.allHeaderFields
        
        if let cookieHeaders = headers["Set-Cookie"] as? String {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": cookieHeaders],
                                            for: httpResponse.url!)
            cookies.forEach { cookie in
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
        }
    }
}

// MARK: - 网络会话管理器（参考原OC的XDURLSessionManager）
final class NativeSessionManager: NSObject, URLSessionDataDelegate {
    static let shared = NativeSessionManager()
    private lazy var session: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }()
    private var taskHandlers = [Int: TaskHandler]()
    private let lock = NSLock()
    
    struct TaskHandler {
        var didReceiveResponse: ((URLResponse) -> Void)?
        var didReceiveData: ((Data) -> Void)?
        var didComplete: ((Error?) -> Void)?
        var willRedirect: ((HTTPURLResponse, URLRequest) -> Void)?
    }
    
    func dataTask(with request: URLRequest,
                  completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let task = session.dataTask(with: request)
        lock.lock()
        taskHandlers[task.taskIdentifier] = TaskHandler(
            didReceiveResponse: { response in completion(nil, response, nil) },
            didReceiveData: { data in completion(data, nil, nil) },
            didComplete: { error in completion(nil, nil, error) }
        )
        lock.unlock()
        return task
    }
    
    // MARK: - URLSession 代理方法
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        taskHandlers[dataTask.taskIdentifier]?.didReceiveData?(data)
        lock.unlock()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        taskHandlers[task.taskIdentifier]?.didComplete?(error)
        taskHandlers.removeValue(forKey: task.taskIdentifier)
        lock.unlock()
    }
    
    // MARK: - 响应接收
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        
        taskHandlers[dataTask.taskIdentifier]?.didReceiveResponse?(response)
        completionHandler(.allow)
    }
    
    // MARK: - URLSession 代理方法（处理重定向）
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        
        taskHandlers[task.taskIdentifier]?.willRedirect?(response, request)
        completionHandler(request)
    }
}

// MARK: - Swizzling 实现（参考网页6、网页9）
extension WKWebView {
    // allow setting WKURLSchemeHandler for WebView-handled schemes like HTTP
    public static var customHandlerSchemes = Set<URL.NavigationalScheme>() {
        didSet {
            _=swizzleHandlesURLSchemeOnce
        }
    }
    
    private static let swizzleHandlesURLSchemeOnce: Void = {
        let originalLoad = class_getClassMethod(WKWebView.self, #selector(WKWebView.handlesURLScheme))!
        let swizzledLoad = class_getClassMethod(WKWebView.self, #selector(WKWebView.swizzled_handlesURLScheme))!
        method_exchangeImplementations(originalLoad, swizzledLoad)
    }()
    
    @objc private class func swizzled_handlesURLScheme(_ urlScheme: String) -> Bool {
        guard !customHandlerSchemes.contains(URL.NavigationalScheme(rawValue: urlScheme)) else { return false }
        return self.swizzled_handlesURLScheme(urlScheme) // call original
    }
}
