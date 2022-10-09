import Foundation
import WallaceCore
import ArgumentParser


struct Options: ParsableArguments {

    @Option(help: "The size of a population at a given generation")
    var populationSize: Int = 10

    @Option(help: "Number of parents selected at a given generation")
    var parentCount: Int = 5

    @Option(help: "Probability of a mutation happening on a child chromosome")
    var mutationProbability: Float = 0.7

    @Option(help: "Max number of generations. Increase to run the algorithm longer")
    var maxGeneration: Int = 1000
    
    @Option(help: "The max number of permutations in a single mutation")
    var maxNumberPermutation: Int = 4
    
    @Option(help: "Set the log level. Defaults to info.")
    var logLevel: String = "info"
}

struct Wallace: ParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "Group students for each activity",
                                                    subcommands: [Init.self, JuraGroups.self, JuraHikeGroups.self,
                                                                  CreaGroups.self, RedressementGroups.self,
                                                                  ScaleUpGroups.self, ExportStudents.self, RunAll.self])

    struct Init: ParsableCommand {
        @Argument(help: "The input file url containing the students")
        var url: String
        
        func run() throws {
            let data = try String(contentsOf: URL(fileURLWithPath: url))
            let students = parseStudentFile(data: data)
            try encodeStudents(students: students)
        }
    }
    
    struct JuraGroups: ParsableCommand  {

        @OptionGroup var options: Options

        func run() throws {
            try runWorkshopCommand(workshop: .jura, options: options)
        }
    }
    
    struct JuraHikeGroups: ParsableCommand {
        
        @OptionGroup var options: Options
        
        func run() throws {
            let students = try decodeStudents()
            try makeJuraHikeRotation(students: students)
        }
    }
    
    struct CreaGroups: ParsableCommand  {
        
        @OptionGroup var options: Options

        func run() throws {
            try runWorkshopCommand(workshop: .crea, options: options)
        }
    }
    
    struct ScaleUpGroups: ParsableCommand  {
          
          @OptionGroup var options: Options

          func run() throws {
            try runWorkshopCommand(workshop: .scaleUp, options: options)
          }
    }
    
    struct RedressementGroups: ParsableCommand  {
          
          @OptionGroup var options: Options

          func run() throws {
            try runWorkshopCommand(workshop: .redressement, options: options)
          }
    }
    
    struct ExportStudents: ParsableCommand {
                
        func run() throws {
            try exportAll()
        }
    }
    
    struct RunAll: ParsableCommand  {
        
        @Argument(help: "The input file url containing the students")
        var url: String
        
        @OptionGroup var options: Options

        func run() throws {
            try initialize(url: url, options: options)
            try Workshop.allCases.forEach({ try Wallace.runWorkshopCommand(workshop: $0, options: options) })
            let students = try decodeStudents()
            try makeJuraHikeRotation(students: students)
            try exportAll()
        }
    }
    
    private static func initialize(url: String, options: Options) throws {
        let data = try String(contentsOf: URL(fileURLWithPath: url))
        let students = parseStudentFile(data: data)
        try encodeStudents(students: students)
    }
    
    private static func runWorkshopCommand(workshop: Workshop, options: Options) throws {
        CLILogger.shared.logLevel = LogLevel(value: options.logLevel)
        let students = try decodeStudents()
        let updatedStudents = try makeWorkshop(students: students, workshop: workshop, options: options)
        try encodeStudents(students: updatedStudents)
    }
    
    /**
     Make the groups for the given workshop and return students with updated group infos 
    */
    private static func makeWorkshop(students: [HECStudent], workshop: Workshop, options: Options) throws -> [HECStudent] {
        Workshop.promoSize = students.count
        logInfo("Starting groups for workshop \(workshop.rawValue) with groups of size \(workshop.groupSize)")
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
                                                     maxNumberPermutation: options.maxNumberPermutation)
                   
        let grouping = Grouping(students: students, heterogeneousFactors: workshop.heterogeneousFactors, homogeneousFactors: workshop.homogeneousFactors, groupSize: workshop.groupSize, configuration: configuration, verify: { (groups) -> Bool in
            return isSolutionValid(groups: groups, workshop: workshop)
        })
        let groups = grouping.run()
        return groups
    }
    
    private static func makeJuraHikeRotation(students: [HECStudent]) throws {
        let groups = try getGroups(from: students, for: .jura)
        let rotations = createGroupRotations(populationSize: groups.count, groupSize: HikeJura.groupSize, numberOfRotations: HikeJura.numberOfRotations)
        // TODO: the rotations export format sucks
        for (index, rotation) in rotations.enumerated() {
            try exportRotation(fileName: "Jura jour \(index + 1).txt", rotation: rotation, groups: groups)
        }
    }
    
    private static func exportAll() throws {
        let students = try decodeStudents()
        try exportStudents(students: students)
        Workshop.allCases.forEach { (workshop) in
            do {
                let groups = try getGroups(from: students, for: workshop)
                try exportGroups(groups: groups, filename: workshop.fileName)
            } catch (let error) {
                logError("Failed to export group", error.localizedDescription)
            }
        }
    }
}



Wallace.main()

