import SpriteKit

/// Handle car spawning
class CarSpawner{
    static let shared = CarSpawner()

    var targetScene: SKScene?
   
    var cars = Array<Car>()
    
    var spawnTimer: Timer?
    var spawnInterval: TimeInterval = 0.75
    var spawnIntervalDecrement: CGFloat = 0.05
    
    var possibleCars: [SKTexture]?
    var possibleLanes: [CGPoint]?
    var carShadowTexture: SKTexture?
    var carSpeed: CGFloat = 1
    var carScale: CGFloat = 1
   
    /// Configures the car spawner with the parameters it needs.
    public func configure(targetScene: SKScene, possibleCars: [SKTexture]?, possibleLanes: [CGPoint]?, carShadow: SKTexture?, carSpeed: CGFloat, carScale: CGFloat){
        self.targetScene = targetScene
        self.possibleCars = possibleCars
        self.possibleLanes = possibleLanes
        self.carShadowTexture = carShadow
        self.carSpeed = carSpeed
        self.carScale = carScale
    }
    
    @objc func spawnCar(){
        if self.targetScene == nil || self.possibleCars == nil || self.possibleLanes == nil {
            return
        }
        
        // Pick a random lane and car
        let chosenLane: CGPoint = self.possibleLanes![Int.random(in: 0..<self.possibleLanes!.count)]
        let chosenCarTexture: SKTexture = possibleCars![Int.random(in: 0..<possibleCars!.count)]
   
        // Create the car
        let newCar = Car(
            scale: self.carScale,
            texture: chosenCarTexture,
            shadow: carShadowTexture,
            target: targetScene!,
            startPos: CGPoint(x: chosenLane.x, y: targetScene!.frame.height + chosenCarTexture.size().height * carScale),
            startVel: CGVector(dx: 0, dy: -carSpeed)
        )
       
        // Keep track of it
        cars.append(newCar)
    }
   
    /// Begin spawning cars, giving it a set of possible lanes to pick from
    func start(){
        if self.targetScene == nil {
            return
        }
       
        // The target is where the selector is! Make sure the method of #selector is part of target
        spawnTimer = Timer.scheduledTimer(
            timeInterval: spawnInterval,
            target: self,
            selector: #selector(spawnCar),
            userInfo: nil,
            repeats: true
        )
    }
   
    /// Stop spawning cars
    func stop(){
        if self.spawnTimer != nil {
            self.spawnTimer?.invalidate()
            self.spawnTimer = nil
        }
    }
   
    public func clearCars(){
        // Detach all cars from the parent scene
        for car in cars {
            car.entity.removeFromTarget()
        }
       
        // Then clear all active cars
        cars.removeAll()
    }
    
    public func updateCars(){
        if cars.isEmpty {
            return
        }
       
        var i = 0
        while i < cars.count {
            let currentCar = cars[i]

            // Remove car if off screen
            if currentCar.entity.node.position.y <= -currentCar.entity.node.frame.height / 2 {
                // Remove from scene
                currentCar.entity.removeFromTarget()
                
                // Remove from tracker array, which should mark it for garbage collection
                cars.remove(at: i)
            }
           
            // If not, update it!
            else{
                currentCar.entity.update()
              
                // Make cars respond to velocity changes in real time
                currentCar.entity.node.physicsBody?.velocity = CGVector(dx: 0, dy: -carSpeed)
                
                i = i + 1
            }
        }
    }
}
