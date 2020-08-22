# Wallace

## Literature on genetic algorithms

A genetic algorithm is a search heuristic that is inspired by Charles Darwin’s theory of natural evolution. This algorithm reflects the process of natural selection where the fittest individuals are selected for reproduction in order to produce offspring of the next generation.

The process of natural selection starts with the selection of fittest individuals from a population. They produce offspring which inherit the characteristics of the parents and will be added to the next generation. If parents have better fitness, their offspring will be better than parents and have a better chance at surviving. This process keeps on iterating and at the end, a generation with the fittest individuals will be found.

From: https://towardsdatascience.com/introduction-to-genetic-algorithms-including-example-code-e396e98d8bf3

Scholar articles:

- http://www.wseas.us/e-library/conferences/2012/Paris/ECCS/ECCS-14.pdf
- http://mat.uab.cat/~alseda/MasterOpt/GeneticOperations.pdf

## Description of the chromosome

A chromosome represents the list of all the students. So if we represent each student by a number between 0 and N - 1, where N is the number of 
students, then each gene of the chromosome is a number between 0 and N - 1.

The group to which a student belongs is going to be its position in the chromosome. For example

```
 2 3 4 5 7 1 8 9 6
 1 1 1 2 2 2 3 3 3
```

The chromosome here is 234571896, and the first group is 2,3,4, the second group is 5,7,1 and the  last group is 8,9,6

## Description of the algorithm

```
Generate P chromosomes, this is the initial population. Currently random, but the initial population could be seeded with "good" chromosomes

While the generation has not reached the threshold
    Calculate the fitness of each chromosome in the population
    Select X parents with the best fit 

    Generate P - X offprings: 
        Select two parents Among the X and apply crossover
        
    For each offspring:
        With a probability P, apply a mutation 
    
    New population is the selected parents and the offsprings
    Generation is incremented

Return the fittest parent
``` 
