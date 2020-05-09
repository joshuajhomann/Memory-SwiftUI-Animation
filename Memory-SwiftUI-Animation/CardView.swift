//
//  CardView.swift
//  Memory-SwiftUI-Animation
//
//  Created by Joshua Homann on 5/8/20.
//  Copyright © 2020 com.josh. All rights reserved.
//

import SwiftUI
import Combine

struct Card: View {
  @Binding var card: GameModel.Card
  var dimension: CGFloat
  var body: some View {
    ZStack {
      Rectangle()
        .fill(Color(card.isFaceVisible ? #colorLiteral(red: 0.9601849914, green: 0.9601849914, blue: 0.9601849914, alpha: 1) : #colorLiteral(red: 0.7511121631, green: 0.9492185712, blue: 1, alpha: 1) ))
        .frame(width: dimension, height: dimension)
        .cornerRadius(dimension * 0.08)
        .overlay(
          RoundedRectangle(cornerRadius: dimension * 0.08)
          .stroke(Color.gray, lineWidth: 2)
        )
      Text(card.isFaceVisible ? card.value : "?")
        .font(.system(size: 0.7 * dimension))
        .rotation3DEffect(.init(radians: card.isFaceVisible ? .pi : 0), axis: (x: 0, y: 1, z: 0))
    }
    .horizontalShakeAnimation(
      proportion: card.isShaking ? 1 : 0,
      distance: dimension * 0.08
    )
    .bounceScaleAnimation(
      proportion:  card.isScaled ? 1 : 0,
      scale: 1.25
    )
    .flipAnimation(
      proportion: card.isRotated ? 1 : 0
      , id: card.id
    )
    .onPreferenceChange(FlipPreferenceKey.self) {
      guard let value = $0[self.card.id] else { return }
      self.card.isFaceVisible = value
    }
  }
  init(card: Binding<GameModel.Card>, dimension: CGFloat) {
    self._card = card
    self.dimension = dimension
  }
}
