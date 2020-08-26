import Foundation

public class Configuration {
        
    let populationSize: Int
    let mutationProbability: Float
    let maxGenerations: Int
    let parentCount: Int
    let maxNumberPermutation: Int
    
    public init(populationSize: Int, mutationProbability: Float,
                maxGenerations: Int, parentCount: Int, maxNumberPermutation: Int) {
        
        self.populationSize = populationSize
        self.mutationProbability = mutationProbability
        self.maxGenerations = maxGenerations
        self.parentCount = parentCount
        self.maxNumberPermutation = maxNumberPermutation
    }
}
