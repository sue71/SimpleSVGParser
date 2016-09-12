//
//  SimpleSVGParser.swift
//  SimpleSVGParser
//
//  Created by Masaki Sueda on 2015/06/29.
//  Copyright (c) 2015年 Masaki Sueda. All rights reserved.
//

import Foundation

let commandOperators = "MmZzLlHhVvCcSsQqTtAa"
let absoluteCommandOperators = "MZLHVCSQTA"

struct SimpleSVGCommand {
    var command:NSString
    var args: [CGFloat]
}

public class SimpleSVGParser:NSObject {
    let PATH_REGEXP = "<path.*?/>"
    let D_REGEXP = "d=\"(.*)\""
    
    var prevPoint:CGPoint = CGPointZero
    var prevControlPoint:CGPoint = CGPointZero
    
    
    public static func buildPathFromSVG(named: String) -> CGPath? {
        let svgParser = SimpleSVGParser()
        return svgParser.buildPathFromSVG(named)
    }
    
    func buildPathFromSVG(named: String) -> CGPath? {
        let path = NSBundle.mainBundle().pathForResource(named, ofType: "svg")
        
        if(path == nil){
            NSLog("[SimpleSVGParser] svg file is not found", named);
            return nil
        }
        
        var error:NSError? = nil
        var svgString: String?
        do {
            svgString = try String(contentsOfFile: path!, encoding:NSUTF8StringEncoding)
        } catch let error1 as NSError {
            error = error1
            svgString = nil
        }
        
        if(error != nil){
            NSLog("[SimpleSVG] cannot read specified svg file", named);
            NSLog("[SimpleSVG][ERROR]", error!);
            return nil
        }
        
        let absoluteSet:NSCharacterSet = NSCharacterSet(charactersInString: absoluteCommandOperators)
        let paths = self.parsePathString(NSString(string:svgString!))
        
        let bezier = UIBezierPath()
        bezier.moveToPoint(self.prevPoint)
        
        for path in paths {
            let commands = self.buildDAttribute(path)
            for svgCommand in commands {
                NSLog("\(svgCommand.command)")
                let isAbsolute = absoluteSet.characterIsMember(svgCommand.command.characterAtIndex(0))
                switch (svgCommand.command.uppercaseString) {
                case "M":
                    // move to
                    self.commandM(bezier, command: svgCommand, isAbsolute: isAbsolute)
                    break
                case "L", "H", "V":
                    // line to
                    self.commandL(bezier, command: svgCommand, isAbsolute: isAbsolute)
                    break
                case "Q":
                    // qubic curve to
                    // Q/q cx, cy, x, y
                    // TODO
                    break
                case "S":
                    // curve to
                    self.commandS(bezier, command: svgCommand, isAbsolute: isAbsolute)
                case "C":
                    // curve to
                    // C/c c1x, c1y, c2x, c2y, x, y
                    self.commandC(bezier, command: svgCommand, isAbsolute: isAbsolute)
                    break
                case "A":
                    // arc to
                    self.commandA(bezier, command: svgCommand, isAbsolute: isAbsolute)
                    break
                case "Z":
                    // cloase path
                    self.commandZ(bezier, command: svgCommand, isAbsolute: isAbsolute)
                    break
                default:
                    NSLog("[SimpleSVGParser][ERROR] illegal format")
                }
            }
        }
        
        return bezier.CGPath
    }
    
    func commandL(bezier: UIBezierPath, command:SimpleSVGCommand, isAbsolute: Bool) {
        let step:Int = 2
        let args = command.args
        
        var index:Int = 0
        
        while step * index < args.count {
            var point = self.prevPoint
            
            switch command.command.uppercaseString {
            case "L":
                if isAbsolute {
                    point.x = CGFloat(args[index])
                    point.y = CGFloat(args[index + 1])
                } else {
                    point.x += CGFloat(args[index])
                    point.y += CGFloat(args[index + 1])
                }
            case "V":
                if isAbsolute {
                    point.y = CGFloat(args[index])
                } else {
                    point.y += CGFloat(args[index])
                }
            case "H":
                if isAbsolute {
                    point.x = CGFloat(args[index])
                } else {
                    point.x += CGFloat(args[index])
                }
            default:
                break
                
            }
            
            bezier.addLineToPoint(point)
            
            self.prevPoint = point
            index += 1
        }
        
    }
    
    func commandM(bezier: UIBezierPath, command:SimpleSVGCommand, isAbsolute: Bool) {
        let step:Int = 2
        let args = command.args
        
        var index:Int = 0
        
        while step * index < args.count {
            var point = self.prevPoint
            
            if isAbsolute {
                point.x = CGFloat(args[0])
                point.y = CGFloat(args[1])
            } else {
                point.x += CGFloat(args[0])
                point.y += CGFloat(args[1])
            }
            
            bezier.moveToPoint(point)
            
            self.prevPoint = point
            index += 1
        }
    }
    
    func commandC(bezier: UIBezierPath, command:SimpleSVGCommand, isAbsolute: Bool) {
        let step:Int = 6
        let args = command.args
        
        var index:Int = 0
        
        while step * index < args.count {
            var c1x:CGFloat = 0,
                c1y:CGFloat = 0,
                c2x:CGFloat = 0,
                c2y:CGFloat = 0,
                x:CGFloat  = 0,
                y:CGFloat  = 0
            
            if isAbsolute {
                c1x = args[index]
                c1y = args[index + 1]
                c2x = args[index + 2]
                c2y = args[index + 3]
                x = args[index + 4]
                y = args[index + 5]
            } else {
                c1x = self.prevPoint.x + args[index]
                c1y = self.prevPoint.y + args[index + 1]
                c2x = self.prevPoint.x + args[index + 2]
                c2y = self.prevPoint.y + args[index + 3]
                x = self.prevPoint.x + args[index + 4]
                y = self.prevPoint.y + args[index + 5]
            }
            
            bezier.addCurveToPoint(CGPointMake(x, y), controlPoint1: CGPointMake(c1x, c1y), controlPoint2: CGPointMake(c2x, c2y))
            
            self.prevPoint = CGPointMake(x, y)
            self.prevControlPoint = CGPointMake(c2x, c2y)
            index += 1
        }
    }
    
    func commandS(bezier: UIBezierPath, command:SimpleSVGCommand, isAbsolute: Bool) {
        let step:Int = 4
        let args = command.args
        
        var index:Int = 0
        
        while step * index < args.count {
            var c1x:CGFloat = 0,
                c1y:CGFloat = 0,
                c2x:CGFloat = 0,
                c2y:CGFloat = 0,
                x:CGFloat  = 0,
                y:CGFloat  = 0
            
            c1x = self.prevPoint.x + (self.prevPoint.x - self.prevControlPoint.x) + args[index]
            c1y = self.prevPoint.y + (self.prevPoint.y - self.prevControlPoint.y) + args[index + 1]
            if isAbsolute {
                c2x = args[index + 2]
                c2y = args[index + 3]
                x = args[index + 4]
                y = args[index + 5]
            } else {
                c2x = self.prevPoint.x + args[index + 2]
                c2y = self.prevPoint.y + args[index + 3]
                x = self.prevPoint.x + args[index + 4]
                y = self.prevPoint.y + args[index + 5]
            }
            
            bezier.addCurveToPoint(CGPointMake(x, y), controlPoint1: CGPointMake(c1x, c1y), controlPoint2: CGPointMake(c2x, c2y))
            
            self.prevPoint = CGPointMake(x, y)
            self.prevControlPoint = CGPointMake(c2x, c2y)
            index += 1
        }
    }
    
    func commandZ(bezier: UIBezierPath, command:SimpleSVGCommand, isAbsolute: Bool) {
        bezier.closePath()
    }
    
    func commandA(bezier: UIBezierPath, command:SimpleSVGCommand, isAbsolute: Bool) {
        // TODO
    }
    
    func parsePathString(svgString:NSString) -> [NSString] {
        // trimming
        let svgString = NSString(string:svgString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
        var error:NSError?
        var pathRegex: NSRegularExpression?
        do {
            pathRegex = try NSRegularExpression(pattern: PATH_REGEXP, options: [NSRegularExpressionOptions.AllowCommentsAndWhitespace, .DotMatchesLineSeparators, NSRegularExpressionOptions.AnchorsMatchLines])
        } catch let error1 as NSError {
            error = error1
            pathRegex = nil
        }
        
        return self.execRegexp(PATH_REGEXP, targetString: svgString)
    }
    
    func buildDAttribute(svgString:NSString) -> [SimpleSVGCommand] {
        let characterSet:NSCharacterSet = NSCharacterSet(charactersInString: commandOperators)
        
        var index:Int = 0
        var commands:[SimpleSVGCommand] = []
        var args:[CGFloat] = []
        
        let dString:NSString = self.execRegexp(D_REGEXP, targetString: svgString)[0]
        
        while index < dString.length {
            var char = dString.characterAtIndex(index)
            var commandStr:NSString? = nil
            
            // search command
            if !characterSet.characterIsMember(char) {
                index += 1
                continue
            } else {
                commandStr = NSString(characters: &char, length: 1)
            }
            
            // search arguments
            var str:NSString = ""
            while ++index < dString.length {
                var valueChar = dString.characterAtIndex(index)
                if UnicodeScalar(valueChar) == "-" {
                    if str.length > 0 {
                        args.append(CGFloat(str.floatValue))
                    }
                    str = "-"
                    continue
                }
                if UnicodeScalar(valueChar) == "," {
                    if str.length > 0 {
                        args.append(CGFloat(str.floatValue))
                    }
                    str = ""
                    continue
                }
                if !characterSet.characterIsMember(valueChar) {
                    str = str.stringByAppendingFormat("%@", NSString(characters: &valueChar, length: 1))
                } else {
                    break
                }
            }
            
            if str.length > 0 {
                args.append(CGFloat(str.floatValue))
                str = ""
            }
            
            if args.count > 0 {
                commands.append(SimpleSVGCommand(command: commandStr!, args: args))
            }
            
            args.removeAll(keepCapacity: false)
        }
        
        return commands
    }
    
    private func execRegexp(pattern: String, targetString:NSString) -> [NSString] {
        var result:[NSString] = []
        var error:NSError?
        let pathRegex: NSRegularExpression?
        do {
            pathRegex = try NSRegularExpression(pattern: pattern, options: [NSRegularExpressionOptions.AllowCommentsAndWhitespace, .DotMatchesLineSeparators, NSRegularExpressionOptions.AnchorsMatchLines])
        } catch let error1 as NSError {
            error = error1
            pathRegex = nil
        }
        
        if error != nil {
            NSLog("[SimpleSVG][ERROR] svg format is illegal")
            return []
        }
        
        var matches:[AnyObject]? = pathRegex?.matchesInString(targetString as String, options: [], range:NSMakeRange(0, targetString.length))
        
        if matches == nil {
            NSLog("[SimpleSVG][ERROR] svg format is illegal")
            return []
        }
        
        if matches!.count > 0 {
            for i in 0..<matches!.count {
                let match = matches![i] as! NSTextCheckingResult
                let count = match.numberOfRanges
                
                for j in 0..<count {
                    let range:NSRange = match.rangeAtIndex(j)
                    let str = NSString(string: targetString).substringWithRange(range)
                    result.append(str)
                }
            }
        }
        
        return result
    }
}