import Foundation
import WallaceCore
import ArgumentParser


struct Options: ParsableArguments {

    @Option(help: "The size of a population at a given generation")
    var populationSize: Int = 20

    @Option(help: "Number of parents selected at a given generation")
    var parentCount: Int = 3

    @Option(help: "Probability of a mutation happening on a child chromosome")
    var mutationProbability: Float = 0.7

    @Option(help: "Max number of generations. Increase to run the algorithm longer")
    var maxGeneration: Int = 500
    
    @Option(help: "The max number of permutations in a single mutation")
    var maxNumberPermutation: Int = 5
    
    @Option(help: "Number of random parents added at each generation")
    var randomParents: Int = 0
    
    @Option(help: "Set the log level. Defaults to info.")
    var logLevel: String = "info"
}

struct Workshops: ParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "Manage workshops",
                                                    subcommands: [Workshops.List.self, Workshops.Show.self, Workshops.Update.self, Workshops.Delete.self, Workshops.New.self], defaultSubcommand: Workshops.List.self)
    
    struct Options: ParsableArguments {
        @Option var groupSize: Int
        @Option var hetero: [EncodedFactor] = []
        @Option var homo: [EncodedFactor] = []
        @Flag var hike = false
    }
    
    struct List: ParsableCommand {
        
        func run() throws {
            print("Workshops: \n")
            Workshop.allValues.forEach({ (workshop) in
                print(workshop.name)
            })
        }
    }
    
    struct Show: ParsableCommand {
        
        @Argument(help: "Name of the workshop")
        var workshopName: String
        
        func run() throws {
            let workshop = try Workshop.getWorkshop(name: workshopName)
            print(workshop.description)
        }
    }
    
    struct Delete: ParsableCommand {
        
        @Argument(help: "Name of the workshop")
        var workshopName: String
        
        func run() throws {
            let workshop = try Workshop.getWorkshop(name: workshopName)
            Workshop.allValues = Workshop.allValues.filter({ $0.name != workshop.name })
            try Workshop.save()
        }
    }
    
    struct New: ParsableCommand {
        @Argument(help: "Name of the workshop")
        var workshopName: String
        
        @OptionGroup var options: Options
        
        func run() throws {
            let existing = Workshop.allValues.first(where: { $0.name == workshopName })
            
            if (existing != nil) {
                assertionFailure("Workshop \(workshopName) already exists")
            }

            print("Creating workshop \(workshopName) \n")
            print("Filling heterogeneous factors: \n")
            let rawHeterogeneousFactors = Workshops.getFactorsInput(keys: options.hetero)
            print("Filling homogeneous factors: \n")
            let rawHomoFactors = Workshops.getFactorsInput(keys: options.homo)
            
            var hikeConfiguration: HikeConfiguration? = nil
            if options.hike {
                print("Getting configuration for hike\n")
                print("Enter the number of hike rotations")
                let rotations = getNumberInput()
                print("Enter the number of groups for each meta groups")
                let groupSize = getNumberInput()
                hikeConfiguration = HikeConfiguration(groupSize: groupSize, numberOfRotations: rotations)
            }
            
            let workshop = Workshop(name: workshopName, groupSize: options.groupSize, rawHeterogeneousFactors: rawHeterogeneousFactors, rawHomogeneousFactors: rawHomoFactors, hikeConfiguration: hikeConfiguration)
            Workshop.allValues.append(workshop)
            try Workshop.save()
            
            logInfo("Created Workshop: \n")
            print(workshop.description)
        }
    }
    
    struct Update: ParsableCommand {
        @Argument(help: "Name of the workshop")
        var workshopName: String
                
        func run() throws {
            var workshop = try Workshop.getWorkshop(name: workshopName)
            
            print("Updating workshop \(workshopName) \n")
            
            print("Enter new group size (current value: \(workshop.groupSize)): \n")
            let groupSize = getNumberInput(defaultValue: workshop.groupSize)
            print("Updating heterogeneous factors: \n")
            let rawHeterogeneousFactors = Workshops.getFactorsInput(keys: Array(workshop.rawHeterogeneousFactors.keys))
            
            var rawHomogeneousFactors = workshop.rawHomogeneousFactors
            if let factors = workshop.rawHomogeneousFactors, !factors.isEmpty {
                print("Filling homogeneous factors: \n")
                rawHomogeneousFactors = Workshops.getFactorsInput(keys: Array(factors.keys))
            }
            
            var hikeConfiguration: HikeConfiguration? = workshop.hikeConfiguration
            if let configuration = hikeConfiguration {
                print("Getting configuration for hike\n")
                print("Enter the number of hike rotations (current value: \(configuration.numberOfRotations)):")
                let rotations = getNumberInput(defaultValue: configuration.numberOfRotations)
                print("Enter the size of each groups (current value: \(configuration.groupSize)):")
                let groupSize = getNumberInput(defaultValue: configuration.groupSize)
                hikeConfiguration = HikeConfiguration(groupSize: groupSize, numberOfRotations: rotations)
            } else {
                print("Do you want to add a hike config? (y/n):")
                if readLine() == "y" {
                    print("Enter the number of hike rotations:")
                    let rotations = getNumberInput()
                    print("Enter the size of each groups:")
                    let groupSize = getNumberInput()
                    hikeConfiguration = HikeConfiguration(groupSize: groupSize, numberOfRotations: rotations)
                }g
            }
            
            workshop = Workshop(name: workshopName, groupSize: groupSize, rawHeterogeneousFactors: rawHeterogeneousFactors, rawHomogeneousFactors: rawHomogeneousFactors, hikeConfiguration: hikeConfiguration)
            
            var workshops = Workshop.allValues.filter({ $0.name != workshopName })
            workshops.append(workshop)
            Workshop.allValues = workshops
            try Workshop.save()
            
            logInfo("Updated Workshop: \n")
            print(workshop.description)
        }
    }
    
    private static func getFactorsInput(keys:  [EncodedFactor]) -> Dictionary<EncodedFactor, Int> {
        var rawFactors: Dictionary<EncodedFactor, Int> = [:]
        keys.forEach({ (key) in
            print("Enter multiplier for \(key)")
            rawFactors[key] = getNumberInput()
        })
        return rawFactors
    }
    
    private static func getNumberInput(defaultValue: Int? = nil) -> Int {
        let input = readLine(strippingNewline: true)
        var value = Int(input ?? "")
        while value == nil {
            print("Wrong input, please enter a valid number")
            let input = readLine(strippingNewline: true)
            value = Int(input ?? defaultValue?.description ?? "")
        }
        return value!
    }
}

struct Students: ParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "Manage students",
                                                    subcommands: [Load.self,  Group.self, HikeGroups.self, Export.self, RunAll.self, RemoveWorkshop.self])

    struct Load: ParsableCommand {
        @Argument(help: "The input file url containing the students")
        var url: String
        
        func run() throws {
            try initialize(url: url)
        }
    }
    
    struct Group: ParsableCommand  {

        @Argument(help: "Name of the workshop")
        var workshopName: String
        
        @OptionGroup var options: Options

        func run() throws {
            let workshop = try Workshop.getWorkshop(name: workshopName)
            try runWorkshopCommand(workshop: workshop, options: options)
        }
    }
    
    struct HikeGroups: ParsableCommand {
        
        @Argument(help: "Name of the workshop")
        var workshopName: String
        
        @OptionGroup var options: Options
        
        func run() throws {
            let workshop = try Workshop.getWorkshop(name: workshopName)
            try makeHikeRotation(students: HECStudent.students, workshop: workshop)
        }
    }
    
    
    struct Export: ParsableCommand {
                
        func run() throws {
            try exportAll()
        }
    }
    
    struct RunAll: ParsableCommand  {
        
        @Argument(help: "The input file url containing the students")
        var url: String
        
        @OptionGroup var options: Options

        func run() throws {
            try initialize(url: url)
            try Workshop.allValues.forEach({ try runWorkshopCommand(workshop: $0, options: options) })
            try Workshop.allValues.forEach({ (worshop) in
                if (worshop.hikeConfiguration == nil) { return }
                try Students.makeHikeRotation(students: HECStudent.students, workshop: worshop)
            })
            try exportAll()
        }
    }
    
    struct RemoveWorkshop: ParsableCommand {
        
        @Argument(help: "The workshop to remove.")
        var workshopName: String
        
        func run() throws {
            let worshop = try Workshop.getWorkshop(name: workshopName)
            HECStudent.students.forEach({ $0.groups[worshop.name] = nil; $0.studentsMetByWorshop[worshop.name] = nil; })
            try HECStudent.save()
        }
        
    }
    
    private static func initialize(url: String) throws {
        let data = try String(contentsOf: URL(fileURLWithPath: url))
        let students = parseStudentFile(data: data)
        try encodeStudents(students: students)
    }
    
    private static func runWorkshopCommand(workshop: Workshop, options: Options) throws {
        CLILogger.shared.logLevel = LogLevel(value: options.logLevel)
        let updatedStudents = try makeWorkshop(students: HECStudent.students, workshop: workshop, options: options)
        try encodeStudents(students: updatedStudents)
    }
    
    /**
     Make the groups for the given workshop and return students with updated group infos 
    */
    private static func makeWorkshop(students: [HECStudent], workshop: Workshop, options: Options) throws -> [HECStudent] {
        logInfo("Starting groups for workshop \n \(workshop)")
        let groups = makeGroups(students: students, options: options, workshop: workshop)
        let updatedStudents = updateStudents(with: groups, for: workshop)
        return updatedStudents
    }
    
    /**
     Run the grouping algorithm for the given students, merging the options from the passed options and the workshop.
    */
    private static func makeGroups(students: [HECStudent], options: Options, workshop: Workshop) -> [Array<HECStudent>] {
        let configuration = Configuration(populationSize: options.populationSize,
                                                     mutationProbability: options.mutationProbability,
                                                     maxGenerations: options.maxGeneration,
                                                     parentCount: options.parentCount,
                                                     maxNumberPermutation: options.maxNumberPermutation,
                                                     randomParents: options.randomParents)
                   
        let grouping = Grouping(students: students, heterogeneousFactors: workshop.heterogeneousFactors, homogeneousFactors: workshop.homogeneousFactors, groupSize: workshop.groupSize, configuration: configuration, verify: { (groups) -> Bool in
            return isSolutionValid(groups: groups, workshop: workshop)
        })
        let groups = grouping.run()
        return groups
    }
    
    private static func makeHikeRotation(students: [HECStudent], workshop: Workshop) throws {
        guard let hikeConfiguration = workshop.hikeConfiguration else {
            logError("Workshop \(workshop) is missing a hike configuration")
            throw CLIException.invalidWorkshopName
        }
        
        let groups = try getGroups(from: students, for: workshop)
        let rotations = createGroupRotations(populationSize: groups.count, groupSize: hikeConfiguration.groupSize, numberOfRotations: hikeConfiguration.numberOfRotations)
        let updatedStudents = updateStudents(students: students, with: rotations, groups: groups)
        try encodeStudents(students: updatedStudents)
        for (index, rotation) in rotations.enumerated() {
            try exportRotation(fileName: "Jura jour \(index + 1).txt", rotation: rotation, groups: groups)
        }
    }
    
    private static func exportAll() throws {
        try exportStudents(students: HECStudent.students)
        Workshop.allValues.forEach { (workshop) in
            do {
                let groups = try getGroups(from: HECStudent.students, for: workshop)
                try exportGroups(groups: groups, filename: workshop.fileName)
            } catch (let error) {
                logError("Failed to export group", error.localizedDescription)
            }
        }
    }
}

struct Wallace: ParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "Create groups for the year",
                                                    subcommands: [Workshops.self, Students.self])

}
Wallace.main()

