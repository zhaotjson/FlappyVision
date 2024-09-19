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
    
    @EnvironmentObject var poleSettings: PoleSettings
    @Environment(\.openWindow) var openWindow
    
    // Constants
    let poleWidth: Float = 0.5
    let gapHeight: Float = 0.4
    let poleSpacing: Float = 0.5
    let numberOfPoles: Int = 6
    let poleHeightRange: ClosedRange<Float> = 0.15...1.35
    let totalHeight: Float = 1.5
    let maxGapDeviation: Float = 0.5  // Maximum deviation for gap position
    let verticalShift: Float = 1      // Amount to shift vertically
    
    @State private var poleOffset: Float = -2.5   // Track how much the poles have moved to the left
    @State private var poleEntities: [Entity] = [] // To keep track of pole entities
    @State private var previousGapCenterY: Float? = nil // Track previous gap center Y
    @State private var animationTimer: Timer? = nil // Timer for continuous updates
    
    var body: some View {
        RealityView { content in
            // Make the RealityView content closure async
            await generatePoles(content: content)
            
            // Display Bird
            guard let bird = await createBird() else {
                return
            }
            bird.transform.translation = [-1, 0.75 + verticalShift, -1] // Shift up
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
            // Nothing needed here for now
        }
        .onAppear {
            startPoleMovement() // Start movement after the view appears
        }
        .onDisappear {
            stopPoleMovement() // Stop movement when view disappears
        }
    }

    /*
     
     PRIVATE FUNCTIONS
     
     */
    
    private func calculateGapCenterY(previousGapCenterY: Float?) -> Float {
        if let previousGapY = previousGapCenterY {
            // Ensure the gapCenterY is within the deviation range
            return Float.random(in: max(previousGapY - maxGapDeviation, poleHeightRange.lowerBound)...min(previousGapY + maxGapDeviation, poleHeightRange.upperBound))
        } else {
            // For the first pole, choose randomly within the range
            return Float.random(in: poleHeightRange)
        }
    }
    
    private func generatePoles(content: RealityViewContent) async {
        previousGapCenterY = nil // Reset previousGapCenterY for initial generation
        poleEntities.removeAll() // Clear previous poles

        for i in 0..<numberOfPoles {
            let gapCenterY = calculateGapCenterY(previousGapCenterY: previousGapCenterY)
            previousGapCenterY = gapCenterY
            
            let bottomPoleHeight = (gapCenterY - (gapHeight / 2))
            let topPoleHeight = (totalHeight - gapCenterY - (gapHeight / 2))
            
            guard let bottomPole = await createPole(
                scale: [poleWidth, bottomPoleHeight * 5, poleWidth],
                translation: [Float(i) * poleSpacing, bottomPoleHeight / 2 + verticalShift, -1] // No offset initially
            ) else {
                continue
            }
            
            guard let topPole = await createPole(
                scale: [poleWidth, topPoleHeight * 5, poleWidth],
                translation: [Float(i) * poleSpacing, totalHeight - topPoleHeight / 2 + verticalShift, -1] // No offset initially
            ) else {
                continue
            }
            
            // Add poles to the content and track them
            content.add(bottomPole)
            content.add(topPole)
            poleEntities.append(bottomPole)
            poleEntities.append(topPole)
        }
    }
    
    private func startPoleMovement() {
        let removalThreshold: Float = -1.5 // Threshold for repositioning poles to the right
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            poleOffset += 0.005
            
            Task {
                await MainActor.run {
                    var polesToReuse: [Int] = []
                    var furthestRightX: Float = -Float.infinity
                    
                    for pole in poleEntities {
                        if pole.transform.translation.x > furthestRightX {
                            furthestRightX = pole.transform.translation.x
                        }
                    }
                    
                    for (index, pole) in poleEntities.enumerated() {
                        let newX = pole.transform.translation.x - 0.005
                        pole.transform.translation.x = newX
                        
                        if newX < removalThreshold {
                            polesToReuse.append(index)
                        }
                    }
                    
                    for index in stride(from: 0, to: polesToReuse.count, by: 2) {
                        guard index + 1 < poleEntities.count else { continue }
                        
                        let newGapCenterY = calculateGapCenterY(previousGapCenterY: previousGapCenterY)
                        previousGapCenterY = newGapCenterY
                        
                        let bottomPoleHeight = (newGapCenterY - (gapHeight / 2))
                        let topPoleHeight = (totalHeight - newGapCenterY - (gapHeight / 2))
                        
                        let newXPosition = furthestRightX + poleSpacing
                        
                        poleEntities[polesToReuse[index]].transform.translation = [newXPosition, bottomPoleHeight / 2 + verticalShift, -1]
                        poleEntities[polesToReuse[index]].transform.scale = [poleWidth, bottomPoleHeight * 5, poleWidth]
                        
                        poleEntities[polesToReuse[index + 1]].transform.translation = [newXPosition, totalHeight - topPoleHeight / 2 + verticalShift, -1]
                        poleEntities[polesToReuse[index + 1]].transform.scale = [poleWidth, topPoleHeight * 5, poleWidth]
                    }
                }
            }
        }
    }
    
    private func stopPoleMovement() {
        // Stop the timer when movement is no longer needed
        animationTimer?.invalidate()
        animationTimer = nil
    }

    // Rest of your code (createSkyBox, createBird, createPole, createWall, etc.) remains unchanged.
}

/*
 
 OTHER OBJECT GENERATION
 
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
            
            newWall.transform.scale.x = 20
            
        }
        return newWall
    } else {
        return nil
    }
}
