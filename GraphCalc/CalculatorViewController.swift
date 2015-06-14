//
//  CalculatorViewController.swift
//  Calculator
//
//  Created by Todd Laney on 4/23/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController
{
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var status: UILabel!
    
    private var enteringNumber = false
    private var brain = CalculatorBrain()
    private let memoryName = "ℳ"  // variable name used for Memory
    private let errorColor = UIColor.redColor()
    private var normalColor = UIColor.blackColor()

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override func viewDidLoad()
    {
        // make each button a round rect
        for child in view.subviews {
            if let button = child as? UIButton {
                button.layer.cornerRadius = 4.0
            }
        }
        normalColor = display.textColor // use color in storyboard
        display.adjustsFontSizeToFitWidth = true
        status.adjustsFontSizeToFitWidth = true
        clear()
    }
    
    @IBAction func appendDot(sender: UIButton)
    {
        println("appendDot: \(sender.currentTitle!)")
        if (!enteringNumber || display.text!.rangeOfString(".") == nil) {
            appendDigit(sender)
        }
    }
    @IBAction func appendDigit(sender: UIButton)
    {
        if let digit = sender.currentTitle {
            println("appendDigit: \(digit)")
            
            if enteringNumber {
                display.text = display.text! + digit
            }
            else {
                display.text = digit
                enteringNumber = true
            }
            update()
        }
    }
    
    @IBAction func clear()
    {
        println("CLEAR")
        brain.clear()
        enteringNumber = false
        update()
    }
    
    @IBAction func erase() {
        if enteringNumber {
            var num = display.text!
            removeLast(&num)
            display.text = count(num) > 0 ? num : "0"
        } else {
            brain.undo()
        }
        update()
    }
    
    @IBAction func useMemory() {
        if enteringNumber {
            enter()
        }
        brain.pushOperand(memoryName)
        update()
    }

    @IBAction func setMemory() {
        if let x = displayValue {
            brain.setVariable(memoryName, x)
            enteringNumber = false
            update()
        }
    }

    @IBAction func changeSign(sender: UIButton) {
        if enteringNumber {
            display.text = "\(-(displayValue ?? 0))"
        } else {
            operate(sender)
        }
    }
    @IBAction func operate(sender: UIButton)
    {
        if let operation = sender.currentTitle {
            if enteringNumber {
                enter()
            }
            brain.pushOperation(operation)
            update()
        }
     }
    
    @IBAction func enter()
    {
        enteringNumber = false
        if let value = displayValue {
            brain.pushOperand(value)
            update()
        }
    }

    // update UI to match state of the model (aka brain)
    private func update()
    {
        var desc = brain.fullDescription

        if enteringNumber {
            status.text = " " + desc
            display.textColor = normalColor
        } else {
            if count(desc) == 0 {
                status.text = " "
                display.text = "0.0"
                display.textColor = normalColor
            } else {
                status.text = desc + "="
                var result = brain.evaluateResult()
                display.text = result.description
                display.textColor = result.value == nil ? errorColor : normalColor
            }
        }
    }
    
    private var displayValue: Double? {
        get {
            return NSNumberFormatter().numberFromString(display.text!)?.doubleValue
        }
    }
    
    struct Strings {
        static let ShowGraphSegueIdent = "ShowGraph"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let gvc = segue.destination as? GraphViewController {
            if segue.identifier == Strings.ShowGraphSegueIdent {
                
                var newBrain = CalculatorBrain()
                newBrain.program = brain.program
                
                gvc.title = newBrain.description
 
                gvc.function = {
                    newBrain.setVariable(self.memoryName, $0)
                    return newBrain.evaluate()
                }
            }
        }
    }

}

extension UIStoryboardSegue
{
    var destination : UIViewController? {
        var dvc = self.destinationViewController as? UIViewController
        if let nav = dvc as? UINavigationController {
            dvc = nav.visibleViewController
        }
        return dvc
    }
}

