//
//  index_of.swift
//  SwiftCollectionBenchmark
//
//  Created by 野村 憲男 on 2015/01/14.
//
//

import Foundation

func v1_index_of<C : CollectionType>(domain: C, condition: C.Generator.Element -> Bool) -> C.Index? {
    return find(lazy(domain).map(condition), true)
}

func v2_index_of<C : CollectionType>(domain: C, condition: C.Generator.Element -> Bool) -> C.Index? {
    for (idx, element) in enumerate(domain) {
        if condition(element) {
            return idx as? C.Index
        }
    }
    return nil
}

// from: http://airspeedvelocity.net/2015/01/02/more-fun-with-implicitly-wrapped-non-optionals/
func v3_index_of<C : CollectionType>(domain: C, condition: C.Generator.Element -> Bool) -> C.Index? {
    for (idx, element) in Zip2(indices(domain), domain) {
        if condition(element) {
            return idx
        }
    }
    return nil
}

// from: https://github.com/katokichisoft/SimpleGaplessPlayer/blob/master/HKLAVGaplessPlayer/misc/HKLStdLibUtils.swift
extension Array {
    /**
    Returns the lowest index whose corresponding array value matches a given condition.
    
    :discussion: Starting at index 0, each element of the array is passed as the 1st parameter of condition closure until a match is found or the end of the array is reached. Objects are considered equal if the closure returns true.
    
    :param: condition A closure for finding the target object in the array
    
    :returns: The lowest index whose corresponding array value matches a given condition. If none of the objects in the array matches the condition, returns nil.
    
    :refer: http://stackoverflow.com/a/24105493
    */
    func indexOf(condition: T -> Bool) -> Int? {
        for (idx, element) in enumerate(self) {
            if condition(element) {
                return idx
            }
        }
        return nil
    }
}
