# Wallace

Named after [Alfred Russel Wallace](https://en.wikipedia.org/wiki/Alfred_Russel_Wallace), because naming a package Darwin on iOS is a bad idea.

This is a command line tool to generate heterogenous groups of students, specifically for the X-HEC Entrepreneur Master. 
This package is split between `Wallace`, which contains code specific for the use case and wraps it around a command line interface, and the `WallaceCore` package, which is completely agnostic and could be applied to other similar problems.

## Installation

1. Clone the repository
2. Run the following:

```shell
$ swift build -c release
$ cd .build/release
$ cp -f Wallace /usr/local/bin/wallace
```

## Usage

There are two main commands: `workshops` and `students`.

The first one allows to manage the workshops as the requirements changes every year.

For example the workshops in 2024 were created with the following

```shell
wallace workshops new Jura --group-size 3 --hetero gender --hetero school --hetero type --hetero frenchSpeaker --hike
wallace workshops new Start-up --group-size 3 --hetero gender --hetero school --hetero type --hetero frenchSpeaker
wallace workshops new Redressement --group-size 4 --hetero gender --hetero school --hetero type --hetero frenchSpeaker
```

The `new` subcommand takes the name as the main argument, and the following arguments:

- `--group-size`: The desired size of groups 
- `--hetero`: A repeatable flag for the parameters that should be heterogeized 
- `--homo`: A repeatable flag for the parameters that should be homogeneized
- `--hike`: A boolean flag to set if you want to generate groups of groups for this workshop

The `students` command contains the following sub-commands:

- `load`: load the given URL as the initial CSV file and parse it into an intermediary data format
- `group`: run the genetic algorithm to make the group for the given workshop 
- `hike-groups`: run the meta-grouping algorithm to make the hike groups for the given workshop
- `export`: export the intermediary data format to CSV
- `run-all`: run all the workshops and hike groups + the export
- `remove-workshop`: remove a workshop if you want to re-run it

The `group` and `run-all` support the following options:

- `--group-size`: The desired size of groups (default: 3)
- `--population-size`: The size of a population at a given generation (default: 10)
- `--parent-count`: Number of parents selected at a given generation (default: 5)
- `--mutation-probability`: Probability of a mutation happening on a child chromosome (default: 0.7)
- `--max-generation`: Max number of generations. Increase to run the algorithm longer (default: 1000)
-  `--debug`: Enable debug logs



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
        With a probability p, apply a mutation 
    
    New population is the selected parents and the offsprings
    Generation is incremented

Return the fittest parent
``` 

## Contributing 

1. After making modifications, run the tests to make sure the core functionnality is still working
1. Build the tool with `swift build` 
1. Test the commands with `.build/debug/Wallace run-all promo2022.csv` 

## Installing

`make build`

You can now use `wallace` as a standalone CLI.
