//
//  WordSearch.swift
//  WordSearch
//
//  Created by Ryan Token on 2/17/19.
//  Copyright © 2019 Token Solutions. All rights reserved.
//

//A program that generates a random word search based on a JSON file and renders it as a formatted PDF

import Foundation
import UIKit

//CaseIterable allows for giving a random PlacementType
enum PlacementType: CaseIterable {
    case leftRight
    case rightLeft
    case upDown
    case downUp
    case topLeftBottomRight
    case topRightBottomLeft
    case bottomLeftTopRight
    case bottomRightTopLeft
    
    var movement: (x: Int, y: Int) {
        switch self {
        case .leftRight:
            return (1, 0)
        case .rightLeft:
            return (-1, 0)
        case .upDown:
            return (0, 1)
        case .downUp:
            return (0, -1)
        case .topLeftBottomRight:
            return (1, 1)
        case .topRightBottomLeft:
            return (-1, 1)
        case .bottomLeftTopRight:
            return (1, -1)
        case .bottomRightTopLeft:
            return (-1, -1)
        }
    }
}

enum Difficulty {
    case easy
    case medium
    case hard
    
    var placementTypes: [PlacementType] {
        switch self {
        case .easy:
            return [.leftRight, .upDown].shuffled()
            
        case .medium:
            return [.leftRight, .rightLeft, .upDown, .downUp].shuffled()
            
        case .hard:
            return PlacementType.allCases.shuffled()
        }
    }
}

//Decodable = we can decode this thing from JSON
//holds an actual word to place on the string
struct Word: Decodable {
    var text: String
    var clue: String
}

//we need to be able to modify letters in place on the grid
//if it's a value type we can't do that, we need a reference type (classes are reference types)
//modifying one instance of label will modify all other references
class Label {
    var letter: Character = " "
}

class WordSearch {
    var words = [Word]() //cat, dog, hamster, whatever
    var gridSize = 10
    
    var labels = [[Label]]() //two dimensional array
    var difficulty = Difficulty.medium
    var numberOfPages = 10
    
    //generate random letters
    //65-90 is the ASCII numbers for capitals A - Z
    //creates an array of those letters
    let allLetters = (65...90).map { Character(Unicode.Scalar($0)) }
    
    //makes our grid line by line
    func makeGrid() {
        labels = (0 ..< gridSize).map { _ in
            (0 ..< gridSize).map { _ in Label() }
        }
        
        placeWords()
        fillGaps()
        printGrid()
    }
    
    private func fillGaps() {
        for column in labels {
            for label in column {
                if label.letter == " " {
                    label.letter = allLetters.randomElement()!
                }
            }
        }
    }
    
    private func printGrid() {
        for column in labels {
            for row in column {
                print(row.letter, terminator: "")
            }
            
            print("")
        }
    }
    
    //go through every possible square saying 'does this word fit here? No? Bail out'
    private func labels(fromX x: Int, y: Int, word: String, movement: (x: Int, y: Int)) -> [Label]? {
        var returnValue = [Label]()
        
        var xPosition = x
        var yPosition = y
        
        for letter in word {
            let label = labels[xPosition][yPosition]
            
            if label.letter == " " || label.letter == letter {
                returnValue.append(label)
                xPosition += movement.x
                yPosition += movement.y
            } else {
                return nil
            }
        }
        
        return returnValue
    }
    
    //for this given movement type (downUp, upDown, etc) go through all possible squares in grid and place it there
    private func tryPlacing(_ word: String, movement: (x: Int, y: Int)) -> Bool {
        let xLength = (movement.x * (word.count - 1))
        let yLength = (movement.y * (word.count - 1))
        
        //randomly place this word in the grid
        let rows = (0 ..< gridSize).shuffled()
        let cols = (0 ..< gridSize).shuffled()

        for row in rows {
            for col in cols {
                let finalX = col + xLength
                let finalY = row + yLength
                
                if finalX >= 0 && finalX < gridSize && finalY >= 0 && finalY < gridSize {
                    if let returnValue = labels(fromX: col, y: row, word: word, movement: movement) {
                        for (index, letter) in word.enumerated() {
                            returnValue[index].letter = letter
                        }
                        //word was successfully placed for that movement type
                        return true
                    }
                }
            }
        }
        //this word could not be placed in any square for that movement type
        return false
    }
    
    //go through all placement types and try to place them all
    private func place(_ word: Word) -> Bool {
        let formattedWord = word.text.replacingOccurrences(of: " ", with: "").uppercased()
        
//        for type in difficulty.placementTypes {
//            if tryPlacing(formattedWord, movement: type.movement) {
//                return true
//            }
//        }
        
        //try calling tryPlacing with first item from placementTypes
        //pass in movementTypes for that placement type
        //if succeeds, return true
        //if return false, go to next placementType until one of them finally returns true
        //if it all returns false, containsWhere returns false (?)
        return difficulty.placementTypes.contains {
            tryPlacing(formattedWord, movement: $0.movement)
        }
        
        //return false
    }
    
    private func placeWords() -> [Word] {
//        words.shuffle()
//
//        var usedWords = [Word]()
//
//        for word in words {
//            if place(word) {
//                usedWords.append(word)
//            }
//        }
//
//        return usedWords
        
        //functional way of doing all that
        return words.shuffled().filter(place)
    }
    
    func renderToPDF() -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin = pageRect.width / 10
        
        let availableSpace = pageRect.width - (margin * 2)
        let gridCellSize = availableSpace / CGFloat(gridSize)
        
        let gridLetterFont = UIFont.systemFont(ofSize: 16)
        let gridLetterStyle = NSMutableParagraphStyle()
        gridLetterStyle.alignment = .center
        
        let gridLetterAttributes: [NSAttributedString.Key: Any] = [
            .font: gridLetterFont,
            .paragraphStyle: gridLetterStyle
        ]
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { ctx in
            for _ in 0 ..< numberOfPages {
                ctx.beginPage()
                
                _ = makeGrid()
                
                //Write Grid
                for i in 0 ... gridSize {
                    let linePosition = CGFloat(i) * gridCellSize
                    
                    //rows?
                    ctx.cgContext.move(to: CGPoint(x: margin, y: margin + linePosition))
                    ctx.cgContext.addLine(to: CGPoint(x: margin + (CGFloat(gridSize) * gridCellSize), y: margin + linePosition))
                    
                    //columns?
                    ctx.cgContext.move(to: CGPoint(x: margin + linePosition, y: margin))
                    ctx.cgContext.addLine(to: CGPoint(x: margin + linePosition, y: margin + (CGFloat(gridSize) * gridCellSize)))
                }
                
                //draw the path we've added in the above lines
                ctx.cgContext.setLineCap(.square)
                ctx.cgContext.strokePath()
                
                //Draw Letters Inside Grid
                var xOffset = margin
                var yOffset = margin
                
                for column in labels {
                    for label in column {
                        let size = String(label.letter).size(withAttributes: gridLetterAttributes)
                        let yPosition = (gridCellSize - size.height) / 2
                        let cellRect = CGRect(x: xOffset, y: yOffset + yPosition, width: gridCellSize, height: gridCellSize)
                        String(label.letter).draw(in: cellRect, withAttributes: gridLetterAttributes)
                        xOffset += gridCellSize
                    }
                    
                    xOffset = margin
                    yOffset += gridCellSize
                }
            }
        }
    }
}
