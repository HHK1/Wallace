import Foundation
import WallaceCore
import ArgumentParser


struct Options: ParsableArguments {

    @Option(help: "The desired size of groups")
    var groupSize: Int = 3

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

    @Flag(help: "Enable debug logs")
    var debug = false
}

struct Wallace: ParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "Group students for each activity",
                                                    subcommands: [JuraGroups.self, CreaGroups.self, RedressementGroups.self, ScaleUpGroups.self, ExportStudents.self, RunAll.self])

    struct JuraGroups: ParsableCommand  {
        
        @Argument(help: "The input file url containing the students")
        var url: String
        
        @OptionGroup var options: Options

        func run() throws {
            
            CLILogger.shared.debug = options.debug
            let data = try String(contentsOf: URL(fileURLWithPath: url))
            let students = parseStudentFile(data: data)
            _ = try makeJuraGroups(students: students, options: options)
        }
    }
    
    struct CreaGroups: ParsableCommand  {
        
        @OptionGroup var options: Options

        func run() throws {
            
            CLILogger.shared.debug = options.debug
            let students = try decodeStudents()
            _ = try makeCreaGroups(students: students, options: options)
        }
    }
    
    struct ScaleUpGroups: ParsableCommand  {
          
          @OptionGroup var options: Options

          func run() throws {
              
              CLILogger.shared.debug = options.debug
              let students = try decodeStudents()
              _ = try makeScaleUpGroups(students: students, options: options)
          }
    }
    
    struct RedressementGroups: ParsableCommand  {
          
          @OptionGroup var options: Options

          func run() throws {
              
              CLILogger.shared.debug = options.debug
              let students = try decodeStudents()
              _ = try makeRedressementGroups(students: students, options: options)
          }
    }
    
    struct ExportStudents: ParsableCommand {
                
        func run() throws {
            
            let students = try decodeStudents()
            try exportStudents(students: students)
        }
    }
    
    struct RunAll: ParsableCommand  {
        
        @Argument(help: "The input file url containing the students")
        var url: String
        
        @OptionGroup var options: Options

        func run() throws {
            CLILogger.shared.debug = options.debug
            let data = try String(contentsOf: URL(fileURLWithPath: url))
            var students = parseStudentFile(data: data)
            students = try makeJuraGroups(students: students, options: options)
            students = try makeCreaGroups(students: students, options: options)
            students = try makeScaleUpGroups(students: students, options: options)
            students = try makeRedressementGroups(students: students, options: options)
            try exportStudents(students: students)
        }
    }
}


func makeJuraGroups(students: [HECStudent], options: Options) throws -> [HECStudent] {
    let groups = makeGroups(students: students, options: options)
    let updatedStudents = generateNewStudents(groups: groups, keyPath: \.juraGroups)
    try saveGroupsAndStudents(groups: groups, students: updatedStudents, filename: "jura.txt")
    return updatedStudents
}

func makeCreaGroups(students: [HECStudent], options: Options) throws -> [HECStudent] {
    let highTouchStudents = students.filter({ $0.mineur == Mineur.HighTouch })
    let deepTechStudents = students.filter({ $0.mineur == Mineur.DeepTech })

    let highTouchGroups = makeGroups(students: highTouchStudents, options: options)
    let deepTechGroups = makeGroups(students: deepTechStudents, options: options)
    
    var groups = highTouchGroups
    groups.append(contentsOf: deepTechGroups)
    let updatedStudents = generateNewStudents(groups: groups, keyPath: \.creaGroups)
    try saveGroupsAndStudents(groups: groups, students: updatedStudents, filename: "crea.txt")
    return updatedStudents
}

func makeScaleUpGroups(students: [HECStudent], options: Options) throws -> [HECStudent] {
    let groups = makeGroups(students: students, options: options)
    let updatedStudents = generateNewStudents(groups: groups, keyPath: \.scaleUpGroups)
    try saveGroupsAndStudents(groups: groups, students: updatedStudents, filename: "scaleUp.txt")
    return updatedStudents
}

func makeRedressementGroups(students: [HECStudent], options: Options) throws -> [HECStudent] {
    let groups = makeGroups(students: students, options: options)
    let updatedStudents = generateNewStudents(groups: groups, keyPath: \.redressementGroups)
    try saveGroupsAndStudents(groups: groups, students: updatedStudents, filename: "redressement.txt")
    return updatedStudents
}

func exportStudents(students: [HECStudent]) throws {
    let export = students.reduce(HECStudent.csvTitle) { (aggregated, student) -> String in
        return "\(aggregated)\(student.description)\n"
    }
    try writeToFile(data: Data(export.utf8), path: "export.csv")
}


func makeGroups(students: [HECStudent], options: Options) -> [Array<HECStudent>] {
    let configuration = Configuration(populationSize: options.populationSize,
                                                 mutationProbability: options.mutationProbability,
                                                 maxGenerations: options.maxGeneration,
                                                 parentCount: options.parentCount,
                                                 maxNumberPermutation: options.maxNumberPermutation)
               
    let factors: [Float] = [5.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0  ]
    let grouping = Grouping(students: students, factors: factors,
                            groupSize: options.groupSize, configuration: configuration)
    let groups = grouping.run()
    let isValid = HECStudent.areGroupsValid(students: students, groups: groups)
    if (!isValid) {
        logError("Group is not valid !")
    } else {
        logInfo("Group is valid")
    }
    return groups
}

func generateNewStudents(groups: [Array<HECStudent>], keyPath: WritableKeyPath<HECStudent, Optional<Vector>>) -> [HECStudent] {
    let groupSize = groups.count

    return groups.enumerated().reduce([], { (newStudents, entry) -> [HECStudent] in
        let (index, group) = entry
        var groupVector = Array<Float>(repeating: 0, count: groupSize)
        groupVector[index] = 1
        
        let groupStudents = group.map { (student) -> HECStudent in
            var studentCopy = student
            studentCopy[keyPath: keyPath] = groupVector
            return studentCopy
        }
        var next = Array.init(newStudents)
        next.append(contentsOf: groupStudents)
        return next
    })
}

/**
   Save  the generated groups into a file, and save the students with their group vector into the intermediary file save
*/
func saveGroupsAndStudents(groups: [Array<HECStudent>], students: [HECStudent], filename: String) throws {
    let encoder = JSONEncoder()
    let simplifiedGroups = groups.map { $0.map { $0.shortDescription }}
    let simpfliedGroupsString = simplifiedGroups.reduce("", { (stringData, group) -> String in
        var newData = stringData
        newData.append(contentsOf: group.joined(separator: ", "))
        newData.append("\n")
        return newData
    })
    let studentsEncoded = try encoder.encode(students)
    try writeToFile(data: simpfliedGroupsString.data(using: .utf8)!, path: filename)
    try writeToFile(data: studentsEncoded, path: "students.json")
}

/**
    Decode the students  objects from the intermediary file save
 */
func decodeStudents() throws -> Array<HECStudent> {
    let decoder = JSONDecoder()
    let data = try Data(contentsOf: URL(fileURLWithPath: "students.json"))
    let students = try decoder.decode(Array<HECStudent>.self, from: data)
    return students
}

Wallace.main()

