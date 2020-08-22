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

    @Flag(help: "Enable debug logs")
    var debug = false
}

struct Wallace: ParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "Group students for each activity",
                                                    subcommands: [JuraGroups.self, CreaGroups.self, RedressementGroups.self, ScaleUpGroups.self])

    struct JuraGroups: ParsableCommand  {
        
        @Argument(help: "The input file url containing the students")
        var url: String
        
        @OptionGroup var options: Options

        func run() throws {
            
            CLILogger.shared.debug = options.debug
            let data = try String(contentsOf: URL(fileURLWithPath: url))
            let students = parseStudentFile(data: data)
            
            let groups = makeGroups(students: students, options: options)
            let updatedStudents = generateNewStudents(groups: groups, keyPath: \.juraGroups)
            try saveGroupsAndStudents(groups: groups, students: updatedStudents, filename: "jura.json")
        }
    }
    
    struct CreaGroups: ParsableCommand  {
        
        @OptionGroup var options: Options

        func run() throws {
            
            CLILogger.shared.debug = options.debug
            let students = try decodeStudents()
            let highTouchStudents = students.filter({ $0.mineur == Mineur.HighTouch })
            let deepTechStudents = students.filter({ $0.mineur == Mineur.DeepTech })

            let highTouchGroups = makeGroups(students: highTouchStudents, options: options)
            let deepTechGroups = makeGroups(students: deepTechStudents, options: options)
            
            var groups = highTouchGroups
            groups.append(contentsOf: deepTechGroups)
            let updatedStudents = generateNewStudents(groups: groups, keyPath: \.creaGroups)
            try saveGroupsAndStudents(groups: groups, students: updatedStudents, filename: "crea.json")
        }
    }
    
    struct RedressementGroups: ParsableCommand  {
          
          @OptionGroup var options: Options

          func run() throws {
              
              CLILogger.shared.debug = options.debug
              let students = try decodeStudents()
              
              let groups = makeGroups(students: students, options: options)
              let updatedStudents = generateNewStudents(groups: groups, keyPath: \.redressementGroups)
              try saveGroupsAndStudents(groups: groups, students: updatedStudents, filename: "redressement.json")
          }
    }
    
    struct ScaleUpGroups: ParsableCommand  {
          
          @OptionGroup var options: Options

          func run() throws {
              
              CLILogger.shared.debug = options.debug
              let students = try decodeStudents()
              
              let groups = makeGroups(students: students, options: options)
              try saveGroupsAndStudents(groups: groups, students: students, filename: "scaleUp.json")
          }
    }
}


func makeGroups(students: [HECStudent], options: Options) -> [Array<HECStudent>] {
    let configuration = Configuration(populationSize: options.populationSize,
                                                 mutationProbability: options.mutationProbability,
                                                 maxGenerations: options.maxGeneration,
                                                 parentCount: options.parentCount)
               
    let factors: [Float] = [5.0, 1.0, 1.0, 1.0, 1.0]
    let grouping = Grouping(students: students, factors: factors,
                            groupSize: options.groupSize, configuration: configuration)
    return grouping.run()
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
    let simplifiedGroups = groups.map { $0.map { StudentName(firstName: $0.firstName, LastName: $0.lastName) }}
    let groupsEncoded = try encoder.encode(simplifiedGroups)
    let studentsEncoded = try encoder.encode(students)
    try writeToFile(data: groupsEncoded, path: filename)
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

