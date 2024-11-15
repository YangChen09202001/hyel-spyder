import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    enum GameState {
        case title
        case inGame
        case gameOver
    }

    var gameState: GameState!
    
    var globalScale: CGFloat = 1

    var lastUpdateTime: TimeInterval = 0
    var deltaTime: CGFloat = 0
    
    let tBackground = SKTexture(imageNamed: "road")
    let tTitle = SKTexture(imageNamed: "logo")
    let tGameOver = SKTexture(imageNamed: "game_over")
    let tPlayer = SKTexture(imageNamed: "player")
    let tSpider = SKTexture(imageNamed: "spider")
    let tShadow = SKTexture(imageNamed: "shadow")
    let tCars = [
        SKTexture(imageNamed: "car_g"),
        SKTexture(imageNamed: "car_o"),
        SKTexture(imageNamed: "car_r"),
        SKTexture(imageNamed: "car_y")
    ]

    var backgroundA: SKSpriteNode!
    var backgroundB: SKSpriteNode!

    var titleCard: SKSpriteNode!
    var gameOverCard: SKSpriteNode!
    
    var player: Player!
    var spider: Spider!
   
    var swipeLeft: UISwipeGestureRecognizer!
    var swipeRight: UISwipeGestureRecognizer!
    var tap: UITapGestureRecognizer!
    
    let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    override func didMove(to view: SKView) {
        // Load sound effects
        AudioManager.shared.loadAudio(filename: "switch", fileExtension: "mp3")
        AudioManager.shared.loadAudio(filename: "peek", fileExtension: "mp3")
        AudioManager.shared.loadAudio(filename: "hide", fileExtension: "mp3")
        AudioManager.shared.loadAudio(filename: "attack", fileExtension: "mp3")
        AudioManager.shared.loadAudio(filename: "crash", fileExtension: "mp3")
        // The global scale is based on how much we need to scale the background by to cover the whole scene's frame
        let xScaleFactor = view.frame.width / tBackground.size().width
        let yScaleFactor = view.frame.height / tBackground.size().height
        
        globalScale = max(xScaleFactor, yScaleFactor)
   
        // Set up the scene and its components
        self.physicsWorld.contactDelegate = self // Make contact tests take place in this scene
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0) // Remove gravity
           
        // Set up swipe and tap recognizers and add them to the scene
        swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:))) // The _: effectively makes it so the recognizer passes itself into HandleSwipe
        swipeLeft.direction = .left
       
        view.addGestureRecognizer(swipeLeft)

        swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
       
        view.addGestureRecognizer(swipeRight)

        tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))

        view.addGestureRecognizer(tap)
        
        // Make all textures resize as nearest neighbor
        tBackground.filteringMode = .nearest
        tTitle.filteringMode = .nearest
        tGameOver.filteringMode = .nearest
        tPlayer.filteringMode = .nearest
        tSpider.filteringMode = .nearest
        tShadow.filteringMode = .nearest
        
        for texture in tCars {
            texture.filteringMode = .nearest
        }
       
        // Setup title
        titleCard = SKSpriteNode(texture: tTitle)
        
        titleCard.setScale(globalScale * 0.20)
        titleCard.zPosition = CGFloat(GameObjectType.gui.rawValue)
        titleCard.position = CGPoint(
            x: view.frame.midX,
            y: view.frame.midY + titleCard.frame.height / 2
        )
        
        addChild(titleCard)
        
        // Setup game over card
        gameOverCard = SKSpriteNode(texture: tGameOver)
        
        gameOverCard.setScale(globalScale * 0.2)
        gameOverCard.zPosition = CGFloat(GameObjectType.gui.rawValue)
        gameOverCard.position = CGPoint(
            x: view.frame.midX,
            y: view.frame.midY + gameOverCard.frame.height / 2
        )
        
        addChild(gameOverCard)
        
        // Setup background A
        backgroundA = SKSpriteNode(texture: tBackground)

        backgroundA.setScale(globalScale)
        backgroundA.zPosition = CGFloat(GameObjectType.background.rawValue)
        backgroundA.position = CGPoint(
            x: view.frame.width / 2,
            y: view.frame.height / 2
        )
       
        addChild(backgroundA)

        // Setup background B
        backgroundB = backgroundA.copy() as? SKSpriteNode
       
        backgroundB.position.y = backgroundA.position.y + backgroundA.size.height
       
        addChild(backgroundB)
       
        // Setup player
        player = Player(
            scale: globalScale * 0.8,
            texture: tPlayer,
            shadow: tShadow,
            target: self,
            startPos: CGPoint(
                x: view.frame.width / 2,
                y: (tPlayer.size().height * 0.8 * globalScale / 2) + (30 * globalScale) // MARK: This calculation is being done by hand, using magic numbers that pertain to things that should be variables...
            )
        )
        
        player.calculateLanes(
            scale: globalScale,
            offshoot: (backgroundA.frame.width - view.frame.width) * 0.5, // MARK: Everything should be in unscaled pixel coordinates; is this?
            pad: 18,
            laneWidth: 22,
            laneCount: 3
        )

        // Setup spider
        spider = Spider(
            scale: globalScale,
            texture: tSpider,
            shadow: nil,
            target: self
        )
        
        spider.possibleAttackTargets = player.lanes
        
        // Setup score keeper
        ScoreKeeper.shared.addLabelToScene(self)
       
        // Setup car spawner
        CarSpawner.shared.configure(
            targetScene: self,
            possibleCars: tCars,
            possibleLanes: player.lanes,
            carShadow: tShadow,
            carSpeed: SpeedKeeper.shared.speed - 30,
            carScale: globalScale * 0.8
        )
        
        // Set game state to title screen
        setGameState(to: .title)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        // Flag collision if the player collides with a car or the spider
        var body1: SKPhysicsBody
        var body2: SKPhysicsBody

        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            body1 = contact.bodyA
            body2 = contact.bodyB
        }
        
        else {
            body1 = contact.bodyB
            body2 = contact.bodyA
        }

        let playerIsBody1 = (body1.categoryBitMask & player.entity.node.physicsBody!.categoryBitMask) != 0
        let spiderIsBody2 = (body2.categoryBitMask & spider.entity.node.physicsBody!.categoryBitMask) != 0
        
        // Check collision with spider first
        if playerIsBody1 && spiderIsBody2 {
            setGameState(to: .gameOver)
            AudioManager.shared.playSound("crash")
        }

        // If not, check collision with cars
        else {
            for car in CarSpawner.shared.cars {
                if contact.bodyA.categoryBitMask > contact.bodyB.categoryBitMask {
                    body1 = contact.bodyA
                    body2 = contact.bodyB
                } else {
                    body1 = contact.bodyB
                    body2 = contact.bodyA
                }
             
                let playerIsBody1 = body1.categoryBitMask & player.entity.node.physicsBody!.categoryBitMask != 0
                let carIsBody2 = body2.categoryBitMask & car.entity.node.physicsBody!.categoryBitMask != 0
                
                if playerIsBody1 && carIsBody2 {
                    setGameState(to: .gameOver)
                    AudioManager.shared.playSound("crash")
                }
            }
        }
    }
 
    /// Set game state, making in-game elements respond accordingly
    func setGameState(to state: GameState){
        // Prevent looping transitions
        if state == gameState {
            return
        }

        gameState = state
    
        // MARK: The actions taken in each case have been shoddily put there after testing and seeing what fails, and assuming the only flow is title -> inGame -> gameOver -> title -> ...
        // TODO: Ensure transition actions are robust!
        
        switch state {
        case .title:
            gameOverCard.isHidden = true
            titleCard.isHidden = false

            player.recenter()
            player.isFrozen = false // TODO: Make player use similar freezing protocol to spider

            spider.stop()
            spider.moveOffscreen()
            spider.setFrozen(to: false)

            CarSpawner.shared.stop()
            CarSpawner.shared.clearCars()

            ScoreKeeper.shared.reset()
            ScoreKeeper.shared.label.isHidden = true

            SpeedKeeper.shared.reset()
            SpeedKeeper.shared.isFrozen = false
        case .inGame:
            gameOverCard.isHidden = true
            titleCard.isHidden = true

            spider.start()
            
            CarSpawner.shared.start()
            
            ScoreKeeper.shared.start()
            ScoreKeeper.shared.label.isHidden = false
        case.gameOver:
            gameOverCard.isHidden = false
            titleCard.isHidden = true
       
            player.isFrozen = true
            spider.setFrozen(to: true)
            
            SpeedKeeper.shared.isFrozen = true

            ScoreKeeper.shared.label.isHidden = true
            
            CarSpawner.shared.stop()
        }
    }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer){
        // Play haptic feedback
        hapticFeedback.impactOccurred()
        AudioManager.shared.playSound("peek") // Example: Play "peek" sound on right swipe
        // No actions save for a tap to reset should be taken in game over
        if gameState == .gameOver {
            return
        }
        
        // If is in title screen, begin game!
        if gameState == .title {
            setGameState(to: .inGame)
        }
       
        // Change player direction
        player.changeDirection(to: gesture.direction)
    }
  
    @objc func handleTap(_ tap: UITapGestureRecognizer){
        if gameState == .gameOver {
            setGameState(to: .title)
        }
    }
    
    func scrollBackground(){
        let dy = SpeedKeeper.shared.speed * deltaTime
                
        // Move to bottom until off-screen, move to top and restart
        backgroundA.position.y -= dy
        backgroundB.position.y -= dy
       
        if backgroundA.position.y <= -backgroundA.size.height / 2 {
            backgroundA.position.y = backgroundB.position.y + backgroundB.size.height - dy
        }

        if backgroundB.position.y <= -backgroundB.size.height / 2 {
            backgroundB.position.y = backgroundA.position.y + backgroundA.size.height - dy
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Avoid very large initial deltaTime
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
    
        deltaTime = currentTime - lastUpdateTime as CGFloat // MARK: This starts tweaking when we've left the app for a long time; set it correctly in some sort of callback?

        // Run game functionality here
        // MARK: Functionality assignment is borked; need to cleanly establish what triggers what, and so on... But it works for now!
        
        scrollBackground()
        player.update(with: deltaTime)
        spider.update(with: deltaTime)
        CarSpawner.shared.updateCars()
        SpeedKeeper.shared.update()
                
        lastUpdateTime = currentTime
    }
}
