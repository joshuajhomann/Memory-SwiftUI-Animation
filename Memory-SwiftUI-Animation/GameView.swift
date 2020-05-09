//
//  ContentView.swift
//  Memory-SwiftUI-Animation
//
//  Created by Joshua Homann on 5/1/20.
//  Copyright © 2020 com.josh. All rights reserved.
//

import SwiftUI
import Combine

struct GameView: View {
  typealias GameBoard = GameBoardPreferenceKey.GameBoard
  @State private var board: GameBoard = .init()
  @ObservedObject private var model: GameModel = .init()
  var body: some View {
    VStack {
      GeometryReader { geometry in
        ZStack(alignment: .topLeading)  {
          ForEach(self.model.cards) { card in
            Card(card: self.$model.cards[card.index], dimension: self.board.cardDimension)
              .offset(self.board.offset(for: self.model.cards[card.index].location))
              .onTapGesture { self.model.dispatch(.selectCard(index: card.index)) }
              .zIndex(Double(card.index))
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
      .onReceive(model.nextTransaction) { transaction in
        switch transaction {
        case .flipUpCard:
          withAnimation(.easeInOut(duration: 0.33)) {
            self.model.dispatch(.commit(transaction: transaction, thenWait: 0.33))
          }
        case .shakeCards:
          withAnimation(Animation.easeInOut(duration: 0.33).delay(0.66)) {
            self.model.dispatch(.commit(transaction: transaction, thenWait: 1))
          }
        case .flipDownCards:
          withAnimation(Animation.easeInOut(duration: 0.33)) {
            self.model.dispatch(.commit(transaction: transaction, thenWait: 0.33))
          }
        case .matchCards:
          self.model.dispatch(.commit(transaction: transaction, thenWait: 0))
        case .bounceMatches:
          withAnimation(.spring()) {
            self.model.dispatch(.commit(transaction: transaction, thenWait: 0.5))
          }
        case .removeMatches:
          withAnimation(Animation.easeInOut(duration: 0.5).delay(0.5)) {
            self.model.dispatch(.commit(transaction: transaction, thenWait: 1))
          }
        }
      }
      HStack {
        Text("Flips: \(model.flips)")
        Spacer()
        Button("Restart") { self.model.dispatch(.reset) }
      }
      .padding()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    GameView()
  }
}
