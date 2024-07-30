//
//  Command.WebBuild.swift
//  dreimetadaten
//
//  Created by YourMJK on 09.04.24.
//

import Foundation
import CommandLineTool
import ArgumentParser
import GRDB


extension Command {
	struct WebBuild: ParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "webbuild",
			abstract: "Generate HTML code for the web page using a template file.",
			alwaysCompactUsageOptions: true
		)
		
		struct IOOptions: ParsableArguments {
			private static let argumentHelpAutomaticDefault = "(default: automatic based on <collection type>)"
			
			@Option(name: .customLong("template"), help: ArgumentHelp("The path to the template HTML input file to use for filling in the placeholders. \(argumentHelpAutomaticDefault)", valueName: "html file"))
			var templateFilePath: String?
			
			@Option(name: .customLong("output"), help: ArgumentHelp("The path to the HTML output file. \(argumentHelpAutomaticDefault)", valueName: "html file"))
			var outputFilePath: String?
		}
		
		@Argument(help: ArgumentHelp("The collection type to generate the HTML code for.", valueName: "collection type"))
		var collectionTypeArgument: CollectionTypeArgument
		
		@Option(name: .customLong("db"), help: ArgumentHelp("The path to the SQLite database file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		@Option(name: .customLong("webDataURL"), help: ArgumentHelp("The URL pointing to the web data directory. Used as the base URL for generated metadata links.", valueName: "URL"))
		var webDataURLString: String = Command.webDataURL.absoluteString
		
		@OptionGroup(title: "IO Options")
		var ioOptions: IOOptions
		
		func run() throws {
			guard let webDataURL = URL(string: webDataURLString) else {
				throw IOError.invalidURL(string: webDataURLString)
			}
			
			let dbQueue = try DatabaseQueue(path: databaseFilePath)
			try dbQueue.read { db in
				let objectModel = try MetadataObjectModel(fromDatabase: db, withBaseURL: webDataURL)
				
				for collectionType in collectionTypeArgument.collectionType {
					func automaticDefault(_ optionKeyPath: KeyPath<IOOptions, String?>, defaultIn defaultDir: URL) throws -> URL {
						let path = ioOptions[keyPath: optionKeyPath]
						let defaultFile = collectionType.htmlFile
						let url = path.map { URL(fileURLWithPath: $0, isDirectory: false) } ?? defaultDir.appendingPathComponent(defaultFile, isDirectory: false)
						
						var directory: ObjCBool = false
						guard FileManager.default.fileExists(atPath: url.path, isDirectory: &directory), !directory.boolValue else {
							throw IOError.noSuchFile(url: url)
						}
						return url
					}
					let templateFileURL = try automaticDefault(\.templateFilePath, defaultIn: Command.webTemplatesDir)
					let outputFileURL = try automaticDefault(\.outputFilePath, defaultIn: Command.webDir)
					
					let templateContent: String
					do {
						templateContent = try String(contentsOf: templateFileURL, encoding: .utf8)
					}
					catch {
						throw IOError.fileReadingFailed(url: templateFileURL, error: error)
					}
					
					let webBuilder = WebBuilder(
						objectModel: objectModel,
						collectionType: collectionType,
						templateContent: templateContent,
						host: webDataURL.host!
					)
					try webBuilder.build()
					
					do {
						try webBuilder.content.write(to: outputFileURL, atomically: false, encoding: .utf8)
					}
					catch {
						throw IOError.fileWritingFailed(url: outputFileURL, error: error)
					}
				}
			}
		}
	}
}


extension Command.WebBuild {
	enum CollectionTypeArgument: String, ArgumentEnum {
		case serie
		case spezial
		case kurzgeschichten
		case die_dr3i
		case all
		
		var collectionType: [CollectionType] {
			switch self {
				case .serie: return [.serie]
				case .spezial: return [.spezial]
				case .kurzgeschichten: return [.kurzgeschichten]
				case .die_dr3i: return [.die_dr3i]
				case .all: return CollectionType.allCases
			}
		}
	}
	
	enum IOError: LocalizedError {
		case noSuchFile(url: URL)
		case fileReadingFailed(url: URL, error: Error)
		case fileWritingFailed(url: URL, error: Error)
		case invalidURL(string: String)
		
		var errorDescription: String? {
			switch self {
				case .noSuchFile(let url):
					return "No such file \"\(url.relativePath)\""
				case .fileReadingFailed(let url, let error):
					return "Couldn't read file \"\(url.relativePath)\": \(error.localizedDescription)"
				case .fileWritingFailed(let url, let error):
					return "Couldn't write to file \"\(url.relativePath)\": \(error.localizedDescription)"
				case .invalidURL(let string):
					return "Invalid URL \"\(string)\""
			}
		}
	}
}
