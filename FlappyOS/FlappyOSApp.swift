//
//  FlappyOSApp.swift
//  FlappyOS
//
//  Created by Jason Zhao on 8/19/24.
//

import SwiftUI

@main
struct FlappyOSApp: App {
    var body: some Scene {
        
        @ObservedObject var poleSettings = PoleSettings()
        
        //Main Immersive space
        ImmersiveSpace {
            GameView()
                .environmentObject(poleSettings)
        }.immersionStyle(selection: .constant(.full), in: .full)
        
        
        //Height selection window
        WindowGroup(id: "Height Selector") {
            
            HeightSelector()
                .environmentObject(poleSettings)
        }.defaultSize(width: 80, height: 30)
        
    }
}



//Store pole information
class PoleSettings: ObservableObject {
    
    @Published var height: Float = 2.0
    @Published var numObjects: Float = 0.0
    
}
