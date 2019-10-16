//
//  unsplash_swiftTests.swift
//  unsplash-swiftTests
//
//  Created by jaime Laino Guerra on 10/15/19.
//  Copyright © 2019 jaime Laino Guerra. All rights reserved.
//
#if os(iOS)

import XCTest
import Codable_Utils
@testable import unsplash_swift

class unsplash_swiftTests: XCTestCase {
    
    override func setUp() {
        Unsplash.urlSession = .makeStubSession()
    }
    
    func testPhotoDecoding() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        XCTAssertNoThrow(
            try Bundle(for: Self.self)
                .load("Photo.json", using: decoder) as Photo
        )
    }
    
    func testPhotoEncoding() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let photo =
            try Bundle(for: Self.self)
                .load("Photo.json", using: decoder) as Photo
        
        let encoder = JSONSerializationEncoder()
        encoder.encoder.keyEncodingStrategy = .convertToSnakeCase
        
        let dictionary = try photo.encode(using: encoder)
        let links = dictionary["links"] as? [String: String]
        let urls = dictionary["urls"] as? [String: String]
        
        XCTAssertEqual(links?["download"],
                       "https://unsplash.com/photos/Dwu85P9SOIk/download")
        XCTAssertEqual(urls?["raw"],
                       "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d")
    }
    
    func testTrackDownload() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let photo: Photo = try Bundle(for: Self.self).load("Photo.json", using: decoder)
        let url = Unsplash.buildDownloadLocationURL(with: photo)
        let expectation = XCTestExpectation(description: "handleResponse")
        
        MockURLProtocol.requestHandler = { request in
            expectation.fulfill()
            XCTAssertEqual(request.url, url)
            return (.init(), .init())
        }
        
        Unsplash.trackDownload(photo)
        wait(for: [expectation], timeout: 1)
    }
    
    func testTrackDownloadRequest() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let photo: Photo = try Bundle(for: Self.self).load("Photo.json", using: decoder)
        
        let url = Unsplash.buildDownloadLocationURL(with: photo)
        
        XCTAssertEqual(url?.query, "client_id=\(Unsplash.accessKey)")
        XCTAssertEqual(url?.absoluteString.components(separatedBy: "?")[0],
                       photo.links[.downloadLocation]?.absoluteString)
    }
    
    func testRequest() {
        let params = ["param": "testParam"]
        let headers = ["header": "testHeader",
                       "Authorization": "XXX",
                       "Accept-Version": "XX"]
        let options = Unsplash.RequestOptions(path: "/test",
                                              method: "method",
                                              headers: headers,
                                              queryItems: [.init(name: "test", value: "value")],
                                              params: params)
        
        let urlRequest = Unsplash.buildRequest(with: options)
        
        XCTAssertEqual(urlRequest.url?.path, options.path)
        XCTAssertEqual(urlRequest.httpMethod, options.method)
        XCTAssertEqual(urlRequest.url?.query, "test=value")
        XCTAssertEqual(urlRequest.url?.host, "api.unsplash.com")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Accept-Version"], "v1")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["header"], headers["header"])
        XCTAssertEqual(urlRequest.allHTTPHeaderFields?["Authorization"], "Client-ID \(Unsplash.accessKey)")
    }
    
    func testHandleResponse_NoInternet() throws {
        let expectation = XCTestExpectation(description: "handleResponse")
        let handler: (Result<Photo, Unsplash.RequestError>) -> Void = { result in
            expectation.fulfill()
            switch result {
            case .failure(let error):
                if case .notConnectedToInternet = error {}
                else { XCTFail() }
            default: XCTFail()
            }
        }
        let handleResponse = Unsplash.handleResponse(with: handler)
        let response = HTTPURLResponse(url: URL(string: Unsplash.apiURL)!,
                                       statusCode: 500,
                                       httpVersion: nil,
                                       headerFields: nil)
        let error = NSError(domain: "", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        
        handleResponse(nil, response, error)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testHandleResponse_Error() throws {
        let error = NSError(domain: "", code: 0, userInfo: nil)
        let expectation = XCTestExpectation(description: "handleResponse")
        let handler: (Result<Photo, Unsplash.RequestError>) -> Void = { result in
            expectation.fulfill()
            switch result {
            case .failure(let requestError):
                if case .error(let innerError) = requestError {
                    XCTAssertEqual(innerError, error)
                } else { XCTFail() }
            default: XCTFail()
            }
        }
        let handleResponse = Unsplash.handleResponse(with: handler)
        let response = HTTPURLResponse(url: URL(string: Unsplash.apiURL)!,
                                       statusCode: 500,
                                       httpVersion: nil,
                                       headerFields: nil)
        
        handleResponse(nil, response, error)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testHandleResponse_NoHTTPURLResponse() throws {
        let expectation = XCTestExpectation(description: "handleResponse")
        let handler: (Result<Photo, Unsplash.RequestError>) -> Void = { result in
            expectation.fulfill()
            switch result {
            case .failure(let requestError):
                if case .noHTTPResponse = requestError {}
                else { XCTFail() }
            default: XCTFail()
            }
        }
        let handleResponse = Unsplash.handleResponse(with: handler)
        let response = URLResponse(url: URL(string: Unsplash.apiURL)!,
                                   mimeType: nil,
                                   expectedContentLength: 0,
                                   textEncodingName: nil)
        
        handleResponse(nil, response, nil)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testHandleResponse_Success() throws {
        let expectation = XCTestExpectation(description: "handleResponse")
        let handler: (Result<Photo, Unsplash.RequestError>) -> Void = { result in
            expectation.fulfill()
            switch result {
            case .success(_): break
            default: XCTFail()
            }
        }
        let handleResponse = Unsplash.handleResponse(with: handler)
        let data = try Bundle(for: Self.self).load("Photo.json")
        let response = HTTPURLResponse(url: URL(string: Unsplash.apiURL)!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)
        
        handleResponse(data, response, nil)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testHandleResponse_FailureNoData() throws {
        let expectation = XCTestExpectation(description: "handleResponse")
        let handler: (Result<Photo, Unsplash.RequestError>) -> Void = { result in
            expectation.fulfill()
            switch result {
            case .failure(let error):
                if case let .http(status: status) = error {
                    XCTAssertEqual(status, 200)
                } else { XCTFail() }
            default: XCTFail()
            }
        }
        let handleResponse = Unsplash.handleResponse(with: handler)
        let response = HTTPURLResponse(url: URL(string: Unsplash.apiURL)!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)
        
        handleResponse(nil, response, nil)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testHandleResponse_FailureCode() throws {
        let expectation = XCTestExpectation(description: "handleResponse")
        let handler: (Result<Photo, Unsplash.RequestError>) -> Void = { result in
            expectation.fulfill()
            switch result {
            case .failure(let error):
                if case let .http(status: status) = error {
                    XCTAssertEqual(status, 400)
                } else { XCTFail() }
            default: XCTFail()
            }
        }
        let handleResponse = Unsplash.handleResponse(with: handler)
        let response = HTTPURLResponse(url: URL(string: Unsplash.apiURL)!,
                                       statusCode: 400,
                                       httpVersion: nil,
                                       headerFields: nil)
        
        handleResponse(nil, response, nil)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testHandleResponse_FailureDefault() throws {
        let expectation = XCTestExpectation(description: "handleResponse")
        let handler: (Result<Photo, Unsplash.RequestError>) -> Void = { result in
            expectation.fulfill()
            switch result {
            case .failure(let error):
                if case .invalidURL = error {}
                else { XCTFail() }
            default: XCTFail()
            }
        }
        let handleResponse = Unsplash.handleResponse(with: handler)
        let response = HTTPURLResponse(url: URL(string: Unsplash.apiURL)!,
                                       statusCode: 600,
                                       httpVersion: nil,
                                       headerFields: nil)
        
        handleResponse(nil, response, nil)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRandomPhotoTask() throws {
        let data = try Bundle(for: Self.self).load("Photo.json")
        URLSession.stubRequest { request in
            XCTAssertEqual(request.url?.path, "/photos/random")
            return (.init(), data)
        }
        
        let expectation = XCTestExpectation(description: "response")
        Unsplash.DataTaskFactory
            .randomPhoto { _ in expectation.fulfill() }
            .resume()
        wait(for: [expectation], timeout: 1)
    }

}

extension URLSession {
    static func makeStubSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
    
    static func stubRequest(with handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?) {
        MockURLProtocol.requestHandler = handler
    }
}

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Receive request with no handler")
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
}

#endif
