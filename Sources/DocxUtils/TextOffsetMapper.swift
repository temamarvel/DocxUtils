//
//  TextOffsetMapper.swift
//  DocxUtils
//
//  Created by Артем Денисов on 20.04.2026.
//


enum TextOffsetMapper {
    static func prefixSums(for lengths: [Int]) -> [Int] {
        var result = Array(repeating: 0, count: lengths.count + 1)
        for index in lengths.indices {
            result[index + 1] = result[index] + lengths[index]
        }
        return result
    }
    
    static func locateStart(
        position: String.Index,
        in fullText: String,
        prefixSums: [Int]
    ) -> TextLocation? {
        let target = fullText.distance(from: fullText.startIndex, to: position)
        
        for i in 0..<(prefixSums.count - 1) {
            let start = prefixSums[i]
            let end = prefixSums[i + 1]
            
            if target >= start && target < end {
                return TextLocation(nodeIndex: i, offset: target - start)
            }
        }
        
        return nil
    }
    
    static func locateEnd(
        position: String.Index,
        in fullText: String,
        prefixSums: [Int]
    ) -> TextLocation? {
        let target = fullText.distance(from: fullText.startIndex, to: position)
        
        if target == fullText.count {
            for i in stride(from: prefixSums.count - 2, through: 0, by: -1) {
                let start = prefixSums[i]
                let end = prefixSums[i + 1]
                if end > start {
                    return TextLocation(nodeIndex: i, offset: end - start)
                }
            }
        }
        
        for i in 0..<(prefixSums.count - 1) {
            let start = prefixSums[i]
            let end = prefixSums[i + 1]
            
            guard end > start else { continue }
            
            if target > start && target <= end {
                return TextLocation(nodeIndex: i, offset: target - start)
            }
        }
        
        return nil
    }
}
