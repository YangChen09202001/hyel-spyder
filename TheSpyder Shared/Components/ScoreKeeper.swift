import SpriteKit

/// Singleton; keeps track of the player's score
class ScoreKeeper{
    static let shared = ScoreKeeper()
    
    var score: Int = 0

    var baseAward: Int = 5
    var awardTimer: Timer!
    var awardInterval: TimeInterval = 1

    var multiplier: CGFloat = 1.0
    var multiplierIncrement: CGFloat = 0.25
    
    var label: SKLabelNode
 
    private init(){
        // MARK: Private initializers prevent external instantiation; useful for singletons!

        // Setup score label
        self.label = SKLabelNode(text: "\(self.score)")

        self.label.fontName = "FFF Forward" // Use the name of the font, not the file name
        self.label.fontSize = 32
        self.label.zPosition = CGFloat(GameObjectType.gui.rawValue)
    }
   
    /// Adds the score label to the target scene
    public func addLabelToScene(_ target: SKScene){
        // Add to target scene
        target.addChild(label)
      
        // Position label using scene dimensions
        self.label.position = CGPoint(x: target.frame.midX, y: target.frame.midY + target.frame.midY / 2)
    }
  
    /// Add current score award times multiplier and update score label to reflect it
    @objc func addScore(){
        score += Int(CGFloat(baseAward) * multiplier)
        label.text = "\(score)"
    }

    /// Start keeping score
    public func start(){
        awardTimer = Timer.scheduledTimer(
            timeInterval: awardInterval,
            target: self,
            selector: #selector(addScore),
            userInfo: nil,
            repeats: true
        )
    }

    /// Stop keeping score
    public func stop(){
        if self.awardTimer != nil {
            self.awardTimer?.invalidate()
            self.awardTimer = nil
        }
    }
   
    /// Reset state
    public func reset(){
        // Stop timer
        self.stop()
       
        // Reset score and multiplier
        score = 0
        multiplier = 1

        // Set the score label accordingly
        label.text = "\(score)"
    }
}
