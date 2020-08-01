//
//  KeyboardView.swift
//  Prism
//
//  Created by Eli Zhang on 7/14/20.
//  Copyright © 2020 Eli Zhang. All rights reserved.
//

import SwiftUI

struct KeyboardView: View {
    
    let keys: [[Character]] = [["0", "1", "2", "3", "4", "5", "6", "7"], ["8", "9", "A", "B", "C", "D", "E", "F"]]
    @EnvironmentObject var keyboardEntry: KeyboardEntry
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                .fill(Color.white)
                        .frame(width: UIScreen.screenWidth - (5 * 2), height: 50).shadow(radius: 1, x: 1, y: 1)
                    Text("CLEAR").font(Font.custom("Oswald-Light", size: 20))
                }.onTapGesture {
                    self.keyboardEntry.currentPosition = 0
                    self.keyboardEntry.currentText = "FFFFFF"
                }
                ForEach((0...1), id: \.self) { row in
                    HStack(spacing: 5) {
                        ForEach((0...7), id: \.self) { col in
                            ZStack {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.white)
                                    .frame(width: (UIScreen.screenWidth - (5 * 9)) / 8, height: 50)
                                    .shadow(radius: 1, x: 1, y: 1)
                                    
                                Text(String(self.keys[row][col])).font(Font.custom("Oswald-Light", size: 18))
                            }.onTapGesture {
                                if self.keyboardEntry.currentPosition >= 0 {
                                    if self.keyboardEntry.currentPosition >= 6 {
                                        self.keyboardEntry.currentPosition = 0
                                    }
                                    self.keyboardEntry.currentText = self.replace(self.keyboardEntry.currentText, self.keyboardEntry.currentPosition, self.keys[row][col])
                                    self.keyboardEntry.currentPosition += 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func replace(_ input: String, _ index: Int, _ newChar: Character) -> String {
        var modifiedString = String()
        for (i, char) in input.enumerated() {
            modifiedString += String((i == index) ? newChar : char)
        }
        return modifiedString
    }
}

struct KeyboardView_Previews: PreviewProvider {
    static let keyboardEntry = KeyboardEntry()
    static var previews: some View {
        KeyboardView()
    }
}

class KeyboardEntry: ObservableObject {
    @Published var currentPosition: Int = 0
    @Published var currentText: String = "FFFFFF"
}
