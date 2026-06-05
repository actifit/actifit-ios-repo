//
//  NetworkImage.swift
//  Actifit
//
//  Created by Ali Jaber on 11/10/2024.
//

import SwiftUI

struct NetworkImage: View {
    let imageURL: URL

    var body: some View {
        AsyncImage(url: imageURL) { phase in
            if let image = phase.image {
                // Display the image if it successfully loads
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if phase.error != nil {
                // Display an error view if something goes wrong
                Text("Failed to load image")
            } else {
                // Display a placeholder while the image is loading
                ProgressView()
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        // You can adjust the frame as needed
    }
}

#Preview {
    NetworkImage(imageURL: URL(string: "")!)
}
