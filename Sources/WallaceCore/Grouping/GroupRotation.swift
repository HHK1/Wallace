//
//  File.swift
//  
//
//  Created by Henry Huck on 29/07/2021.
//

import Foundation


// An actual group of members from the population
public typealias Group = Array<Int>
// A solution to a grouping problem, i.e a group of group
public typealias Rotation = Array<Group>
// A map indexed by the Id of the individual to keep the encounters of each individual after all the computed rotations
typealias Encounters = Array<Array<Int>>
/*
Given a population from a given size, each individual is identified with an Int.
During each rotation, each individual is grouped with others in a group of size groupSize.
The goal is to create numberOfRotations rotations, so that during each rotation, an individual never meets
the same individuals twice.
 
There is no guarantee that a solution exists depending on the parameters size. This is a greedy algorithm that will verify
the validity of solutions and will
*/
public func createGroupRotations(populationSize: Int, groupSize: Int, numberOfRotations: Int) -> Array<Rotation> {
    
    let population = Array(0...populationSize - 1)
    var rotations: Array<Rotation> = Array.init(repeating: [], count: numberOfRotations)
    print(populationSize, groupSize, numberOfRotations)
    // The list of individuals that each person has already met. Indexed by the ID of the individual.
    var encounters: Encounters = Array.init(repeating: [], count: populationSize)
    let firstRotation: Rotation = population.chunked(into: groupSize)
    encounters = updateEncounters(encounters: encounters, rotation: firstRotation)
    
    rotations[0] = firstRotation
    
    for i in 1..<numberOfRotations {
        var rotation = generateRotation(population: population, groupSize: groupSize, encounters: encounters)
        while !isRotationValid(rotation: rotation, groupSize: groupSize) {
            rotation = generateRotation(population: population, groupSize: groupSize, encounters: encounters)
        }
        encounters = updateEncounters(encounters: encounters, rotation: rotation)
        rotations[i] = rotation
    }
    print(rotations)
    return rotations
}

func updateEncounters(encounters: Encounters, rotation: Rotation) -> Array<Array<Int>> {
    
    var updatedEncounters = encounters
    rotation.forEach { (group) in
        group.forEach { (id) in
            updatedEncounters[id] = group.filter({ $0 != id})
        }
    }
    return updatedEncounters
}

func generateRotation(population: Array<Int>, groupSize: Int, encounters: Encounters) -> Rotation {
    var unMatchedPopulation = population.shuffled()
    var rotation: Rotation = []
    while unMatchedPopulation.count > 0 {
        let id = unMatchedPopulation.removeFirst()
        var group = [id]
        while group.count < groupSize {
            let peopleMet = group.reduce([]) { (acc, memberId) -> Array<Int> in
                return acc + encounters[memberId]
            }
            guard let nextIdIndex = unMatchedPopulation.firstIndex(where: { !peopleMet.contains($0) }) else {
                break
            }
            let nextId = unMatchedPopulation[nextIdIndex]
            group.append(nextId)
            unMatchedPopulation.remove(at: nextIdIndex)
        }
        rotation.append(group)
    }
    return rotation
}

func isRotationValid(rotation: Rotation, groupSize: Int) -> Bool {
    return rotation.filter({ $0.count != groupSize }).isEmpty
}
