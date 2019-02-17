//
//  ViewController.swift
//  WordSearch
//
//  Created by Ryan Token on 2/17/19.
//  Copyright © 2019 Token Solutions. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let path = Bundle.main.url(forResource: "capitals", withExtension: "json")!
        let contents = try! Data(contentsOf: path)
        let words = try! JSONDecoder().decode([Word].self, from: contents)
        
        let wordSearch = WordSearch()
        wordSearch.words = words
        //wordSearch.makeGrid()
        
        let output = wordSearch.renderToPDF()
        let url = getDocumentsDirectory().appendingPathComponent("output.pdf")
        
        print(url)
        try? output.write(to: url)
    }

    func getDocumentsDirectory() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return path[0]
    }
}

