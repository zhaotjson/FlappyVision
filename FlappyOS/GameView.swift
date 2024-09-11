//
//  GameView.swift
//  testing
//
//  Created by Jason Zhao on 8/19/24.
//


import SwiftUI
import RealityKit
import RealityKitContent

struct GameView: View {
    
    
    
    //Offset Counter
    @State private var poleOffset: Float = 0.0
    
    
    
    @EnvironmentObject var poleSettings: PoleSettings
    @Environment(\.openWindow) var openWindow
    
    // Constants
    let poleWidth: Float = 0.5
    let gapHeight: Float = 0.4
    let poleSpacing: Float = 0.5
    let numberOfPoles: Int = 4
    let poleHeightRange: ClosedRange<Float> = 0.15...1.35
    let totalHeight: Float = 1.5
    let maxGapDeviation: Float = 0.5  // Maximum deviation for gap position
    let verticalShift: Float = 1    // Amount to shift vertically
    
    var body: some View {
        RealityView { content in
            
            
            
            /*
             Generate Poles
             */
            var previousGapCenterY: Float? = nil
            var firstPoleXPosition: Float = 0
            
            for i in 0..<numberOfPoles {
                var gapCenterY: Float
                
                if let previousGapY = previousGapCenterY {
                    // Ensure the gapCenterY is within the deviation range
                    gapCenterY = Float.random(in: max(previousGapY - maxGapDeviation, poleHeightRange.lowerBound)...min(previousGapY + maxGapDeviation, poleHeightRange.upperBound))
                } else {
                    // For the first pole, choose randomly within the range
                    gapCenterY = Float.random(in: poleHeightRange)
                    firstPoleXPosition = Float(i) * poleSpacing
                }
                
                previousGapCenterY = gapCenterY
                
                // Use scaleFactor in scaling
                let bottomPoleHeight = (gapCenterY - (gapHeight / 2))
                let topPoleHeight = (totalHeight - gapCenterY - (gapHeight / 2))
                
                print(bottomPoleHeight)
                print(topPoleHeight)
                
                guard let bottomPole = await createPole(
                    scale: [poleWidth, bottomPoleHeight * 5, poleWidth],
                    translation: [Float(i) * poleSpacing, bottomPoleHeight / 2 + verticalShift, -1] // Shift up
                ) else {
                    continue
                }
                
                guard let topPole = await createPole(
                    scale: [poleWidth, topPoleHeight * 5, poleWidth],
                    translation: [Float(i) * poleSpacing, totalHeight - topPoleHeight / 2 + verticalShift, -1] // Shift up
                ) else {
                    continue
                }
                
                
                
                content.add(bottomPole)
                content.add(topPole)
            }
            
            
            
            
            
            
            
            // Display Bird
            guard let bird = await createBird() else {
                return
            }
            bird.transform.translation = [firstPoleXPosition - 1, 0.75 + verticalShift, -1] // Shift up
            bird.name = "Bird"
            content.add(bird)
            
            
            
            // Display Walls
            
            guard let botWall = await createWall() else {
                return
            }
            botWall.transform.translation = [0, verticalShift - 0.1, -1]
            content.add(botWall)
            
            guard let topWall = await createWall() else {
                return
            }
            topWall.transform.translation = [0, 1.5 + verticalShift, -1]
            content.add(topWall)
            
            
            
            
            
            // Display Skybox
            guard let skyBox = createSkyBox() else {
                return
            }
            content.add(skyBox)
            
            
            
            
            
            
            
        } update: { content in
            // Update pole based on height variable
            // updatePole(with: poleSettings.height, content: content)
        }
        .onAppear(perform: {
            // Display height selector
            // openWindow(id: "Height Selector")
        })
    }
}







/*
 
 PRIVATE FUNCTIONS
 
 
 */





/*
 
 Generate Skybox Environment
 
 */
private func createSkyBox() -> Entity? {
    // Mesh (large sphere)
    let skyBoxMesh = MeshResource.generateSphere(radius: 5000)
    
    // Material (skybox image)
    var skyBoxMaterial = UnlitMaterial()
    guard let skyBoxTexture = try? TextureResource.load(named: "Clouds") else {return nil}
    
    skyBoxMaterial.color = .init(texture: .init(skyBoxTexture))
    
    // Entity
    let skyBoxEntity = Entity()
    skyBoxEntity.components.set(ModelComponent(mesh: skyBoxMesh, materials: [skyBoxMaterial]))
    
    skyBoxEntity.name = "SkyBox"
    
    // Map image to inner surface of sphere
    skyBoxEntity.scale = .init(x: -1, y: 1, z: 1)
    
    return skyBoxEntity
}


/*
 
 Generate Bird
 
 */
private func createBird() async -> Entity? {
    // Get Bird Model
    if let newBird = try? await Entity(named: "bullfinch") {
        return newBird
    } else {
        return nil
    }
}


/*
 
 Generate Pole with user inputs
 
 */
private func createPole(scale: SIMD3<Float>, translation: SIMD3<Float>) async -> Entity? {
    // Get Pole Model
    if let newPole = try? await Entity(named: "Pole") {
        await MainActor.run {
            // Apply the scale and translation
            newPole.transform.scale = scale
            newPole.transform.translation = translation
        }
        return newPole
    } else {
        return nil
    }
}




/*
 
 Generate Bottom and top Walls
 
 */
private func createWall() async -> Entity? {
    
    //Get Wall Model
    if let newWall = try? await Entity(named: "Block") {
        await MainActor.run {
            
            newWall.transform.scale.x = 15
            
        }
        return newWall
    } else {
        return nil
    }
    
}








/*
private func updatePole(with newHeight: Float, content:RealityViewContent) {
    
    
    //Update pole height based on input
    let pole = content.entities.first { entity in
        entity.name == "Pole1"
    }
    
    
    pole?.transform.scale.y = newHeight
    
    
    
    
}
 */
