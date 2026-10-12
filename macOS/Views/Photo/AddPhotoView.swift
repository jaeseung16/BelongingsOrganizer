//
//  MacAddPhotoView.swift
//  Belongings Organizer
//
//  Created by Jae Seung Lee on 9/21/21.
//

import SwiftUI
import SDWebImageWebPCoder
import UniformTypeIdentifiers
import PhotosUI

struct AddPhotoView: View, DropDelegate {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BelongingsViewModel

    @Binding var photo: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var failed = false
    @State private var details = ""

    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()

                Divider()

                photoView()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)

                Divider()

                footer()
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onDrop(of: [.image, .fileURL, .url], delegate: self)
        }
        .alert("Cannot add a photo", isPresented: $failed, presenting: details) { details in
            Button("Dismiss") {

            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    photo = await viewModel.resized(data)
                }
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: [.image, .fileURL, .url]) else {
            return false
        }

        viewModel.getData(from: info) { data, error in
            guard let data = data else {
                if let localizedDescription = error?.localizedDescription {
                    details = localizedDescription
                }
                self.photo = nil
                failed.toggle()
                return
            }

            self.photo = data
        }

        return true
    }

    private func header() -> some View {
        HStack {
            Button(action: {
                dismiss.callAsFunction()
            }, label: {
                Label("Cancel", systemImage: "chevron.backward")
            })

            Spacer()

            Button(action: {
                viewModel.updateImage(photo)
                dismiss.callAsFunction()
            }, label: {
                Text("Done")
            })
        }
    }

    private func photoView() -> Image {
        if let photo, let nsImage = NSImage(data: photo) {
            return Image(nsImage: nsImage)
        } else {
            return Image(systemName: "photo.on.rectangle")
        }
    }

    private func footer() -> some View {
        HStack {
            SelectImageButton { url in
                selectImage(from: url)
            }

            Spacer()

            PhotosPicker(selection: $selectedPhoto, matching: .any(of: [.images])) {
                Label("Photos", systemImage: "photo.on.rectangle")
            }

            if viewModel.hasImage() {
                Spacer()

                Button {
                    pasteImage()
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard.fill")
                }
            }
        }
    }

    private func selectImage(from url: URL) -> Void {
        guard let data = try? Data(contentsOf: url) else {
            return
        }

        if let resized = viewModel.tryResize(image: data) {
            photo = resized
        } else if let decoded = SDImageWebPCoder.shared.decodedImage(with: data, options: nil)?.tiffRepresentation {
            photo = viewModel.tryResize(image: decoded) ?? decoded
        }
    }

    private func pasteImage() -> Void {
        viewModel.paste { data, error in
            if let data = data {
                photo = data
            } else {
                if let localizedDescription = error?.localizedDescription {
                    details = localizedDescription
                }
                failed.toggle()
            }
        }
    }

}
