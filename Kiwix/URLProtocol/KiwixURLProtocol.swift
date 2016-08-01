//
//  KiwixURLProtocol.swift
//  Kiwix
//
//  Created by Chris Li on 8/14/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//  http://www.raywenderlich.com/76735/using-nsurlprotocol-swift

class KiwixURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.scheme!.caseInsensitiveCompare("Kiwix") == .orderedSame ? true : false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(_ aRequest: URLRequest, to bRequest: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(aRequest, to:bRequest)
    }
    
    override func startLoading() {
        guard let url = request.url, let id = url.host, let contentURLString = url.path?.removingPercentEncoding else {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: nil)
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        guard let dataDic = ZimMultiReader.sharedInstance.data(id, contentURLString: contentURLString),
            let data = dataDic["data"] as? Data,
            let mimeType = dataDic["mime"] as? String,
            let dataLength = (dataDic["length"] as? NSNumber)?.intValue else {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: nil)
                client?.urlProtocol(self, didFailWithError: error)
                return
        }
        
        if mimeType.contains("image") {
            PacketAnalyzer.sharedInstance.addImage(data, url: url)
        }
        
        let response = URLResponse(url: self.request.url!, mimeType: mimeType, expectedContentLength: dataLength, textEncodingName: nil)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        return
    }
}

extension URL {
    static func kiwixURLWithZimFileid(_ id: String, contentURLString: String) -> URL? {
        guard let escapedContentURLString = contentURLString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {return nil}
        let baseURLString = "kiwix://" + id
        guard let baseURL = URL(string: baseURLString) else {return nil}
        return URL(string: escapedContentURLString, relativeTo: baseURL)
    }
    
    static func kiwixURLWithZimFileid(_ id: String, articleTitle: String) -> URL? {
        guard let contentURLString = ZimMultiReader.sharedInstance.pageURLString(articleTitle, bookid: id) else {
            print("ZimMultiReader cannot get pageURLString from \(articleTitle) in book \(id)")
            return nil
        }
        return URL.kiwixURLWithZimFileid(id, contentURLString: contentURLString)
    }
    
    init?(id: ZimID, contentURLString: String) {
        guard let escapedContentURLString = contentURLString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {return nil}
        let baseURLString = "kiwix://" + id
        guard let baseURL = URL(string: baseURLString) else {return nil}
        self.init(string: escapedContentURLString, relativeTo: baseURL)
    }
}
