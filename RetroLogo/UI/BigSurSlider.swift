//
//  BigSurSlider.swift
//
//  Created by Aditya Rudrapatna on 18/08/2020.
//  Copyright © 2020 Aditya Rudrapatna. All rights reserved.
//

import SwiftUI

struct BigSurSlider: View {

    @Binding var percentage: Float // a number from 0 to 100
    @Binding var sliderWidth: Float
    @Binding var sliderHeight: Float
    
    let myGray: Color = Color(red: 0.5, green: 0.5, blue: 0.5)
    
    @Binding var image: String // name of the image

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .foregroundColor(self.myGray.opacity(0.5))
                
                // Fill and knob
                ZStack(alignment: .leading) {
                    // Filled portion with rounded ends (extends 2px beyond knob center)
                    RoundedRectangle(cornerRadius: CGFloat(self.sliderHeight / 2))
                        .foregroundColor(.white)
                        .frame(width: max(CGFloat(self.sliderHeight), geometry.size.width * CGFloat(self.percentage / 100) + 6))
                    
                    // Knob circle
                    Circle()
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                        .frame(width: CGFloat(self.sliderHeight), height: CGFloat(self.sliderHeight))
                        .offset(x: min(geometry.size.width - CGFloat(self.sliderHeight), max(0, geometry.size.width * CGFloat(self.percentage / 100) - CGFloat(self.sliderHeight / 2))))
                }
            }
            .frame(width: CGFloat(self.sliderWidth), height: CGFloat(self.sliderHeight))
            .cornerRadius(CGFloat(self.sliderHeight / 2))
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(self.sliderHeight / 2))
                    .stroke(self.myGray, lineWidth: 0.5)
            )
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged({ value in
                    self.percentage = min(max(0, Float(value.location.x / geometry.size.width * 100)), 100)
                }))
            .animation(.easeOut, value: percentage)
        }
        .frame(width: CGFloat(sliderWidth), height: CGFloat(sliderHeight))
    }
}
