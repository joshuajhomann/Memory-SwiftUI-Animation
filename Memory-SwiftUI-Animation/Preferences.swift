//
//  Preferences.swift
//  Memory-SwiftUI-Animation
//
//  Created by Joshua Homann on 5/8/20.
//  Copyright © 2020 com.josh. All rights reserved.
//

import SwiftUI


struct FlipPreferenceKey: PreferenceKey {
  typealias Value = [Int: Bool]
  var isFlipped: Bool
  static var defaultValue: Value = [:]
  static func reduce(value: inout Value, nextValue: () -> Value) {
    nextValue().forEach {
      value[$0] = $1
    }
  }
}

struct GameBoardPreferenceKey: PreferenceKey {
  typealias Value = GameBoard
  struct GameBoard: Equatable {
    var boardDimension: CGFloat = .zero
    var cardDimension: CGFloat = .zero
    var cardSpacing: CGFloat = .zero
    var rowWidth: CGFloat = .zero
    init(boardDimension: CGFloat = .zero) {
      self.boardDimension = boardDimension
      cardDimension = boardDimension / CGFloat(GameModel.Constant.columns + 1)
      cardSpacing = cardDimension / CGFloat(GameModel.Constant.columns + 1)
      rowWidth = cardDimension * CGFloat(GameModel.Constant.columns) + cardSpacing * CGFloat(GameModel.Constant.columns - 1)
    }
    func offset(for location: GameModel.Card.Location) -> CGSize {
      switch location {
        case let .board(x, y):
          return .init(
            width: CGFloat(x) * (cardDimension + cardSpacing) + cardSpacing,
            height: CGFloat(y) * (cardDimension + cardSpacing) + cardSpacing
          )
        case let .match(index):
          return .init(
            width:  CGFloat(index) * rowWidth / CGFloat(14) + cardSpacing,
            height: CGFloat (GameModel.Constant.rows) * (cardDimension + cardSpacing) + cardSpacing
          )
        }
      }
  }
  static var defaultValue: Value = Value()
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value = nextValue()
  }
}
