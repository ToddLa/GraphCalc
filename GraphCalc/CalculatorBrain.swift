//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Todd Laney on 5/6/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import Foundation

class CalculatorBrain : Printable
{
    // Error strings
    struct Errors {
        static let UndefinedVar = "Undefined Variable"
        static let MissingOp = "Operand Missing"
        static let DivideZero = "Division by Zero"
        static let Imaginary = "keep it Real!"
    }

    // Result either a Double or Error string
    enum Result : Printable {
        case Value(Double)
        case Error(String)

        var description : String {
            switch self {
            case .Value(let val): return String(format:"%g", val)
            case .Error(let err): return "\(err)"
            }
        }
        var value : Double? {
            switch self {
            case .Value(let val): return val
            case .Error(let err): return nil
            }
        }
        var error : String? {
            switch self {
            case .Value(let val): return nil
            case .Error(let err): return err
            }
        }
        var doubleValue : Double {
            switch self {
            case .Value(let val): return val
            case .Error(let err): return Double.NaN
            }
        }
    }

    // Op
    private enum Op : Printable {
        case Operand(Double)
        case Variable(String)
        case Constant(sym:String, val:Double)
        case UnaryOperation(sym:String, f:(Double) -> Result)
        case BinaryOperation(sym:String, precedence:Int, f:(Double, Double) -> Result)
        
        var description : String {
            switch self {
                case .Operand(let val): return "\(val)"
                case .Constant(let symbol, _): return symbol
                case .Variable(let symbol): return symbol
                case .UnaryOperation(let op): return op.sym
                case .BinaryOperation(let op): return op.sym
            }
        }
    }
    
    private var opStack = [Op]()
    private var knownOps = [String : Op]()
    private var variableValues  = [String : Double]()
    private let debug = false

    init ()
    {
        func learn(op : Op) {
            knownOps[op.description] = op
        }

        // Constants
        learn(.Constant(sym:"π", val:M_PI))
        learn(.Constant(sym:"e", val:M_E))

        // Binary Ops
        learn(.BinaryOperation(sym:"+", precedence:1, f:{.Value($0 + $1)}))
        learn(.BinaryOperation(sym:"-", precedence:1, f:{.Value($0 - $1)}))
        learn(.BinaryOperation(sym:"×", precedence:2, f:{.Value($0 * $1)}))
        learn(.BinaryOperation(sym:"/", precedence:2, f:{$1.isZero ? .Error(Errors.DivideZero) : .Value($0 / $1)}))
        learn(.BinaryOperation(sym:"^", precedence:4, f:{.Value(pow($0,$1))}))

        // Unary Ops
        learn(.UnaryOperation(sym:"±", f:{.Value($0 * -1)}))
        learn(.UnaryOperation(sym:"√", f:{$0 < 0 ? .Error(Errors.Imaginary) : .Value(sqrt($0))}))
        learn(.UnaryOperation(sym:"sin", f:{.Value(sin($0))}))
        learn(.UnaryOperation(sym:"cos", f:{.Value(cos($0))}))
        learn(.UnaryOperation(sym:"tan", f:{.Value(tan($0))}))
    }

    /// get/set the currect state as a PropertyList
    var program : AnyObject {
        get {
            return [
                "stack": opStack.map {$0.description},
                "vars": variableValues
            ]
        }
        set {
            if let dict = newValue as? [String:AnyObject] {
                if let strings = dict["stack"] as? [String] {
                    opStack = strings.map {
                        if let op = self.knownOps[$0] {
                            return op
                        } else if let val = NSNumberFormatter().numberFromString($0)?.doubleValue {
                            return .Operand(val)
                        } else {
                            return .Variable($0)
                        }
                    }
                }
                if let vars = dict["vars"] as? [String:Double] {
                    variableValues = vars
                }
            }
        }
    }
    
    func setVariable(key:String, _ value:Double)
    {
        variableValues[key] = value
    }
    func getVariable(key:String) -> Double?
    {
        return variableValues[key]
    }
    func clearStack()
    {
        opStack = []
    }
    func clearVariables()
    {
        variableValues.removeAll()
    }
    func clear()
    {
        clearStack()
        clearVariables()
    }
    func undo()
    {
        if opStack.count > 0 {
            opStack.removeLast()
        }
    }
    
    func pushOperand(symbol: String) -> Double?
    {
        opStack.append(Op.Variable(symbol))
        return evaluate()
    }
    
    func pushOperand(val: Double) -> Double?
    {
        opStack.append(Op.Operand(val))
        return evaluate()
    }
    
    func pushOperation(symbol: String) -> Double?
    {
        if let op = knownOps[symbol] {
            opStack.append(op)
        }
        return evaluate()
    }

    // recursive helper for evaluateResult
    private func evaluate(stack:[Op]) -> (result:Result, stack:[Op])
    {
        if stack.count > 0 {
            var stack = stack
            var op = stack.removeLast()
            switch op {
            case .Operand(let val):
                return (.Value(val), stack)
            case .Variable(let symbol):
                if let value = variableValues[symbol] {
                    return (.Value(value), stack)
                } else {
                    return (.Error(Errors.UndefinedVar), stack)
                }
            case .Constant(_, let val):
                return (.Value(val), stack)
            case .UnaryOperation(let op):
                var rhs = evaluate(stack)
                if let val = rhs.result.value {
                    rhs.result = op.f(val)
                }
                return (rhs.result, rhs.stack)
            case .BinaryOperation(let op):
                let rhs = evaluate(stack)
                var lhs = evaluate(rhs.stack)
                if let rhv = rhs.result.value {
                    if let lhv = lhs.result.value {
                        lhs.result = op.f(lhv, rhv)
                    }
                }
                else {
                    lhs.result = rhs.result
                }
                return (lhs.result, lhs.stack)
            }
        }
        return (.Error(Errors.MissingOp), stack)
    }

    /// evaluate the current stack as a Result
    func evaluateResult() -> Result
    {
        if debug {
            let eval = evaluate(opStack)
            println("\(opStack) = \(eval.result) with \(eval.stack) left over")
            println("description: \(self) = \(eval.result)")
            println("program: \(program)")
        }

        return evaluate(opStack).result
    }

    /// evaluate the result of the current stack as a Double
    func evaluate() -> Double?
    {
        return evaluateResult().value
    }

    // recursive helper for description
    // returns description of stack as a string, plus the remaining un-evalulated stack
    private func description(stack:[Op]) -> (result:String, stack:[Op], precedence:Int)
    {
        if stack.count > 0 {
            var stack = stack
            var op = stack.removeLast()
            switch op {
            case .Operand(let val):
                let str = String(format:"%g", val)
                return (str , stack, Int.max)
            case .Variable(let symbol):
                return (symbol, stack, Int.max)
            case .Constant(let op):
                return (op.sym, stack, Int.max)
            case .UnaryOperation(let op):
                var rhs = description(stack)
                if count(op.sym) > 1 || rhs.precedence < Int.max {
                    rhs.result = "(" + rhs.result + ")"
                }
                return (op.sym+rhs.result, rhs.stack, Int.max)
            case .BinaryOperation(var symbol, let precedence, _):
                var rhs = description(stack)
                var lhs = description(rhs.stack)
                if lhs.precedence < precedence {
                    lhs.result = "(" + lhs.result + ")"
                }
                if rhs.precedence < precedence {
                    rhs.result = "(" + rhs.result + ")"
                }
                return (lhs.result+symbol+rhs.result, lhs.stack, precedence)
            }
        }
        return ("?", stack, Int.max)
    }
    
    /// render the current `stack` as a string using **infix** notation
    ///
    /// if multiple expressions are on the stack all expressions are rendered separated by commas
    ///
    var fullDescription : String {
        if (opStack.isEmpty) {return ""}
        var desc = description(opStack)
        while desc.stack.count > 0 {
            let str = desc.result
            desc = description(desc.stack)
            desc.result += ", " + str
        }
        return desc.result
    }

    /// render the current `stack` as a string using **infix** notation
    ///
    /// only the "top" expression on the stack (ie the result of evaluate) 
    /// will be returned. use `fullDescription` if you want entire stack.
    ///
    var description : String {
        if (opStack.isEmpty) {return ""}
        return description(opStack).result
    }
}
