//
//  SwiftUITests.swift
//  LearningExercises
//
//  Created by Alejandro on 5/27/26.
//

import SwiftUI

struct SwiftUITests: View {
    
    let imageURL =  URL(string: "https://developer.apple.com/assets/elements/icons/swiftui/swiftui-256x256_2x.png")
    
    var body: some View {
        ZStack {
            Color(red: 30 / 255, green: 35 / 255, blue: 45 / 255, opacity: 1)
            
            AsyncImage(url: imageURL) { image in
                image.image?
                    .resizable()
                    .scaledToFit()
                    .padding(.all, 35)
            }
        }
    }
}

#Preview {
    
    ZStack {
        Color.white
        
        SwiftUITests()
            .frame(width: 300, height: 300)
            .cornerRadius(75)
        
    }
        .frame(width: 400, height: 400)

}
