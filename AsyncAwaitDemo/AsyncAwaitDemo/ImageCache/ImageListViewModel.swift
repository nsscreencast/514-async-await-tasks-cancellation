import Foundation
import UIKit

@MainActor
class ImageListViewModel: ObservableObject {
    @Published var photos: [UnsplashPhoto] = []
    @Published var isLoading = false
    private let client = UnsplashApiClient()
    
    private var imageCache: [String: UIImage] = [:]
    private var imageLoadTask: Task<Void, Error>?
    
    func image(for photo: UnsplashPhoto) -> UIImage? {
        imageCache[photo.id]
    }
    
    func cancelLoad() {
        imageLoadTask?.cancel()
    }
    
    func loadPhotos() {
        imageLoadTask = Task {
            isLoading = true
            do {
                async let photos1 = client.photos(page: 1).results
                async let photos2 = client.photos(page: 2).results
                let cache = try await fetchThumbnails(for: photos1 + photos2)
                self.imageCache = cache
                self.photos = try await photos1 + photos2
            } catch {
                print("Error: \(error)")
            }
            isLoading = false
        }
    }
    
    private func fetchThumbnails(for photos: [UnsplashPhoto]) async throws -> [String: UIImage] {
        try await withThrowingTaskGroup(of: (id: String, thumb: UIImage?).self) { group in
            var thumbnails: [String: UIImage] = [:]
            for photo in photos {
                guard !Task.isCancelled else { break }
                // try Task.checkCancellation() // good if we want to abort everything
                group.addTask {
                    print("Fetching thumbnail for \(photo.id)...")
                    let thumb = try await self.fetchSingleThumbnail(for: photo)
                    return (photo.id, thumb)
                }
                
                for try await result in group {
                    thumbnails[result.id] = result.thumb
                }
            }
            return thumbnails
        }
    }
    
    private func fetchSingleThumbnail(for photo: UnsplashPhoto) async throws -> UIImage? {
        guard let url = photo.urls[.thumb] else { return nil }
        try? await Task.sleep(nanoseconds: NSEC_PER_SEC)
        do {
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            return await UIImage(data: data)?.byPreparingForDisplay()
        } catch {
            let nsError = error as NSError
            if (nsError.domain, nsError.code) == (URLError.errorDomain, URLError.cancelled.rawValue) {
                return nil
            } else {
                throw error
            }
        }
    }
}
