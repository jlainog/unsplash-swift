//
//  Unsplash.swift
//  unsplash-swift-example
//
//  Created by jaime Laino Guerra on 9/24/19.
//  Copyright © 2019 jaime Laino Guerra. All rights reserved.
//
#if os(iOS)

import UIKit
import Foundation
import CoreGraphics
import Codable_Utils

public struct Unsplash {
    
    /// The Unsplash API url.
    static let apiURL = "https://api.unsplash.com/"
    
    /// Your application’s access key.
    public static private(set) var accessKey: String = "APP_ACCESS_KEY"
    
    /// Your application’s secret key.
    public static private(set) var secret: String = "APP_SECRET"
    
    /// The Unsplash editorial collection id.
    public static let editorialCollectionId = "317099"
    
    /// Configure Unsplash API with the proper access
    /// - Parameters:
    ///   - accessKey: Your application’s access key.
    ///   - secret: Your application’s secret key.
    public static func configure(accessKey: String, secret: String) {
        self.accessKey = accessKey
        self.secret = secret
    }
    
    public static func trackDownload(_ photo: Photo) {
        if let url = buildDownloadLocationURL(with: photo) {
            urlSession.dataTask(with: url).resume()
        }
    }
}

// MARK: DataTaskFactory
public extension Unsplash {
    struct DataTaskFactory {
        public static func randomPhoto(handler: @escaping (Result<Photo, RequestError>) -> Void) -> URLSessionDataTask {
            makeDataTask(
                with: .init(path: "/photos/random"),
                completionHandler: handler
            )
        }
        
        public static func searchPhotos(with query: String,
                                        cursor: Cursor,
                                        handler: @escaping (Result<SearchResponse, RequestError>) -> Void) -> URLSessionDataTask {
            let paged = Paged(with: cursor, parameters: ["query": query])
            let options = RequestOptions(path: "/search/photos",
                                         queryItems: Unsplash.makeQueryItems(paged.parameters))

            return makeDataTask(
                with: options,
                completionHandler: handler
            )
        }
        
        public static func collection(with collectionId: String,
                                      cursor: Cursor,
                                      handler: @escaping (Result<[Photo], RequestError>) -> Void) -> URLSessionDataTask {
            let paged = Paged(with: cursor, parameters: ["id": collectionId])
            let options = RequestOptions(path: "/collections/\(collectionId)/photos",
                                         params: paged.parameters)

            return makeDataTask(
                with: options,
                completionHandler: handler
            )
        }
    }
}

extension Unsplash {
    public struct Cursor {
        public let page: Int
        public let perPage: Int
        
        public init(page: Int, perPage: Int) {
            self.page = page
            self.perPage = perPage
        }
    
        public func next() -> Cursor {
            .init(page: page + 1, perPage: perPage)
        }
    }
    
    struct Paged {
        var cursor: Cursor
        var parameters: [String: String]
        
        internal init(with cursor: Cursor, parameters: [String: String]) {
            let params = ["page": "\(cursor.page)",
                "per_page": "\(cursor.perPage)"]
            
            self.cursor = cursor
            self.parameters = [params, parameters].merge()
        }
    }
}


// MARK: RequestError
public extension Unsplash {
    /// Error messages
    /// If an error occurs, whether on the server or client side,
    /// the error message(s) will be returned in an errors array. For example:
    /// {  "errors": ["Username is missing", "Password cannot be blank"] }
    struct ErrorMessages: Error, Codable {
        public var errors: [String]
    }
    
    enum RequestError: Error {
        case invalidURL,
        noHTTPResponse,
        http(status: Int),
        notConnectedToInternet,
        error(NSError)
        
        public var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid URL."
            case .noHTTPResponse:
                return "Not a HTTP response."
            case .http(let status):
                return "HTTP error: \(status)."
            case .notConnectedToInternet:
                return "Not Connected to Internet"
            case .error(let error):
                return error.localizedDescription
            }
        }
    }
}

public struct SearchResponse: Codable {
    public let total: Int
    public let totalPages: Int
    public let results: [Photo]
}

// MARK: Photo
public struct Photo: Codable {
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case height, width, color, exif
        case user, urls, links
        case likesCount = "likes"
        case downloadsCount = "downloads"
        case viewsCount = "views"
    }
    
    public enum URLKind: String, CodingKey {
        case raw, full, regular, small, thumb
    }
    
    public enum LinkKind: String, CodingKey {
        case `self`, html, download
        case downloadLocation// = "download_location"
    }
    
    public let identifier: String
    public let height: Int
    public let width: Int
    public let color: UIColor?
    public let exif: PhotoExif?
    public let user: User
    public let urls: [URLKind: URL]
    public let links: [LinkKind: URL]
    public let likesCount: Int
    public let downloadsCount: Int?
    public let viewsCount: Int?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(.identifier)
        height = try container.decode(.height)
        width = try container.decode(.width)
        color = try container.decodeHexColor(.color)
        exif = try container.decodeIfPresent(.exif)
        user = try container.decode(.user)
        urls = try container.decodeDictionary(.urls)
        links = try container.decodeDictionary(.links)
        likesCount = try container.decode(.likesCount)
        downloadsCount = try? container.decode(.downloadsCount)
        viewsCount = try? container.decode(.viewsCount)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(height, forKey: .height)
        try container.encode(width, forKey: .width)
        try container.encodeIfPresent(color?.hexString, forKey: .color)
        try container.encodeIfPresent(exif, forKey: .exif)
        try container.encode(user, forKey: .user)
        try container.encodeDictionary(urls, forKey: .urls)
        try container.encodeDictionary(links, forKey: .links)
        try container.encode(likesCount, forKey: .likesCount)
        try container.encodeIfPresent(downloadsCount, forKey: .downloadsCount)
        try container.encodeIfPresent(viewsCount, forKey: .viewsCount)
    }
    
    public func url(of kind: URLKind, size: CGSize = .zero) -> URL? {
        guard var url = urls[kind] else { return nil }
        
        if size != .zero {
            let scale = UIScreen.main.scale
            url.appendQueryItems([.init(name: "max-w", value: "\(size.width * scale)"),
                                  .init(name: "max-h", value: "\(size.height * scale)")])
        }
        
        return url
    }
}

// MARK: PhotoExif
public struct PhotoExif: Codable {
    public let aperture: String?
    public let exposureTime: String
    public let focalLength: String?
    public let iso: Int?
    public let make: String
    public let model: String
}

// MARK: User
public struct User: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case username, firstName, lastName, name, bio
        case profileImage, links, location, portfolioURL
        case totalCollections, totalLikes, totalPhotos
    }
    
    public enum ProfileImageSize: String, CodingKey {
        case small, medium, large
    }
    
    public enum LinkKind: String, CodingKey {
        case `self`, html, photos, likes, portfolio
    }
    
    public let identifier: String
    public let username: String
    public let firstName: String?
    public let lastName: String?
    public let name: String?
    public let profileImage: [ProfileImageSize: URL]
    public let bio: String?
    public let links: [LinkKind: URL]
    public let location: String?
    public let portfolioURL: URL?
    public let totalCollections: Int
    public let totalLikes: Int
    public let totalPhotos: Int
    public var profileURL: URL? { URL(string: "https://unsplash.com/@\(username)") }
    public var displayName: String {
        if let name = name { return name }
        
        if let firstName = firstName {
            if let lastName = lastName {
                return "\(firstName) \(lastName)"
            }
            return firstName
        }
        
        return username
    }
    
    public static func == (lhs: User, rhs: User) -> Bool { lhs.identifier == rhs.identifier }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(.identifier)
        username = try container.decode(.username)
        firstName = try container.decodeIfPresent(.firstName)
        lastName = try container.decodeIfPresent(.lastName)
        name = try container.decodeIfPresent(.name)
        profileImage = (try? container.decodeDictionary(.profileImage)) ?? .init()
        bio = try container.decodeIfPresent(.bio)
        links = try container.decodeDictionary(.links)
        location = try container.decodeIfPresent(.location)
        portfolioURL = try container.decodeIfPresent(.portfolioURL)
        totalCollections = try container.decode(.totalCollections)
        totalLikes = try container.decode(.totalLikes)
        totalPhotos = try container.decode(.totalPhotos)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(username, forKey: .username)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(name, forKey: .name)
        try container.encodeDictionary(profileImage, forKey: .profileImage)
        try container.encode(bio, forKey: .bio)
        try container.encodeDictionary(links, forKey: .links)
        try container.encode(location, forKey: .location)
        try container.encode(portfolioURL, forKey: .portfolioURL)
        try container.encode(totalCollections, forKey: .totalCollections)
        try container.encode(totalLikes, forKey: .totalLikes)
        try container.encode(totalPhotos, forKey: .totalPhotos)
    }
}

// MARK: UIColor+Utils
public extension UIColor {
    var redComponent: CGFloat { cgColor.components?[0] ?? 0 }
    var greenComponent: CGFloat { cgColor.components?[1] ?? 0 }
    var blueComponent: CGFloat { cgColor.components?[2] ?? 0 }
    var alpha: CGFloat {
        guard let components = cgColor.components else {
            return 1
        }
        return components[cgColor.numberOfComponents - 1]
    }
    
    var hexString: String {
        return NSString(format: "%02X%02X%02X%02X",
                        Int(round(redComponent * 255)),
                        Int(round(greenComponent * 255)),
                        Int(round(blueComponent * 255)),
                        Int(round(alpha * 255))) as String
    }
    
    convenience init(hexString: String) {
        var chars = Array(hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 1
        
        // swiftlint:disable fallthrough
        switch chars.count {
        case 3:
            chars = [chars[0], chars[0], chars[1], chars[1], chars[2], chars[2]]
            fallthrough
        case 6:
            chars = ["F", "F"] + chars
            fallthrough
        case 8:
            alpha = CGFloat(strtoul(String(chars[0...1]), nil, 16)) / 255
            red   = CGFloat(strtoul(String(chars[2...3]), nil, 16)) / 255
            green = CGFloat(strtoul(String(chars[4...5]), nil, 16)) / 255
            blue  = CGFloat(strtoul(String(chars[6...7]), nil, 16)) / 255
        default:
            alpha = 0
        }
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// MARK: UIImageView+Photo
public extension UIImageView {
    private struct AssociatedKey {
        static var imageDownloader = "UIImageView.ImageDownloader"
    }
    
    internal var imageDownloader: ImageDownloader! {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.imageDownloader) as? ImageDownloader
        }
        set(downloader) {
            objc_setAssociatedObject(self, &AssociatedKey.imageDownloader, downloader, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func setImage(from photo: Photo,
                  kind: Photo.URLKind = .regular,
                  options: UIView.AnimationOptions = .transitionCrossDissolve) {
        if imageDownloader == nil {
            imageDownloader = .init()
        }
        
        if imageDownloader
            .isCurrentLoadEqualToRequest(with: photo, size: frame.size, kind: kind) {
            return
        }
        
        imageDownloader.cancel()
        
        imageDownloader
            .load(photo,
                  size: frame.size,
                  kind: kind,
                  completionBlock: completionBlock(with: options))
    }
    
    internal func completionBlock(with options: UIView.AnimationOptions) -> (UIImage?, Bool) -> Void {
        return { [weak self] (image, isCached) in
            guard let self = self, let image = image else { return }
            if !isCached {
                UIView.transition(
                    with: self,
                    duration: 0.25,
                    options: options,
                    animations: { self.image = image },
                    completion: nil
                )
            } else {
                self.image = image
            }
        }
    }
}

// MARK: ImageDownloader
public class ImageDownloader {

    let queue: DispatchQueue = .main
    let cache: ImageURLCache = .shared
    let urlSession: URLSession = .shared
    var imageDataTask: URLSessionDataTask?
    
    var dataTaskState: URLSessionDataTask.State {
        imageDataTask?.state ?? .completed
    }
    
    public typealias DownloaderCompletionBlock = (UIImage?, _ isCached: Bool) -> Void
    public private(set) var isCancelled = false
    
    public init() {}
    
    public func load(_ photo: Photo,
                     size: CGSize = .zero,
                     kind: Photo.URLKind = .regular,
                     completionBlock block: @escaping DownloaderCompletionBlock) {
        guard let url = photo.url(of: kind), dataTaskState != .running else {
            return
        }
        
        if loadFromCache(with: url,
                         completionBlock: block) {
            return
        }
        
        imageDataTask = makeDataTask(with: url, completionBlock: block)
        resume()
    }
    
    public func cancel() {
        isCancelled = true
        imageDataTask?.cancel()
    }
    
    public func isCurrentLoadEqualToRequest(with photo: Photo,
                                            size: CGSize = .zero,
                                            kind: Photo.URLKind) -> Bool {
        guard let originalUrl = imageDataTask?.originalRequest?.url,
            let url = photo.url(of: kind, size: size) else {
                return false
        }
       return originalUrl == url && dataTaskState == .running
    }
    
    func resume() {
        isCancelled = false
        imageDataTask?.resume()
    }
    
    func loadFromCache(with url: URL, completionBlock: @escaping DownloaderCompletionBlock) -> Bool {
        guard let cached = cache.image(for: url) else { return false }
        
        isCancelled = false
        completionBlock(cached, true)
        return true
    }
    
    func makeDataTask(with url: URL, completionBlock: @escaping DownloaderCompletionBlock) -> URLSessionDataTask {
        urlSession.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else { return }

            guard let data = data,
                let response = response,
                let image = UIImage(data: data) else {
                    self.queue.async {
                        completionBlock(nil, false)
                    }
                    return
            }
            
            self.cache[url] = (response, data)
            self.queue.async {
                completionBlock(image, false)
            }
        }
    }
}

#if canImport(Combine)
import Combine

// MARK: ImageDownloader+Publisher
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension ImageDownloader {
    func downloadPublisher(_ photo: Photo,
                           size: CGSize = .zero,
                           kind: Photo.URLKind = .regular) -> AnyPublisher<UIImage?, Never> {
        guard let url = photo.url(of: kind) else {
            return Just(nil).eraseToAnyPublisher()
        }

        if let cached = cache.image(for: url) {
            return Just(cached).eraseToAnyPublisher()
        }

        return URLSession.shared
            .dataTaskPublisher(for: url)
            .map({
                self.cache[url] = $0
                return UIImage(data: $0.data)
            })
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
}
#endif

// MARK: Networking
extension Unsplash {
    private static var successCodes: CountableRange<Int> = 200..<299
    private static var failureCodes: CountableRange<Int> = 400..<499
    private static var headers: [String: String] {
        ["Accept-Version": "v1",
         "Authorization": "Client-ID \(accessKey)"]
    }
    private static var clientIdItem: URLQueryItem { .init(name: "client_id", value: accessKey) }
    
    static var urlSession: URLSession = .shared
    
    struct RequestOptions {
        let path: String
        var method: String = "get"
        var headers: [String: String]?
        var queryItems: [URLQueryItem]?
        var params: [String: String]?
    }
    
    static func buildDownloadLocationURL(with photo: Photo) -> URL? {
        var downloadLocationURL = photo.links[.downloadLocation]
        downloadLocationURL?.appendQueryItems([clientIdItem])
        return downloadLocationURL
    }
    
    static func makeQueryItems(_ items: [String: String]) -> [URLQueryItem] {
        items.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    
    static func makeDataTask<T: Decodable>(
        with options: RequestOptions,
        completionHandler handler: @escaping (Result<T, RequestError>) -> Void
    ) -> URLSessionDataTask {
        urlSession.dataTask(
            with: buildRequest(with: options),
            completionHandler: handleResponse(with: handler)
        )
    }

    static func buildRequest(with options: RequestOptions) -> URLRequest {
        var request = URLRequest(url: url(options),
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 30.0)
        let allHTTPHeaderFields =
            [headers, options.headers]
                .compactMap { $0 }
                .merge()
        
        request.httpMethod = options.method
        request.allHTTPHeaderFields = allHTTPHeaderFields
        return request
    }
    
    static func url(_ options: RequestOptions) -> URL {
        var components = URLComponents(string: apiURL)!
        components.path = options.path
        components.queryItems = options.queryItems
        
        if let params = options.params, options.method == "get" {
            components.queryItems = (components.queryItems ?? []) + makeQueryItems(params)
        }
        
        return components.url!
    }
    
    static func handleResponse<T: Decodable>(with handler: @escaping (Result<T, RequestError>) -> Void)
        -> (Data?, URLResponse?, Error?) -> Void {
            return { data , response, urlError in
                if let urlError = urlError as NSError? {
                    if urlError.code == NSURLErrorNotConnectedToInternet {
                        handler(.failure(.notConnectedToInternet))
                        return
                    }
                    handler(.failure(.error(urlError)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    handler(.failure(RequestError.noHTTPResponse))
                    return
                }
                
                let statusCode = httpResponse.statusCode
                
                switch statusCode {
                case successCodes:
                    if let data = data {
                        do {
                            let decoder = JSONDecoder()
                            decoder.keyDecodingStrategy = .convertFromSnakeCase
                            let value = try T.decode(from: data, using: decoder)
                            handler(.success(value))
                            return
                        } catch {
                            handler(.failure(.error(error as NSError)))
                        }
                    }
                    handler(.failure(.http(status: statusCode)))
                case failureCodes:
                    if let data = data {
                        let messages = try? ErrorMessages.decode(from: data)
                        debugPrint(messages?.errors ?? "")
                    }
                    handler(.failure(.http(status: statusCode)))
                default:
                    handler(.failure(.invalidURL))
                }
            }
    }
}

// MARK: KeyedDecodingContainer+HexColor
extension KeyedDecodingContainer {
    func decodeHexColor(_ codingKey: Key) throws -> UIColor {
        let hexColor = try self.decode(String.self, forKey: codingKey)
        return UIColor(hexString: hexColor)
    }
}

// MARK: URL+Utils
extension URL {
    mutating func appendQueryItems(_ items: [URLQueryItem]) {
        guard var components =
            URLComponents(
                url: self,
                resolvingAgainstBaseURL: true
            )
            else { return }
        
        components.queryItems = items + (components.queryItems ?? [])
        self = components.url ?? self
    }
}

// MARK: Array+Dictionary
extension Array where Element == [String: String] {
    func merge() -> [String: String] {
        reduce([:]) { (result, element) in
            result.merging(element) { resultKey, elementKey in resultKey }
        }
    }
}

// MARK: ImageURLCache
class ImageURLCache {
    private let cache: URLCache = .init(memoryCapacity: 50.megabytes,
                                        diskCapacity: 50.megabytes,
                                        diskPath: "Unsplash_ImageURLCache")
    
    static let shared: ImageURLCache = .init()
    
    subscript(_ url: URL) -> (response: URLResponse, data: Data)? {
        get { value(for: url) }
        set {
            guard let value = newValue else {
                removeValue(for: url)
                return
            }
            insert(value, for: url)
        }
    }
    
    func insert(_ value: (response: URLResponse, data: Data),
                for url: URL) {
        cache
            .storeCachedResponse(.init(response: value.response,
                                       data: value.data),
                                 for: .init(url: url))
    }
    
    func value(for url: URL) -> (response: URLResponse, data: Data)? {
        cache
            .cachedResponse(for: .init(url: url))
            .map { ($0.response, $0.data) }
    }
    
    func image(for url: URL) -> UIImage? {
        value(for: url).flatMap { UIImage(data: $0.data) }
    }
    
    func removeValue(for url: URL) {
        cache.removeCachedResponse(for: .init(url: url))
    }
}

private extension Int {
    var megabytes: Int { return self * 1024 * 1024 }
}

#endif
