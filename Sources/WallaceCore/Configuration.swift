import Foundation

public class Configuration {
        
    let populationSize: Int
    let mutationProbability: Float
    let parentCount: Int
    let maxNumberPermutation: Int
    let maxGenerations: Int
    
    public init(populationSize: Int, mutationProbability: Float,
                maxGenerations: Int, parentCount: Int, maxNumberPermutation: Int) {
        
        assert(populationSize >= parentCount, "Population size must be greater than the parent count")
        self.populationSize = populationSize
        self.mutationProbability = mutationProbability
        self.maxGenerations = maxGenerations
        self.parentCount = parentCount
        self.maxNumberPermutation = maxNumberPermutation
    }
}
