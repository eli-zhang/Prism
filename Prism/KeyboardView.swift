//
//  KeyboardView.swift
//  Prism
//
//  Created by Eli Zhang on 7/14/20.
//  Copyright © 2020 Eli Zhang. All rights reserved.
//

import SwiftUI

struct KeyboardView: View {
    
    let keys = [["0", "1", "2", "3", "4", "5", "6", "7"], ["8", "9", "A", "B", "C", "D", "E", "F"]]
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                                .fill(Color.white)
                        .frame(width: UIScreen.screenWidth - (5 * 2), height: 50).shadow(radius: 1, x: 1, y: 1)
                    Text("CLEAR").font(Font.custom("Oswald-Light", size: 20))
                }
                ForEach((0...1), id: \.self) { row in
                    HStack(spacing: 5) {
                        ForEach((0...7), id: \.self) { col in
                            ZStack {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.white)
                                    .frame(width: (UIScreen.screenWidth - (5 * 9)) / 8, height: 30)
                                    .shadow(radius: 1, x: 1, y: 1)
                                    
                                Text(self.keys[row][col]).font(Font.custom("Oswald-Light", size: 18))
                            }
                        }
                    }
                }
            }
            
        }
    }
}

struct KeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardView()
    }
}
