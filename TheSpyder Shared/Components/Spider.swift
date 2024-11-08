import SpriteKit

class Spider{
    var entity: Entity
    var attackTimer: Timer!
    
    let attackInterval: TimeInterval = 5
    let peekDuration: TimeInterval = 3.0
    let snatchDuration: TimeInterval = 0.5
    
    var possibleAttackTargets = Array<CGPoint>()

    let smoothTime = 7.5
    var targetPos: CGPoint
   
    var isFrozen = false
    
    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, target: SKScene){
        // Start spider offscreen
        let startPos = CGPoint(x: 0, y: -texture.size().height * scale)
        
        // Set up entity
        self.entity = Entity(scale: scale, texture: texture, shadow: shadow, target: target, type: GameObjectType.spider, startPos: startPos)
       
        // Set lerp position to default
        self.targetPos = startPos
    }
   
    /// Run sequence of spider attack to a given point
    @objc func attack(){
        if possibleAttackTargets.isEmpty {
            return
        }
      
        // Pick random attack target
        let attackTarget = possibleAttackTargets[Int.random(in: 0..<possibleAttackTargets.count)]
        
        // Move to peek
        let moveToPeek = SKAction.run {
            self.targetPos.x = attackTarget.x
            self.targetPos.y = 0
        }
        
        // Stay peeked for a bit
        let stayPeeked = SKAction.wait(forDuration: peekDuration)
        
        // Then snatch!
        let snatch = SKAction.run {
            self.targetPos.x = attackTarget.x
            self.targetPos.y = attackTarget.y
        }
        
        // Stay in snatching position for a bit
        let staySnatched = SKAction.wait(forDuration: snatchDuration)
        
        // Move back down
        let moveBackDown = SKAction.run {
            self.targetPos.x = self.entity.node.parent == nil ? 0 : self.entity.node.parent!.frame.midX
            self.targetPos.y = -self.entity.node.frame.height
        }
   
        // Start the timer again
        let restartTimer = SKAction.run {
            self.attackTimer = Timer.scheduledTimer(withTimeInterval: self.attackInterval, repeats: false) { timer in
                timer.invalidate()
                self.attack()
            }
        }
        
        // Run sequence
        let sequence = [
            moveToPeek,
            stayPeeked,
            snatch,
            staySnatched,
            moveBackDown,
            restartTimer
        ]
        
        self.entity.node.run(SKAction.sequence(sequence))
    }
       
    private func lerpMove(with deltaTime: CGFloat){
        entity.node.position.x = lerp(entity.node.position.x, targetPos.x, smoothTime * deltaTime)
        entity.node.position.y = lerp(entity.node.position.y, targetPos.y, smoothTime * deltaTime)
    }

    public func start(){
        // Run the timer; doesn't repeat because it restarts itself
        self.attackTimer = Timer.scheduledTimer(timeInterval: self.attackInterval, target: self, selector: #selector(self.attack), userInfo: nil, repeats: false)
    }
  
    public func stop(){
        // Remove any queued events
        self.entity.node.removeAllActions()
        
        // Stop the timer
        if self.attackTimer != nil {
            self.attackTimer.invalidate()
            self.attackTimer = nil
        }
    }
    
    public func setFrozen(to status: Bool){
        // Don't re-run already set state transition
        if status == isFrozen {
            return
        }

        isFrozen = status
        
        if isFrozen == true {
            // Pause any running actions
            self.entity.node.isPaused = true
        }
       
        else {
            // Unpause running actions
            self.entity.node.isPaused = false
        }
    }
    
    public func moveOffscreen(){
        // Teleport spider offscreen
        self.targetPos.x = self.entity.node.parent == nil ? 0 : self.entity.node.parent!.frame.midX
        self.targetPos.y = -self.entity.node.frame.height
        
        self.entity.node.position.x = self.targetPos.x
        self.entity.node.position.y = self.targetPos.y
    }
    
    public func update(with deltaTime: CGFloat){
        if !isFrozen {
            lerpMove(with: deltaTime)
        }
        
        entity.update()
    }
}
