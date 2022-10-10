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

struct Wallace: ParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "Group students for each activity",
                                                    subcommands: [Init.self,  Group.self, HikeGroups.self, ExportStudents.self, RunAll.self, Remove.self])

    struct Init: ParsableCommand {
        @Argument(help: "The input file url containing the students")
        var url: String
        
        func run() throws {
            let data = try String(contentsOf: URL(fileURLWithPath: url))
            let students = parseStudentFile(data: data)
            try encodeStudents(students: students)
            
            let jura = Workshop(name: "jura", groupSize: 3, rawHeterogeneousFactors: EncodedFactor.allFactors, rawHomogeneousFactors: nil, hikeConfiguration: HikeConfiguration(groupSize: 4, numberOfRotations: 4))
            let crea = Workshop(name: "crea", groupSize: 3, rawHeterogeneousFactors: [.gender: 10, .school: 10, .type: 10, .englishSpeaker: 10], rawHomogeneousFactors: [.track: 10], hikeConfiguration: nil)
            let scaleup = Workshop(name: "scaleUp", groupSize: 4, rawHeterogeneousFactors: EncodedFactor.allFactors, rawHomogeneousFactors: nil, hikeConfiguration: nil)
            let redressement = Workshop(name: "redressement", groupSize: 4, rawHeterogeneousFactors: EncodedFactor.allFactors, rawHomogeneousFactors: nil, hikeConfiguration: nil)
            
            Workshop.allValues = [jura, crea, scaleup, redressement]
            try Workshop.save()
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
            let students = HECStudent.students
            let workshop = try Workshop.getWorkshop(name: workshopName)
            try makeHikeRotation(students: students, workshop: workshop)
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
            try Workshop.allValues.forEach({ try Wallace.runWorkshopCommand(workshop: $0, options: options) })
            try Workshop.allValues.forEach({ (worshop) in
                if (worshop.hikeConfiguration == nil) { return }
                try Wallace.makeHikeRotation(students: HECStudent.students, workshop: worshop)
            })
            try exportAll()
        }
    }
    
    struct Remove: ParsableCommand {
        
        @Argument(help: "The workshop to remove.")
        var workshopName: String
        
        func run() throws {
            let worshop = try Workshop.getWorkshop(name: workshopName)
            HECStudent.students.forEach({ $0.groups[worshop.name] = nil; $0.studentsMetByWorshop[worshop.name] = nil; })
            try HECStudent.save()
        }
        
    }
    
    private static func initialize(url: String, options: Options) throws {
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
        logInfo("Starting groups for workshop \(workshop) with groups of size \(workshop.groupSize)")
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



Wallace.main()

