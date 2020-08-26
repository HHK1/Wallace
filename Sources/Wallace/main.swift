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
                                                    subcommands: [JuraGroups.self, CreaGroups.self, RedressementGroups.self, ScaleUpGroups.self, ExportStudents.self])

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
    
    struct ScaleUpGroups: ParsableCommand  {
          
          @OptionGroup var options: Options

          func run() throws {
              
              CLILogger.shared.debug = options.debug
              let students = try decodeStudents()
              
              let groups = makeGroups(students: students, options: options)
              let updatedStudents = generateNewStudents(groups: groups, keyPath: \.scaleUpGroups)
              try saveGroupsAndStudents(groups: groups, students: updatedStudents, filename: "scaleUp.json")
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
    
    struct ExportStudents: ParsableCommand {
        
        typealias Seminaire = Array<Array<String>?>
        
        
        func run() throws {
            
            let students = try decodeStudents()
            let initialValue: Dictionary<String, Seminaire> = [
                "jura": Array(repeating: [], count: students.count),
                "crea": Array(repeating: [], count: students.count),
                "scaleUp": Array(repeating: [], count: students.count),
                "redressement": Array(repeating: [], count: students.count)
            ]
            
            func addStudent(student: HECStudent, path: KeyPath<HECStudent, Vector?>, groupName: String, aggregated: Dictionary<String, Seminaire>) -> Seminaire {
                guard var seminaire = aggregated[groupName] else { return [] }
                guard let index = student[keyPath: path]?.firstIndex(of: 1) else { return seminaire }
                var group = seminaire[index] ?? []
                group.append(student.description)
                seminaire[index] = group
                return seminaire
            }
            
            let allGroups = students.reduce(initialValue) { (aggregated, student) -> Dictionary<String, Seminaire> in
                let jura = addStudent(student: student, path: \.juraGroups, groupName: "jura", aggregated: aggregated)
                let crea = addStudent(student: student, path: \.creaGroups, groupName: "crea", aggregated: aggregated)
                let scaleUp = addStudent(student: student, path: \.scaleUpGroups, groupName: "scaleUp", aggregated: aggregated)
                let redressement = addStudent(student: student, path: \.redressementGroups, groupName: "redressement", aggregated: aggregated)
                return ["jura": jura, "crea": crea, "scaleUp":scaleUp, "redressement": redressement]
            }
            let encoder = JSONEncoder()

            try allGroups.forEach { (key, seminaire) in
                let seminaireData = try encoder.encode(seminaire)
                try writeToFile(data: seminaireData, path: "\(key)_data.json")
            }
        }
    }
}


func makeGroups(students: [HECStudent], options: Options) -> [Array<HECStudent>] {
    let configuration = Configuration(populationSize: options.populationSize,
                                                 mutationProbability: options.mutationProbability,
                                                 maxGenerations: options.maxGeneration,
                                                 parentCount: options.parentCount,
                                                 maxNumberPermutation: options.maxNumberPermutation)
               
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
    let simplifiedGroups = groups.map { $0.map { $0.shortDescription }}
    let simpfliedGroupsString = simplifiedGroups.reduce("", { (stringData, group) -> String in
        var newData = stringData
        newData.append(contentsOf: group.joined(separator: ","))
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

