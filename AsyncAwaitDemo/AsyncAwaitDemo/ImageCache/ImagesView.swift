import Foundation
import SwiftUI

struct ImagesView: View {
    @ObservedObject var viewModel = ImageListViewModel()
    
    let col = GridItem(.flexible(), spacing: 1)
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVGrid(columns: [col, col], alignment: .center, spacing: 1) {
                        ForEach(viewModel.photos) { photo in
                            ImageCell(image: viewModel.image(for: photo))
                        }
                    }
                }
            }
            .overlay(
                VStack(spacing: 20) {
                    ProgressView().opacity(viewModel.isLoading ? 1 : 0)
                    
                    if viewModel.isLoading {
                        Button("Stop loading") {
                            viewModel.cancelLoad()
                        }
                    }
                }
            )
            .onAppear { viewModel.loadPhotos() }
            .navigationTitle("Unsplash")
        }
    }
}

struct ImageCell: View {
    let image: UIImage?
    
    var body: some View {
        return Rectangle()
            .fill(Color(white: 0.8))
            .aspectRatio(1.4, contentMode: .fit)
            .overlay(
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
            )
            .clipped()
    }
}

#if DEBUG
struct ImagesView_Preview: PreviewProvider {
    static var previews: some View {
        ImagesView()
    }
}
#endif

