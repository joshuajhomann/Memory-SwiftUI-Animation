//
//  ContentView.swift
//  Memory-SwiftUI-Animation
//
//  Created by Joshua Homann on 5/1/20.
//  Copyright © 2020 com.josh. All rights reserved.
//

import SwiftUI
import Combine

final class GameModel: ObservableObject {
  struct Card: Identifiable {
    var id: Int { index }
    var index: Int
    var value: String
    var location: Location
    var isRotated: Bool = false
    var isFaceVisible: Bool = false
    enum Location {
      case board(x: Int, y: Int)
      case match(index: Int)
    }
  }
  @Published var cards: [Card]
  private var flippedCardIndex: Int?
  private var lastMatchIndex = 0
  enum Constant {
    static let rows = 3
    static let columns = 4
  }
  enum Selection {
    case single, match(Int, Int), mismatch(Int, Int)
  }
  init() {
    let emojis = ["🦄", "🐼", "🐸", "🐙", "🐳", "🦋"]
    cards = (emojis + emojis)
      .shuffled()
      .enumerated()
      .map { index, value in
        Card(
          index: index,
          value: value,
          location: .board(x: index % Constant.columns, y: index / Constant.columns)
        )
      }
  }
  func selectCard(at index: Int) -> Selection? {
    guard !cards[index].isFaceVisible else {
      return nil
    }
    cards[index].isRotated = true
    guard let flippedCardIndex = flippedCardIndex else {
      self.flippedCardIndex = index
      return .single
    }
    if cards[index].value == cards[flippedCardIndex].value {
      return .match(index, flippedCardIndex)
    }
    return .mismatch(index, flippedCardIndex)
  }
  func unselect(_ first: Int, _ second: Int) {
    cards[first].isRotated = false
    cards[second].isRotated = false
    flippedCardIndex = nil
  }
  func removeMatches(_ first: Int, _ second: Int) {
    cards[first].location = .match(index: lastMatchIndex)
    lastMatchIndex += 1
    cards[second].location = .match(index: lastMatchIndex)
    lastMatchIndex += 1
    flippedCardIndex = nil
  }
}

struct FlipAnimation: AnimatableModifier {
  var proportion: Double
  var id: Int

  var animatableData: Double {
    get { proportion }
    set { proportion = newValue }
  }

  func body(content: Content) -> some View {
    return content
      .rotation3DEffect(Angle(radians: proportion * .pi), axis: (x: 0, y: 1, z: 0))
      .preference(
        key: FlipPreferenceKey.self,
        value: [id: proportion > 0.5]
      )
  }

}

extension View {
  func flipAnimation(proportion: Double, id: Int) -> some View {
    return self.modifier(FlipAnimation(proportion: proportion, id: id))
  }
}

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
    init(boardDimension: CGFloat = .zero) {
      self.boardDimension = boardDimension
      cardDimension = boardDimension / CGFloat(GameModel.Constant.columns + 1)
      cardSpacing = cardDimension / CGFloat(GameModel.Constant.columns + 1)
    }
    func offset(for card: GameModel.Card) -> CGSize {
      switch card.location {
        case let .board(x, y):
          return .init(
            width: CGFloat(x) * (cardDimension + cardSpacing) + cardSpacing,
            height: CGFloat(y) * (cardDimension + cardSpacing) + cardSpacing
          )
        case let .match(index):
          return .init(
            width:  CGFloat(index) * cardDimension * 0.1 + cardSpacing,
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
    }
    .flipAnimation(proportion: card.isRotated ? 1 : 0, id: card.id)
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

struct GameView: View {
  typealias GameBoard = GameBoardPreferenceKey.GameBoard
  @State private var board: GameBoard = .init()
  @ObservedObject private var model: GameModel = .init()
  var body: some View {
    let model = self.model
    let board = self.board
    return GeometryReader { geometry in
      ZStack(alignment: .topLeading)  {
        ForEach (model.cards.indices) { index in
          Card(card: self.$model.cards[index], dimension: board.cardDimension)
            .offset(board.offset(for: model.cards[index]))
            .onTapGesture {
              var selection: GameModel.Selection?
              withAnimation(Animation.linear(duration: 1.0)) {
                selection = model.selectCard(at: index)
              }
              switch selection {
              case let .match(first, second):
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                  withAnimation(Animation.linear(duration: 1.0)) {
                    model.removeMatches(first, second)
                  }
                }
              case let .mismatch(first, second):
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                  withAnimation(Animation.linear(duration: 1.0)) {
                    model.unselect(first, second)
                  }
                }
              case .single, .none: break
              }
          }
        }
      }
      .frame(
        width: min(geometry.size.width, geometry.size.height),
        height: min(geometry.size.width, geometry.size.height),
        alignment: .topLeading
      )
      .preference(
        key: GameBoardPreferenceKey.self,
        value: .init(boardDimension: geometry.size.width)
      )
    }
    .onPreferenceChange(GameBoardPreferenceKey.self) { self.board = $0 }
  }

}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    GameView()
  }
}
