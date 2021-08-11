//
//  Parser.swift
//  Wallace
//
//  Created by Henry Huck on 22/08/2020.
//

import Foundation

func parseStudentFile(data: String) -> Array<HECStudent> {
    let rows = data.components(separatedBy: .newlines).filter({ $0 != "" })
    return rows.enumerated().map { (index, row) -> HECStudent in
        return HECStudent(id: UInt8(index), row: row.components(separatedBy: ";"), numberOfStudents: rows.count)
    }
}


func writeToFile(data: Data, path: String) throws {
    let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    let url = currentDirectory.appendingPathComponent(path)
    try data.write(to: url)
}
