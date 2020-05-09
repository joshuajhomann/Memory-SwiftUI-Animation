//
//  GameModel.swift
//  Memory-SwiftUI-Animation
//
//  Created by Joshua Homann on 5/8/20.
//  Copyright © 2020 com.josh. All rights reserved.
//

import Foundation
import Combine

final class GameModel: ObservableObject {
  @Published var cards: [Card] = []
  @Published private (set) var flips = 0
  var nextTransaction: AnyPublisher<Transaction, Never> {
    transactionSubject.eraseToAnyPublisher()
  }

  private var transactionSubject = PassthroughSubject<Transaction, Never>()
  private var isExecuting = false
  private var flippedCardIndex: Int?
  private var lastMatchIndex = 0
  private var timerCancellable: AnyCancellable?
  struct Card: Identifiable {
    var id: Int { index }
    var index: Int
    var value: String
    var location: Location
    var isRotated = false
    var isShaking = false
    var isScaled = false
    var isFaceVisible = false
    enum Location {
      case board(x: Int, y: Int)
      case match(index: Int)
    }
  }

  enum Constant {
    static let rows = 3
    static let columns = 4
  }

  enum Action {
    case selectCard(index: Int)
    case reset
    case commit(transaction: Transaction, thenWait: TimeInterval)
  }

  enum Transaction {
    case flipUpCard(index: Int)
    case shakeCards(first: Int, second: Int)
    case flipDownCards(first: Int, second: Int)
    case matchCards(first: Int, second: Int)
    case bounceMatches(first: Int, second: Int)
    case removeMatches(first: Int, second: Int)
  }

  init() {
    dispatch(.reset)
  }

  func dispatch(_ action: Action) {
    switch action {
    case let .selectCard(index):
      guard !isExecuting,
        !cards[index].isFaceVisible else {
        return
      }
      flips += 1
      transactionSubject.send(.flipUpCard(index: index))
    case .reset:
      flips = 0
      isExecuting = false
      flippedCardIndex = nil
      lastMatchIndex = 0
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
    case let .commit(transaction, delay):
      apply(transaction: transaction, thenWait: delay)
    }
  }

  private func apply(transaction: Transaction, thenWait delay: TimeInterval) {
    let nextTransaction: Transaction?
    var beforeNextAction: (() -> Void)?
    switch transaction {
    case let .flipUpCard(index):
      cards[index].isRotated = true
      if let flippedCardIndex = flippedCardIndex {
        if cards[index].value == cards[flippedCardIndex].value {
          nextTransaction = .matchCards(first: flippedCardIndex, second: index)
        } else {
          nextTransaction = .shakeCards(first: flippedCardIndex, second: index)
        }
      } else {
        self.flippedCardIndex = index
        nextTransaction = nil
      }
    case let .shakeCards(first, second):
      cards[first].isShaking = true
      cards[second].isShaking = true
      nextTransaction = .flipDownCards(first: first, second: second)
      beforeNextAction = { [weak self] in
        self?.cards[first].isShaking = false
        self?.cards[second].isShaking = false
      }
    case let .flipDownCards(first, second):
      cards[first].isRotated = false
      cards[second].isRotated = false
      flippedCardIndex = nil
      nextTransaction = nil
    case let .matchCards(first, second):
      let copy = cards
      let end = [copy[first], copy[second]]
      cards = copy.filter { $0.id != copy[first].id && $0.id != copy[second].id } + end
      nextTransaction = .bounceMatches(
        first: cards.firstIndex{ end[0].id == $0.id }!,
        second: cards.firstIndex{ end[1].id == $0.id }!
      )
    case let .bounceMatches(first, second):
      cards[first].isScaled = true
      cards[second].isScaled = true
      nextTransaction = .removeMatches(first: first, second: second)
      beforeNextAction = { [weak self] in
        self?.cards[first].isScaled = false
        self?.cards[second].isScaled = false
      }
    case let .removeMatches(first, second):
      cards[first].location = .match(index: lastMatchIndex)
      lastMatchIndex += 1
      cards[second].location = .match(index: lastMatchIndex)
      lastMatchIndex += 1
      flippedCardIndex = nil
      nextTransaction = nil
    }

    if let nextAction = nextTransaction {
      timerCancellable = Just(nextAction)
        .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
        .sink(receiveValue: { [transactionSubject] transaction in
          beforeNextAction?()
          transactionSubject.send(transaction)
        })
      isExecuting = true
    } else {
      isExecuting = false
    }
  }
}
