//
//  ContentView.swift
//  unsplash-swift-example
//
//  Created by jaime Laino Guerra on 9/24/19.
//  Copyright © 2019 jaime Laino Guerra. All rights reserved.
//

import SwiftUI
import Combine
import unsplash_swift
import Codable_Utils

extension Unsplash {
    static func getRandomPhotoPublisher() -> AnyPublisher<Photo?, Never> {
        return Future<Photo?, Never> { promise in
            DataTaskFactory.randomPhoto { (result) in
                switch result {
                case .success(let photo):
                    promise(.success(photo))
                default: break
                }
            }.resume()
        }
        .eraseToAnyPublisher()
    }
}

final class PhotoLoader: ObservableObject {
    private var cancellable = Set<AnyCancellable>()
    @Published var image: UIImage = .init()
    
    func load(_ photo: Photo) {
        ImageDownloader()
            .downloadPublisher(photo)
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .assign(to: \.image, on: self)
            .store(in: &cancellable)
    }
}

struct PhotoImage: View {
    @ObservedObject private var loader = PhotoLoader()
    var photo: Photo?
    var displayName: String {
        photo?.user.displayName ?? ""
    }
    
    init(photo: Photo?) {
        guard let photo = photo else { return }
        self.photo = photo
        loader.load(photo)
    }
    
    var body: some View {
        ZStack {
            Image(uiImage: loader.image)
                .resizable()
                .aspectRatio(contentMode: ContentMode.fit)
            VStack {
                Spacer()
                Text(displayName)
                    .bold()
                    .font(.largeTitle)
                    .foregroundColor(.red)
            }
        }
    }
}

class GetRandomViewModel: ObservableObject {
    private var cancellable = Set<AnyCancellable>()
    @Published var photo: Photo?
    
    func getRandom() {
        Unsplash
            .getRandomPhotoPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.photo, on: self)
            .store(in: &cancellable)
    }
}

struct ContentView: View {
   @ObservedObject private var viewModel: GetRandomViewModel = .init()
    
    var body: some View {
        VStack {
            PhotoImage(photo: viewModel.photo)
                .onAppear(perform: viewModel.getRandom)
            Button(action: viewModel.getRandom,
                   label: { Text("Get Random Photo").font(.largeTitle) })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
