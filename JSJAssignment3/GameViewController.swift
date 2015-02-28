//
//  GameViewController.swift
//  JSJAssignment3
//
//  Created by ch484-mac7 on 2/27/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion

class GameViewController : UIViewController {
    var scene : SCNScene!
    var cameraNode : SCNNode!
    var wallNode: SCNNode!
    var motionManager : CMMotionManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup environment
        setupWorld()
        
        // Detect taps
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        view.gestureRecognizers = [tapRecognizer]
        
        // Detect motion
        motionManager = CMMotionManager()
        motionManager.deviceMotionUpdateInterval = 0.1
        
        motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.currentQueue())
            {
                (deviceMotion, error) -> Void in
                
                let accel = deviceMotion.gravity
                let userAccel = deviceMotion.userAcceleration
                
                let accelX = Float(9.8 * accel.x + userAccel.x*9.8)
                let accelY = Float(9.8 * accel.y + userAccel.y*9.8)
                let accelZ = Float(9.8 * accel.z + userAccel.z*9.8)
                
                self.scene.physicsWorld.gravity = SCNVector3(x: accelX, y: accelY, z: accelZ)
                
        }
    }
    
    
    func setupWorld() {
        
        // Setup scene
        scene = SCNScene()
        scene.physicsWorld.speed = 1
        
        // Setup camera position
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 30)
        //cameraNode.eulerAngles.z -= 0.5
        scene.rootNode.addChildNode(cameraNode)
        
        
        // add a plane to the view that users must bounce the ball on
        //setup the geometry of node (as a plane)
        let wall = SCNTube(innerRadius: 4.9, outerRadius: 5, height: 10)
        wall.firstMaterial?.doubleSided = true
        wall.firstMaterial?.diffuse.contents = UIColor.redColor() // make it red!!
        
        // add the plane to the world as a static body (no dynamic physics)
        wallNode = SCNNode()
        wallNode.geometry = wall
        wallNode.physicsBody = SCNPhysicsBody.staticBody()
        wallNode.position = SCNVector3(x: 0.0, y: 0.0, z: -5)
        
        scene.rootNode.addChildNode(wallNode)
        
        // Setup view
        let view = self.view as SCNView
        view.scene = scene
        
        
    }
    
    func addBall() {
        
        // add a sphere to the world
        let ballGeometry = SCNSphere(radius: 1.0)
        
        // make it have Eric's picture
        let ballMaterial = SCNMaterial()
        ballMaterial.diffuse.contents = UIImage(named: "texture")
        
        // adjust physics to make it slightly highly bouncy
        let ball = SCNNode(geometry: ballGeometry)
        ball.geometry?.firstMaterial = ballMaterial;
        ball.physicsBody = SCNPhysicsBody.dynamicBody()
        ball.physicsBody?.restitution = 2.5
        ball.position = SCNVector3(x: 0, y: 10, z: -5)
        
        scene.rootNode.addChildNode(ball)
        
    }
    
    // add balls to scene at will!!!
    func handleTap(sender: AnyObject) {
        addBall()
    }
}
