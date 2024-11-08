import SpriteKit
import GameplayKit

enum GameObjectType: UInt32 {
    case background = 0
    case shadow = 1
    case car = 2
    case player = 3
    case spider = 4
    case gui = 5
}

/// Simple linear interpolation; use with movement!
func lerp(_ start: CGFloat, _ end: CGFloat, _ t: CGFloat) -> CGFloat{
    return (1 - t) * start + t * end
}

class Entity{
    public var type: GameObjectType
    public var node: SKSpriteNode
    public var shadow: SKSpriteNode?

    init(scale: CGFloat, texture: SKTexture, shadow: SKTexture?, target: SKScene, type: GameObjectType, startPos: CGPoint = CGPoint(x: 0, y: 0), startRotation: CGFloat = 0){
        self.type = type
       
        // Setup body node and initialize shadow node
        node = SKSpriteNode(texture: texture)
     
        // A shadow may not be given!
        if shadow != nil {
            self.shadow = SKSpriteNode(texture: shadow)
        }

        // Scale them
        node.setScale(scale)
        
        if let entityShadow = self.shadow {
            entityShadow.setScale(scale)
        }

        // Finish setting up the node first
        
        // Position & rotate
        node.position = startPos
        node.zPosition = CGFloat(type.rawValue)
        node.zRotation = startRotation
        
        // Setup its physics body
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.isDynamic = true
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.categoryBitMask = type.rawValue
    
        switch type {
        case .player:
            node.physicsBody?.contactTestBitMask = GameObjectType.car.rawValue | GameObjectType.spider.rawValue
        default:
            node.physicsBody?.contactTestBitMask = 0
        }
       
        // Add to scene
        target.addChild(node)
       
        // Now finish configuring and adding the shadow
        if let entityShadow = self.shadow {
            entityShadow.position = node.position
            entityShadow.zPosition = CGFloat(GameObjectType.shadow.rawValue)
            entityShadow.zRotation = node.zRotation
            entityShadow.alpha = 0.2
            
            target.addChild(entityShadow)
        }
    }

    public func removeFromTarget(){
        // Remove body and shadow nodes from the parent
        node.removeFromParent()
        if shadow != nil {
            shadow?.removeFromParent()
        }
    }
    
    /// Keep shadow on the caster
    public func update(){
        // MARK: The car uses its physics body to move, and it seems to cause this shadow to be off-center...
        if shadow != nil {
            shadow!.position = node.position
            shadow!.zRotation = node.zRotation
        }
    }
}
