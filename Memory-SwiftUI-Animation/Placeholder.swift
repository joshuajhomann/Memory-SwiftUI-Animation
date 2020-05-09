//
//  Placeholder.swift
//  Memory-SwiftUI-Animation
//
//  Created by Joshua Homann on 5/9/20.
//  Copyright © 2020 com.josh. All rights reserved.
//

import SwiftUI

struct PlaceHolder: Identifiable {
  var id: Int
  var x: Int
  var y: Int
  static func make() -> [PlaceHolder] {
    (0..<GameModel.Constant.columns).flatMap { x in
      (0..<GameModel.Constant.rows).map { y in
        PlaceHolder(id: x + y * GameModel.Constant.columns, x: x, y: y)
      }
    }
  }
}

