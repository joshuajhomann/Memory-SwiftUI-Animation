//
//  FlipAnimation.swift
//  Memory-SwiftUI-Animation
//
//  Created by Joshua Homann on 5/2/20.
//  Copyright © 2020 com.josh. All rights reserved.
//

import SwiftUI

struct FlipAnimation: AnimatableModifier {
  var proportion: Double
  var id: Int

  var animatableData: Double {
    get { proportion }
    set { proportion = newValue }
  }

  func body(content: Content) -> some View {
    content
      .rotation3DEffect(Angle(radians: proportion * .pi), axis: (x: 0, y: 1, z: 0))
      .preference(
        key: FlipPreferenceKey.self,
        value: [id: proportion > 0.5]
      )
  }

}

struct BounceScaleAnimation: AnimatableModifier {
  var proportion: CGFloat
  var scale: CGFloat
  private var adjustedProportion: CGFloat {
    proportion < 0.5
      ? 2 * proportion
      : (1 - 2 * (proportion - 0.5))
  }

  var animatableData: CGFloat {
    get { proportion }
    set { proportion = newValue }
  }

  func body(content: Content) -> some View {
    content
      .scaleEffect(1 + (scale - 1) * adjustedProportion)
  }
}

struct HorizontalShakeAnimation: AnimatableModifier {
  var proportion: CGFloat
  var distance: CGFloat
  private var adjustedProportion: CGFloat {
    proportion < 0.5
      ? 4 * proportion * .pi
      : (1 - 2 * (proportion - 0.5)) * 2 * .pi
  }

  var animatableData: CGFloat {
    get { proportion }
    set { proportion = newValue }
  }

  func body(content: Content) -> some View {
    content
      .transformEffect(.init(
        translationX: sin(adjustedProportion * 3) * distance,
        y: 0)
      )
  }
}

extension View {
  func flipAnimation(proportion: Double, id: Int) -> some View {
    self.modifier(FlipAnimation(proportion: proportion, id: id))
  }
  func bounceScaleAnimation(proportion: CGFloat, scale: CGFloat) -> some View {
    self.modifier(BounceScaleAnimation(proportion: proportion, scale: scale))
  }
  func horizontalShakeAnimation(proportion: CGFloat, distance: CGFloat) -> some View {
    self.modifier(HorizontalShakeAnimation(proportion: proportion, distance: distance))
  }
}

