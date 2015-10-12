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

// Set constants
struct Constants {
    static let BasketHeight: CGFloat = 5.0
    static let BasketThickness: CGFloat = 0.5
    static let BasketYPosition: Float = -16.0
    static let AppleDropHeight: Float = 17.0
}

class GameViewController: UIViewController {
    // Initialize variables
    var scene: SCNScene!
    var cameraNode: SCNNode!
    var cameraOrbit: SCNNode!
    var motionManager: CMMotionManager!
    var timer: NSTimer?
    var dropInterval = 5.0
    var goal = 10
    var basketRadius: CGFloat = 2.0
    
    let standardUserDefaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get goal for user defaults and update basket radius
        self.goal = self.standardUserDefaults.integerForKey("goal") ?? 10
        self.basketRadius = 2.0 + CGFloat(self.goal/500);
        
        // Don't let the basket's radius surpass 8
        if(self.basketRadius > 8.0) {
            self.basketRadius = 8.0;
        }
        
        // Setup environment
        setupWorld()
        
        // Detect motion
        motionManager = CMMotionManager()
        motionManager.deviceMotionUpdateInterval = 0.1
        
        if let queue = NSOperationQueue.currentQueue() {
            motionManager.startDeviceMotionUpdatesToQueue(queue)
                {
                    (deviceMotion, error) -> Void in
                    
                    if deviceMotion != nil && error == nil {
                        let accel = deviceMotion!.gravity
                        let userAccel = deviceMotion!.userAcceleration
                        
                        let accelX = Float(9.8 * accel.x + userAccel.x*9.8)
                        let accelY = Float(9.8 * accel.y + userAccel.y*9.8)
                        let accelZ = Float(9.8 * accel.z + userAccel.z*9.8)
                        
                        self.scene.physicsWorld.gravity = SCNVector3(x: accelX, y: accelY, z: accelZ)
                    }
                    
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        createDropTimer()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.timer?.invalidate()
    }
    
    // Create a timer to periodically call addApple()
    func createDropTimer() {
        self.timer?.invalidate()
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(self.dropInterval,
            target: self,
            selector: Selector("addApple"),
            userInfo: nil,
            repeats: true)
    }
    
    func setupWorld() {
        
        // Setup scene
        scene = SCNScene()
        scene.physicsWorld.speed = 1
        scene.background.contents = UIImage(named: "tree_background")
        
        // Setup camera position
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 9
        camera.zFar = 100
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 30)
        cameraOrbit = SCNNode()
        cameraOrbit.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cameraOrbit)
        
        // Set camera rotation
        cameraOrbit.eulerAngles.x -= Float(M_PI_4/10)
        
        // Add a tube for the walls of the basket
        let wall = SCNTube(innerRadius: self.basketRadius - Constants.BasketThickness, outerRadius: self.basketRadius, height: Constants.BasketHeight)
        wall.firstMaterial?.diffuse.contents = UIImage(named: "basket_texture")
        
        // Make the tube concave so that apples can pass through it
        let wallShape = SCNPhysicsShape(geometry: wall, options: [SCNPhysicsShapeTypeKey: SCNPhysicsShapeTypeConcavePolyhedron])
        
        // Add the tube to the world as a static body (no dynamic physics)
        let wallNode = SCNNode()
        wallNode.geometry = wall
        wallNode.physicsBody = SCNPhysicsBody(type: .Static, shape: wallShape)
        wallNode.position = SCNVector3(x: 0.0, y: Constants.BasketYPosition, z: -5)
        
        // Add a cylinder for the bottom of the basket
        let bottom = SCNCylinder(radius: self.basketRadius, height: Constants.BasketThickness)
        bottom.firstMaterial?.diffuse.contents = UIImage(named: "basket_texture")
        
        // Add the cylinder to the world as a static body (no dynamic physics)
        let bottomNode = SCNNode()
        bottomNode.geometry = bottom
        bottomNode.physicsBody = SCNPhysicsBody.staticBody()
        bottomNode.position = SCNVector3(x: 0.0, y: Constants.BasketYPosition - 2.75, z: -5)
        
        scene.rootNode.addChildNode(wallNode)
        scene.rootNode.addChildNode(bottomNode)
        
        // Setup view
        let view = self.view as! SCNView
        view.scene = scene
        view.autoenablesDefaultLighting = true
        
        // Drop the first apple
        self.addApple()
    }
    
    // Create and drop apples
    func addApple() {
        // If more than 60 apples have been dropped, reset the game
        if (scene.rootNode.childNodes.count > 63) {
            // Delete all apples
            for (var i = 62; i >= 3; i--) {
                let node = scene.rootNode.childNodes[i] as SCNNode
                node.removeFromParentNode()
            }
            
            // Reset interval at which to drop apples
            self.dropInterval = 5.0
            createDropTimer()
        }
        
        // add a sphere to the world
        let ballGeometry = SCNSphere(radius: 1.0)
        
        let ballMaterial = SCNMaterial()
        
        ballMaterial.diffuse.contents = UIImage(named: "apple_texture")
        
        // adjust physics to make it slightly highly bouncy
        let ball = SCNNode(geometry: ballGeometry)
        ball.geometry?.firstMaterial = ballMaterial
        ball.physicsBody = SCNPhysicsBody.dynamicBody()
        ball.physicsBody?.restitution = 0.5
        ball.rotation = SCNVector4(x: randomNumberBetween(-100, max: 100), y: randomNumberBetween(-100, max: 100), z: randomNumberBetween(-100, max: 100), w: randomNumberBetween(-100, max: 100))
        ball.position = SCNVector3(x: randomNumberBetween(-6.0, max: 6.0), y: Constants.AppleDropHeight, z: randomNumberBetween(-5.0, max: 5.0))
        
        scene.rootNode.addChildNode(ball)
        
        // Decrement the interval at which apples will be dropped
        if (self.dropInterval > 0.5) {
            self.dropInterval -= 0.1
            createDropTimer()
        }
    }
    
    // Genereate a random number between a minimum value and a maximum value
    func randomNumberBetween(min: Float, max: Float) -> Float {
        return Float(arc4random()) / Float(UINT32_MAX) * (max - min) + min
    }
}
