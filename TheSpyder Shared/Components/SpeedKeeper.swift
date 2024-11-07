import SpriteKit

/// Keeps track of the game speed
class SpeedKeeper{
    static let shared = SpeedKeeper()

    var speed: CGFloat = 600
    var speedupAmount: CGFloat = 120
    var scoreUntilSpeedup: Int = 50
    var scoreUntilSpeedupIncrement: Int = 100

    var lastSpeedBeforeFreeze: CGFloat = 0
    var isFrozen = false
    
    /// Update the speed based on given score
    public func update(){
        if !isFrozen {
            // Set speed to what it was before last freeze
            if lastSpeedBeforeFreeze != 0 {
                speed = lastSpeedBeforeFreeze
                lastSpeedBeforeFreeze = 0
            }

            // Make currently spawned cars respond instantly to speed changes, always, as long as this isn't frozen
            CarSpawner.shared.carSpeed = speed - 30

            // If current score exceeds speedup threshold, increase game speed and score multiplier
            if ScoreKeeper.shared.score >= scoreUntilSpeedup {
                
                speed += speedupAmount
                scoreUntilSpeedup += scoreUntilSpeedupIncrement
               
                CarSpawner.shared.spawnInterval -= CarSpawner.shared.spawnIntervalDecrement

                ScoreKeeper.shared.multiplier += ScoreKeeper.shared.multiplierIncrement
            }
        }
        
        else if isFrozen {
            // Keep record of speed before freeze and set it to 0 for now
            if lastSpeedBeforeFreeze == 0 {
                lastSpeedBeforeFreeze = speed
                speed = 0
            }
               
            // Make spawned cars respond to that change
            CarSpawner.shared.carSpeed = 0
        }
    }

    public func reset(){
        speed = 600
        scoreUntilSpeedup = 50
    }
}
