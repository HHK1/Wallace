import Foundation

public class Configuration {
        
    let populationSize: Int
    let mutationProbability: Float
    let maxGenerations: Int
    let parentCount: Int
    
    public init(populationSize: Int, mutationProbability: Float,
                maxGenerations: Int, parentCount: Int) {
        
        self.populationSize = populationSize
        self.mutationProbability = mutationProbability
        self.maxGenerations = maxGenerations
        self.parentCount = parentCount
    }
}
