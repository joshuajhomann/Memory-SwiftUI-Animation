//
//  FireworksView.swift
//  Memory-SwiftUI-Animation
//
//  Created by Joshua Homann on 5/8/20.
//  Copyright © 2020 com.josh. All rights reserved.
//

import SpriteKit
import SwiftUI
import Combine


struct FireworksView : UIViewRepresentable {

  class Coordinator {
    var scene: SKScene?
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator()
  }

  func makeUIView(context: Context) -> SKView {
    let view = SKView(frame: .zero)
    view.backgroundColor = .clear
    view.preferredFramesPerSecond = 60
    let scene = FireworksScene(size: UIScreen.main.bounds.size)
    scene.scaleMode = .resizeFill
    scene.backgroundColor = .clear
    scene.anchorPoint = .init(x: 0.5, y: 0.5)
    context.coordinator.scene = scene
    return view
  }

  func updateUIView(_ view: SKView, context: Context) {
    view.presentScene(context.coordinator.scene)
  }
}

class FireworksScene : SKScene{
  private var animationCancellable: AnyCancellable?
  private var explosions: [SKEmitterNode] = []

  static let allColors: [SKKeyframeSequence] = {
    let colors = [
      [#colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1), #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1), #colorLiteral(red: 0.9994240403, green: 0.9855536819, blue: 0, alpha: 1), #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)].map{ SKColor(cgColor: $0) },
      [#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1), #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)].map{ SKColor(cgColor: $0) },
      [#colorLiteral(red: 0.9994240403, green: 0.9855536819, blue: 0, alpha: 1), #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1), #colorLiteral(red: 0.8321695924, green: 0.985483706, blue: 0.4733308554, alpha: 1), #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)].map{ SKColor(cgColor: $0) },
      [#colorLiteral(red: 1, green: 0.2527923882, blue: 1, alpha: 1), #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1), #colorLiteral(red: 0.8446564078, green: 0.5145705342, blue: 1, alpha: 1), #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)].map{ SKColor(cgColor: $0) },
    ]
    let times: [NSNumber] = [0, 0.25, 0.5, 1]
    return colors.map { SKKeyframeSequence(keyframeValues: $0, times: times)}
  }()
  override func didMove(to view: SKView) {
    start()
  }
  private func start() {
    guard explosions.isEmpty else {
      return
    }
    explosions = (0..<3).compactMap { _ in SKEmitterNode(fileNamed: "explosion.sks") }
    explosions.forEach { $0.isHidden = true}
    explosions.forEach(addChild(_:))
    animationCancellable = Timer
      .publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .map({ _ in () })
      .prepend(())
      .sink(receiveValue: { [weak self] _ in
        guard let self = self else { return }
        let explosion = self.explosions.removeFirst()
        explosion.removeFromParent()
        explosion.resetSimulation()
        explosion.position = .init(
          x: CGFloat((-200...200).randomElement() ?? 0),
          y: CGFloat((-200...400).randomElement() ?? 0)
        )
        explosion.particleColorSequence = Self.allColors.randomElement()!
        explosion.setScale(CGFloat((50...100).randomElement() ?? 100)/100.0)
        explosion.isHidden = false
        self.addChild(explosion)
        self.explosions.append(explosion)
      })
  }

}
