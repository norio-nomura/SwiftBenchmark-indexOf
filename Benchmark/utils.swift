//
//  utils.swift
//  SwiftCollectionBenchmark
//
//  Created by 野村 憲男 on 2015/01/14.
//
//

import Foundation

// http://airspeedvelocity.net/2014/12/05/zipwith-pipe-forward-and-treating-functions-like-objects/
func cycle
    <S: SequenceType>(source: S)
    -> SequenceOf<S.Generator.Element> {
        return SequenceOf { _->GeneratorOf<S.Generator.Element> in
            var g = source.generate()
            return GeneratorOf {
                if let x = g.next() {
                    return x
                }
                else {
                    g = source.generate()
                    if let y = g.next() {
                        return y
                    }
                    else {
                        // maybe assert here, if you want that behaviour
                        // when passing an empty sequence into cycle
                        return nil
                    }
                }
            }
        }
}

// https://gist.github.com/indragiek/b16f95d911a37cb963a7
public struct RandomNumberGenerator: SequenceType {
    let range: Range<Int>
    let count: Int
    
    public init(range: Range<Int>, count: Int) {
        self.range = range
        self.count = count
    }
    
    public func generate() -> GeneratorOf<Int> {
        var i = 0
        return GeneratorOf<Int> {
            return (i++ == self.count) ? .None : randomNumberFrom(self.range)
        }
    }
}

public func randomNumberFrom(from: Range<Int>) -> Int {
    return from.startIndex + Int(arc4random_uniform(UInt32(from.endIndex - from.startIndex)))
}

public func randomNumbersFrom(from: Range<Int>, #count: Int) -> RandomNumberGenerator {
    return RandomNumberGenerator(range: from, count: count)
}
