//
//  ContentView.swift
//  Prism
//
//  Created by Eli Zhang on 7/3/20.
//  Copyright © 2020 Eli Zhang. All rights reserved.
//

import SwiftUI

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

struct ConfettiAnimationShape : Shape {
    func path(in rect: CGRect) -> Path {
        return Path(CGRect(x: 0, y: 0, width: 0, height: 0))
    }
}

struct ShowModifier: ViewModifier {
    let show: Bool
    func body(content: Content) -> some View {
        Group {
            if show {
                EmptyView()
            } else {
                content
            }
        }
    }
}

class ScreenConfiguration {
    static var triangleWidth: CGFloat = UIScreen.screenWidth / 2 - 10
    static var verticalTriangleCount: Int = {
        return Int(ceil(UIScreen.screenHeight / triangleWidth))
    }()
    
    static func generateColor() -> UIColor {
        let red = CGFloat.random(in: 0...1)
        let green = CGFloat.random(in: 0...1)
        let blue = CGFloat.random(in: 0...1)
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    static func getTriangleOrientation(row: Int, col: Int) -> Orientation {
        return col.isEven ? .up : .down
    }
    
    static func getStartingCoords() -> (Int, Int) {
        var startingRow: Int = self.verticalTriangleCount / 2
        if startingRow % 2 != 0 {
            startingRow += 1
        }
        
        let trianglesInStartingRow: Int = 5 + (startingRow.isEven ? 2 : 0)
        let startingCol: Int = trianglesInStartingRow / 2
        return (startingRow, startingCol)
    }
    
    static func getBorderingCoords(row: Int, col: Int) -> [(Int, Int)] {
        let orientation = getTriangleOrientation(row: row, col: col)
        
        switch orientation {
        case .up:
            return [(row, col - 1), (row, col + 1), (row + 1, col + (row.isEven ? -1 : 1))]
        case .down:
            return [(row, col - 1), (row, col + 1), (row - 1, col + (row.isEven ? -1 : 1))]
        }
    }
    
    enum Orientation {
        case up
        case down
    }
    
    static func populateColorArray() -> ([[UIColor]], UIColor) {
        let randomColor = generateColor()
        return populateColorArrayWithStartingColor(startingColor: randomColor)
    }
    
    static func populateColorArrayWithStartingColor(startingColor: UIColor) -> ([[UIColor]], UIColor) {
        func validateCoords(coords: (Int, Int)) -> Bool {
            return coords.0 < rows.count && coords.0 >= 0
            && coords.1 < rows[coords.0].count && coords.1 >= 0
        }
        
        var rows: [[UIColor]] = []
        for row in 0..<self.verticalTriangleCount {
            let trianglesPerRow = 5 + (row.isEven ? 2 : 0)
            rows.append(Array(repeating: .clear, count: trianglesPerRow))
        }
        
        let (startingRow, startingCol): (Int, Int) = getStartingCoords()
        
        rows[startingRow][startingCol] = startingColor
        rows[startingRow][startingCol - 1] = startingColor.modifyColor(colorChange: .red)
        rows[startingRow][startingCol + 1] = startingColor.modifyColor(colorChange: .blue)
        rows[startingRow - 1][rows[startingRow - 1].count / 2] = startingColor.modifyColor(colorChange: .green)
        
        var toVisit: [(Int, Int)] = []
        let baseColors = [(startingRow, startingCol + 1), (startingRow, startingCol - 1), (startingRow - 1, rows[startingRow - 1].count / 2)]
        for startingCoord in baseColors {
            toVisit += getBorderingCoords(row: startingCoord.0, col: startingCoord.1)
        }

        while !toVisit.isEmpty {
            let currentCoords = toVisit.removeFirst()
            let currRow = currentCoords.0
            let currCol = currentCoords.1
            if validateCoords(coords: currentCoords) {   // Spot exists
                if rows[currRow][currCol] == .clear {    // Make sure color hasn't been visited
                    let borderingTriangles = getBorderingCoords(row: currRow, col: currCol)
                    var currColor: UIColor = .clear
                    for coord in borderingTriangles {
                        if validateCoords(coords: coord) {
                            currColor = UIColor.blend(color1: currColor, color2: rows[coord.0][coord.1])
                        }
                    }
                    rows[currRow][currCol] = UIColor.lighten(color: currColor)
                    toVisit += borderingTriangles
                }
            }
        }
        
        return (rows, startingColor)
    }
    
}

struct ContentView: View {
    var startingCoords: (Int, Int) = ScreenConfiguration.getStartingCoords()
    var coreColorCoords: [(Int, Int)] = ScreenConfiguration.getBorderingCoords(
        row: ScreenConfiguration.getStartingCoords().0,
        col: ScreenConfiguration.getStartingCoords().1)
    var dragMultiplier: CGFloat = 0.4
    @State private var redGuess: CGFloat = 255
    @State private var greenGuess: CGFloat = 255
    @State private var blueGuess: CGFloat = 255
    @State private var redChange: CGFloat = 0
    @State private var greenChange: CGFloat = 0
    @State private var blueChange: CGFloat = 0
    @State private var colorInfo: ([[UIColor]], UIColor) = ScreenConfiguration.populateColorArray()
    @State private var oldColor: UIColor = .clear
    @State private var showGuess: Bool = false
    @State private var accuracy: CGFloat = 0
    @State private var showConfetti: Int = 0
    @State private var showKeyboard: Bool = false
    @EnvironmentObject var keyboardEntry: KeyboardEntry

    func getGuessAfterChange() -> (Int, Int, Int) {
        return (
            Int(max(0, min(255, redGuess + dragMultiplier * redChange))),
            Int(max(0, min(255, greenGuess + dragMultiplier * greenChange))),
            Int(max(0, min(255, blueGuess + dragMultiplier * blueChange))))
    }

    func getHexString() -> String {
        if !showKeyboard {
            let guessValue = getGuessAfterChange()
            return String(format:"%02X", guessValue.0)
            + String(format:"%02X", guessValue.1)
            + String(format:"%02X", guessValue.2)
        }
        return keyboardEntry.currentText
    }

    func getAccuracy() -> CGFloat {
        let guessValue = getGuessAfterChange()

        let redDifference = abs(CGFloat(guessValue.0) / 255.0 - oldColor.redValue)
        let greenDifference = abs(CGFloat(guessValue.1) / 255.0 - oldColor.greenValue)
        let blueDifference = abs(CGFloat(guessValue.2) / 255.0 - oldColor.blueValue)

        return (1 - redDifference) * (1 - greenDifference) * (1 - blueDifference)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                VStack(spacing: 5) {
                    ForEach((0..<ScreenConfiguration.verticalTriangleCount), id: \.self) { row in
                        HStack(spacing: -(ScreenConfiguration.triangleWidth / 2) + 5) {
                            ForEach((0...(4 + (row.isEven ? 2 : 0))), id: \.self) { col in
                                Triangle()
                                    .fill(Color(self.colorInfo.0[row][col])).frame(
                                    width: ScreenConfiguration.triangleWidth,
                                    height: ScreenConfiguration
                                        .triangleWidth).animation(.easeInOut)
                                .rotationEffect(col.isEven ? .degrees(0) : .degrees(180))
                                .onTapGesture {
                                    if row == self.startingCoords.0 && col == self.startingCoords.1 {
                                        // Tapped center, submitting guess or resetting
                                        if !self.showGuess {
                                            self.showGuess = true
                                            self.oldColor = self.colorInfo.1
                                            self.accuracy = self.getAccuracy()
                                            if self.accuracy > 0.9 {
                                                self.showConfetti = 1
                                                Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { timer in
                                                    self.showConfetti = 0
                                                }
                                            }
                                        }
                                        else {
                                            self.colorInfo = ScreenConfiguration.populateColorArray()
                                            self.showGuess = false
                                            self.redGuess = 255
                                            self.greenGuess = 255
                                            self.blueGuess = 255
                                            self.showConfetti = 0
                                        }
                                    }
                                    else if !((row == self.startingCoords.0 &&
                                         (col == self.startingCoords.1 - 1 ||
                                        col == self.startingCoords.1 + 1))
                                        || (row == self.startingCoords.0 - 1 && col == (self.colorInfo.0[self.startingCoords.0 - 1].count / 2)))
                                    {
                                        self.colorInfo = ScreenConfiguration.populateColorArray()
                                        self.showGuess = false
                                        self.redGuess = 255
                                        self.greenGuess = 255
                                        self.blueGuess = 255
                                    }
                                    else {
                                        if self.showGuess {
                                            self.showGuess = false
                                        }
                                    }
                                }
                                .gesture(DragGesture().onChanged({ (value) in
                                    if row == self.startingCoords.0 {
                                        if col == self.startingCoords.1 - 1 {
                                            // Red
                                            self.redChange = self.dragMultiplier * -value.translation.height
                                        }
                                        else if col == self.startingCoords.1 + 1 {
                                            // Blue
                                            self.blueChange = self.dragMultiplier * -value.translation.height
                                        }
                                    }
                                    else if row == self.startingCoords.0 - 1 && col == (self.colorInfo.0[self.startingCoords.0 - 1].count / 2) {
                                        // Green
                                        self.greenChange = self.dragMultiplier * -value.translation.height
                                    }
                                }).onEnded({ _ in
                                    self.redGuess = max(0, min(255, self.redGuess + self.redChange))
                                    self.redChange = 0
                                    self.blueGuess = max(0, min(255, self.blueGuess + self.blueChange))
                                    self.blueChange = 0
                                    self.greenGuess = max(0, min(255, self.greenGuess + self.greenChange))
                                    self.greenChange = 0
                                }))
                            }
                        }
                    }
                }
    //            VStack() {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(self.showGuess ?
                            Color(UIColor(
                            red: CGFloat(self.getGuessAfterChange().0) / 255.0,
                            green: CGFloat(self.getGuessAfterChange().1) / 255.0,
                            blue: CGFloat(self.getGuessAfterChange().2) / 255.0, alpha: 1))
                            : Color.white).animation(.easeInOut(duration: self.showGuess ? 1 : 0))
                        .frame(width: 100, height: 50, alignment: .bottom)
                        .onTapGesture {
                            self.showKeyboard = !self.showKeyboard;
                        }
                
                KeyboardView().frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .bottom).padding(.bottom, 40 + geometry.safeAreaInsets.bottom)
                    .opacity(self.showKeyboard ? 1 : 0).animation(.easeInOut)
                
                Text(self.showGuess ? "" : self.getHexString()).font(Font.custom("Oswald-Light", size: 20))
                VStack(alignment: .center, spacing: 20) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.white)
                        .frame(width: UIScreen.screenWidth - 40, height: 7).padding([.top, .leading, .trailing])
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.green)
                            .frame(width: self.accuracy * (UIScreen.screenWidth - 40), height: 7).padding([.top, .leading, .trailing]).animation(.easeInOut(duration: 1))
                    }.opacity(self.showGuess ? 1 : 0).animation(.easeInOut)

                    Spacer()
                    }.padding(40)

                LottieView(name: "Confetti", play: self.$showConfetti).opacity(Double(self.showConfetti)).frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight)
                    .contentShape(ConfettiAnimationShape()).show(!self.showConfetti.boolValue)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let keyboardEntry = KeyboardEntry()
    static var previews: some View {
        ContentView()
    }
}

extension UIScreen {
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}

extension UIColor {
    var redValue: CGFloat { return CIColor(color: self).red }
    var greenValue: CGFloat { return CIColor(color: self).green }
    var blueValue: CGFloat { return CIColor(color: self).blue }
    var alphaValue: CGFloat { return CIColor(color: self).alpha }
    func modifyColor(colorChange: ColorChange) -> UIColor {
        func diverge(_ value: CGFloat) -> CGFloat {  // Moves closer to 0
            return value * 0.85
        }
        
        func converge(_ value: CGFloat) -> CGFloat {   // Moves closer to 1
            return (1 - value) * 0.8 + value
        }
        
        func convergeSlightly(_ value: CGFloat) -> CGFloat {   // Moves closer to 1
            return (1 - value) * 0.9 + value
        }
        
        var redValue = self.redValue
        var greenValue = self.greenValue
        var blueValue = self.blueValue
        switch colorChange {
        case .red:
            redValue = converge(redValue)
            greenValue = diverge(greenValue)
            blueValue = diverge(blueValue)
        case .green:
//            redValue = diverge(redValue)
            greenValue = converge(greenValue)
//            blueValue = diverge(blueValue)
        case .blue:
            redValue = diverge(redValue)
            greenValue = diverge(greenValue)
            blueValue = converge(blueValue)
        }
        return UIColor(red: redValue, green: greenValue, blue: blueValue, alpha: 1)
    }
    
    static func blend(color1: UIColor, intensity1: CGFloat = 0.5, color2: UIColor, intensity2: CGFloat = 0.5) -> UIColor {
        if color1 == .clear {
            return color2
        } else if color2 == .clear {
            return color1
        }
        let total = intensity1 + intensity2
        let l1 = intensity1/total
        let l2 = intensity2/total
        guard l1 > 0 else { return color2 }
        guard l2 > 0 else { return color1 }
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)

        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return UIColor(red: l1*r1 + l2*r2, green: l1*g1 + l2*g2, blue: l1*b1 + l2*b2, alpha: l1*a1 + l2*a2)
    }
    
    static func lighten(color: UIColor) -> UIColor {
        return UIColor(red: color.redValue, green: color.greenValue, blue: color.blueValue, alpha: color.alphaValue * 0.7)
    }
    
    enum ColorChange {
        case red
        case blue
        case green
    }
}

extension Int {
    var isEven: Bool {
        return self % 2 == 0
    }
    var boolValue: Bool { return self != 0 }
}


extension View {
    func show(_ bool: Bool) -> some View {
        modifier(ShowModifier(show: bool))
    }
}
