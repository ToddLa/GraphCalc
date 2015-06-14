//
//  GraphViewController.swift
//  GraphCalc
//
//  Created by Todd Laney on 6/2/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource
{
    // this is the function to be graphed, set this when you prepare me
    var function : ((Double) -> Double?)?

    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
        }
    }

    // MARK: GraphViewDataSource

    func evaluateGraph(sender: GraphView, atX: Double) -> Double? {
        return function?(atX)
    }
}
