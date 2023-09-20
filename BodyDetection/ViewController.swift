/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [-1.0, 0, 0]
    let characterAnchor = AnchorEntity()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButtons()
    }
    
    func setupButtons() {
        // Setup Robot Button
        let robotButton = UIButton(type: .system)
        robotButton.setTitle("Load Robot", for: .normal)
        robotButton.addTarget(self, action: #selector(loadRobotModel), for: .touchUpInside)
        robotButton.frame = CGRect(x: 20, y: view.bounds.height - 60, width: 120, height: 40)
        arView.addSubview(robotButton)
        
        // Setup Pikachu Button
        let pikachuButton = UIButton(type: .system)
        pikachuButton.setTitle("Load Pikachu", for: .normal)
        pikachuButton.addTarget(self, action: #selector(loadPikachuModel), for: .touchUpInside)
        pikachuButton.frame = CGRect(x: view.bounds.width - 140, y: view.bounds.height - 60, width: 120, height: 40)
        arView.addSubview(pikachuButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configuration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        
        arView.scene.addAnchor(characterAnchor)
    }

    @objc func loadRobotModel(_ sender: UIButton) {
        loadModel(named: "character/robot")
    }

    @objc func loadPikachuModel(_ sender: UIButton) {
        loadModel(named: "character/pikachu")
    }

    func loadModel(named modelName: String) {
        // Remove the current character from its anchor and set its reference to nil.
        if let currentCharacter = character {
            characterAnchor.removeChild(currentCharacter)
            character = nil
        }
        
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: modelName).sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
            }, receiveValue: { (entity: Entity) in
                if let loadedCharacter = entity as? BodyTrackedEntity {
                    loadedCharacter.scale = [1.0, 1.0, 1.0]
                    self.character = loadedCharacter
                    self.characterAnchor.addChild(loadedCharacter)
                    cancellable?.cancel()
                } else {
                    print("Error: Unable to load model as BodyTrackedEntity")
                }
            })
    }


    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
            // Update the position of the character anchor's position.
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            characterAnchor.position = bodyPosition
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
   
            if let character = character, character.parent == nil {
                // Attach the character to its anchor as soon as
                // 1. the body anchor was detected and
                // 2. the character was loaded.
                characterAnchor.addChild(character)
            }
        }
    }
}

