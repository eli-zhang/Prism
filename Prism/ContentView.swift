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

struct ScreenConfiguration {
    var triangleWidth: CGFloat
    var verticalTriangleCount: Int
    init() {
        triangleWidth = UIScreen.screenWidth / 2 - 10
        verticalTriangleCount = Int(ceil(UIScreen.screenHeight / triangleWidth))
    }
    
    func generateColor() -> UIColor {
        let red = CGFloat.random(in: 0...1)
        let green = CGFloat.random(in: 0...1)
        let blue = CGFloat.random(in: 0...1)
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    func getTriangleOrientation(row: Int, col: Int, rowLength: Int) -> Orientation {
        return col.isEven ? .up : .down
    }
    
    func getBorderingCoords(row: Int, col: Int, rowLength: Int, filterOtherSide: Bool = false) -> [(Int, Int)] {
        let orientation = getTriangleOrientation(row: row, col: col, rowLength: rowLength)
        
        switch orientation {
        case .up:
            if filterOtherSide && row < rowLength / 2 { // To the left
                return [(row, col - 1), (row + 1, col + (row.isEven ? -1 : 1))]
            }
            else if filterOtherSide && row > rowLength / 2 { // To the right
                return [(row, col + 1), (row + 1, col + (row.isEven ? -1 : 1))]
            }
            else { // In the middle
                return [(row, col - 1), (row, col + 1), (row + 1, col + (row.isEven ? -1 : 1))]
            }
        case .down:
            if filterOtherSide && row < rowLength / 2 { // To the left
                return [(row, col - 1), (row - 1, col + (row.isEven ? -1 : 1))]
            }
            else if filterOtherSide && row > rowLength / 2 { // To the right
                return [(row, col + 1), (row - 1, col + (row.isEven ? -1 : 1))]
            }
            else { // In the middle
                return [(row, col - 1), (row, col + 1), (row - 1, col + (row.isEven ? -1 : 1))]
            }
        }
    }
    
    enum Orientation {
        case up
        case down
    }
    
    func populateColorArray() -> [[UIColor]] {
        func validateCoords(coords: (Int, Int)) -> Bool {
            return coords.0 < rows.count && coords.0 >= 0
            && coords.1 < rows[coords.0].count && coords.1 >= 0
        }
        
        var rows: [[UIColor]] = []
        for row in 0..<self.verticalTriangleCount {
            let trianglesPerRow = 5 + (row.isEven ? 2 : 0)
            rows.append(Array(repeating: .clear, count: trianglesPerRow))
        }
        
        var startingRow: Int = self.verticalTriangleCount / 2
        if startingRow % 2 != 0 {
            startingRow += 1
        }
        
        let randomColor = generateColor()
        
        rows[startingRow][rows[startingRow].count / 2] = randomColor
        rows[startingRow][rows[startingRow].count / 2 - 1] = randomColor.modifyColor(colorChange: .blue)
        rows[startingRow][rows[startingRow].count / 2 + 1] = randomColor.modifyColor(colorChange: .green)
        rows[startingRow - 1][rows[startingRow - 1].count / 2] = randomColor.modifyColor(colorChange: .red)
        
        var toVisit: [(Int, Int)] = []
        let baseColors = [(startingRow, rows[startingRow].count / 2 + 1), (startingRow, rows[startingRow].count / 2 - 1), (startingRow - 1, rows[startingRow - 1].count / 2)]
        for startingCoord in baseColors {
            toVisit += getBorderingCoords(row: startingCoord.0, col: startingCoord.1, rowLength: rows[startingCoord.0].count)
        }

        while !toVisit.isEmpty {
            let currentCoords = toVisit.removeFirst()
            let currRow = currentCoords.0
            let currCol = currentCoords.1
            if validateCoords(coords: currentCoords) {   // Spot exists
                if rows[currRow][currCol] == .clear {    // Make sure color hasn't been visited
                    let borderingTriangles = getBorderingCoords(row: currRow, col: currCol, rowLength: rows[currRow].count)
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
        
        return rows
    }
    
}

struct ContentView: View {
    
    var screenConfigurator = ScreenConfiguration()
    let colorArray: [[UIColor]]
    
    init() {
        colorArray = screenConfigurator.populateColorArray()
    }
  
    var body: some View {
        VStack(spacing: 5) {
            ForEach((0..<self.screenConfigurator.verticalTriangleCount), id: \.self) { row in
                HStack(spacing: -(self.screenConfigurator.triangleWidth / 2) + 5) {
                    ForEach((0...(4 + (row.isEven ? 2 : 0))), id: \.self) { col in
                        Triangle()
                            .fill(Color(self.colorArray[row][col])).frame(
                                width: self.screenConfigurator.triangleWidth,
                                height: self.screenConfigurator
                                .triangleWidth)
                            .rotationEffect(col.isEven ? .degrees(0) : .degrees(180))
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
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
        var redValue = self.redValue
        var greenValue = self.greenValue
        var blueValue = self.blueValue
        switch colorChange {
        case .red:
            redValue = converge(redValue)
            greenValue = diverge(greenValue)
            blueValue = diverge(blueValue)
        case .green:
            redValue = diverge(redValue)
            greenValue = converge(greenValue)
            blueValue = diverge(blueValue)
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
}
