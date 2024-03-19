//
//  ViewExtensions.swift
//  Ichime
//
//  Created by Nikita Nafranets on 20.03.2024.
//

import SwiftUI

/**
 @example:
 ```swift
 Button {
     print("👋👋👋")
 } label: {
     Text("Hello World!")
 }
 .if(vm.status == .subscribed, if: { button in
     button.buttonStyle(TertiaryButton())
 }, else: { button in
     button.buttonStyle(SecondaryButton())
 })
 ```
 */
extension View {
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}
