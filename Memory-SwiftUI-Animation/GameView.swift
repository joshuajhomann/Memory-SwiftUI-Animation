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
  private let placeHolders = PlaceHolder.make()
  var body: some View {
    VStack {
      GeometryReader { geometry in
        ZStack(alignment: .topLeading)  {
          ForEach(self.placeHolders) { placeHolder in
            Rectangle()
              .fill(Color( #colorLiteral(red: 0.9590210898, green: 0.959043609, blue: 0.9590315119, alpha: 1) ))
              .frame(width: self.board.cardDimension, height: self.board.cardDimension)
              .cornerRadius(self.board.cardDimension * 0.08)
              .overlay(
                RoundedRectangle(cornerRadius: self.board.cardDimension * 0.08)
                .stroke(Color( #colorLiteral(red: 0.8986896726, green: 0.8987107751, blue: 0.898699439, alpha: 1) ), lineWidth: 2)
              )
              .offset(self.board.offset(for: .board(x: placeHolder.x, y: placeHolder.y)))
          }
          Rectangle()
            .fill(Color( #colorLiteral(red: 0.9590210898, green: 0.959043609, blue: 0.9590315119, alpha: 1) ))
            .frame(width: self.board.rowWidth, height: self.board.cardDimension)
            .cornerRadius(self.board.cardDimension * 0.08)
            .overlay(
              RoundedRectangle(cornerRadius: self.board.cardDimension * 0.08)
              .stroke(Color( #colorLiteral(red: 0.8986896726, green: 0.8987107751, blue: 0.898699439, alpha: 1) ), lineWidth: 2)
            )
            .offset(self.board.offset(for: .board(x: 0, y: GameModel.Constant.rows)))
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
        let model = self.model
        switch transaction {
        case .flipUpCard:
          withAnimation(.easeInOut(duration: 0.33)) {
            model.dispatch(.commit(transaction: transaction, thenWait: 0.33))
          }
        case .shakeCards:
          withAnimation(Animation.easeInOut(duration: 0.33).delay(0.66)) {
            model.dispatch(.commit(transaction: transaction, thenWait: 1))
          }
        case .flipDownCards:
          withAnimation(Animation.easeInOut(duration: 0.33)) {
            model.dispatch(.commit(transaction: transaction, thenWait: 0.33))
          }
        case .matchCards:
          model.dispatch(.commit(transaction: transaction, thenWait: 0))
        case .bounceMatches:
          withAnimation(.spring()) {
            model.dispatch(.commit(transaction: transaction, thenWait: 0.5))
          }
        case .removeMatches:
          withAnimation(Animation.easeInOut(duration: 0.5).delay(0.5)) {
            model.dispatch(.commit(transaction: transaction, thenWait: 1))
          }
        }
      }
      .overlay(
        model.matches < 6
          ? AnyView(EmptyView())
          : AnyView( ZStack {
              FireworksView()
              Text("You won!!!").font(.system(size: 72))
            }
          )
      )
      HStack {
        Text("Flips: \(model.flips)").font(.largeTitle)
        Spacer()
        Button(action: { self.model.dispatch(.reset) }) {
          Text("Restart").font(.largeTitle)
        }

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
