//
//  Files.swift
//  Wallace
//
//  Created by Henry Huck on 22/08/2020.
//

import Foundation
import WallaceCore

/**
 Parse the original student file. Here vector components are encoded in single columns and must be split into actual vectors.
 Example: the origin of the student is encoded in a single column with 3 values, afterwards it will be encoded in 3 distinct properties.
 */
func parseStudentFile(data: String) -> Array<HECStudent> {
    let rows = data.components(separatedBy: .newlines).filter({ $0 != "" })
    return rows.enumerated().map { (index, row) -> HECStudent in
        return HECStudent(id: UInt8(index), row: row.components(separatedBy: ";"))
    }
}

func writeToFile(data: Data, path: String) throws {
    let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    let url = currentDirectory.appendingPathComponent(path)
    try data.write(to: url)
}

/**
  Encode students to an intermediary file save.
 */
func encodeStudents(students: [HECStudent]) throws {
    let encoder = JSONEncoder()
    let studentsEncoded = try encoder.encode(students)
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

/**
   Save  the generated groups into a txt file. Each line represents a groupa and contain the short description of each student in the group.
*/
func exportGroups(groups: [Array<HECStudent>], filename: String) throws {
    let simplifiedGroups = groups.map { $0.map { $0.shortDescription }}
    let simpfliedGroupsString = simplifiedGroups.reduce("", { (stringData, group) -> String in
        var newData = stringData
        newData.append(contentsOf: group.joined(separator: ", "))
        newData.append("\n")
        return newData
    })
    try writeToFile(data: simpfliedGroupsString.data(using: .utf8)!, path: filename)
}

/**
 Export the students into a CSV file, using their description.
 */
func exportStudents(students: [HECStudent]) throws {
    let export = students.reduce(HECStudent.csvTitle) { (aggregated, student) -> String in
        return "\(aggregated)\(student.description)\n"
    }
    try writeToFile(data: Data(export.utf8), path: "export.csv")
}

/*
 Given a rotation, export a single file to `fileName` with a text giving the list of students for each day
 */
func exportRotation(fileName: String, rotation: Rotation, groups: Array<[HECStudent]>) throws {
    let rotationString = rotation.enumerated().reduce("", { (stringData, enumerated) -> String in
        let (index, groupsofGroups) = enumerated
        let result = stringData.appending("Groupe de marche \(index + 1) \n")
        let students = groupsofGroups.reduce("") { (students, groupId) -> String in
            let group = groups[groupId]
            return students + "Groupe \(groupId + HECStudent.groupOffset): " + group.map({ $0.shortDescription}).joined(separator: ", ") + "\n"
        }
        return result.appending(students).appending("\n \n")
    })
    try writeToFile(data: rotationString.data(using: .utf8)!, path: fileName)
}
