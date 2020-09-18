//
//  Metadata.swift
//  D3F-MetadataCollector
//
//  Created by YourMJK on 13.09.20.
//  Copyright © 2020 YourMJK. All rights reserved.
//

import Foundation


extension Metadata {
	struct OrderedCodingKey: CodingKey {
		var stringValue: String
		var intValue: Int?
		
		init(_ key: CodingKey) {
			self.stringValue = Self.prefixedKeyString(keyString: key.stringValue)
			self.intValue = key.intValue
		}
		init?(stringValue: String) {
			self.stringValue = stringValue
		}
		init?(intValue: Int) {
			self.stringValue = "\(intValue)"
			self.intValue = intValue
		}

		static let ordering: [String] = [
			"serie",
			"spezial",
			"kurzgeschichten",
			"die_dr3i",

			"nummer",
			"teile",

			"teilNummer",
			"buchstabe",
			
			"titel",
			"autor",
			"hörspielskriptautor",
			"beschreibung",
			"veröffentlichungsdatum",
			"kapitel",
			"sprecher",
			"links",
		
			"titel",
			"start",
			"end",
		
			"ffmetadata",
			"xld_log",
			"cover",
			"cover_itunes",
			"cover_kosmos"
		]
		static func prefixedKeyString(keyString: String) -> String {
			let number = Self.ordering.firstIndex(of: keyString) ?? 99
			return String(format: "%02d_%@", number, keyString)
		}
	}
}



struct Metadata: Codable {
	var serie: [Folge]
	var spezial: [Höreinheit]?
	var kurzgeschichten: [Höreinheit]?
	var die_dr3i: [Folge]?
}


class Höreinheit: Codable {
	var titel: String?
	var autor: String?
	var hörspielskriptautor: String?
	var beschreibung: String?
	var veröffentlichungsdatum: String?
	var kapitel: [Kapitel]?
	var sprecher: [[String]]?
	var links: Links?
}


class Folge: Höreinheit {
	let nummer: UInt
	var teile: [Teil]?
	
	init(nummer: UInt) {
		self.nummer = nummer
		super.init()
	}
	
	
	// Codable
	enum CodingKeys: CodingKey {
		case nummer
		case teile
	}
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		nummer = try container.decode(UInt.self, forKey: .nummer)
		teile = try container.decodeIfPresent([Teil].self, forKey: .teile)
		try super.init(from: decoder)
	}
	override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(nummer, forKey: .nummer)
		try container.encodeIfPresent(teile, forKey: .teile)
		try super.encode(to: encoder)
	}
}


class Teil: Höreinheit {
	let teilNummer: UInt
	var buchstabe: String?
	
	init(teilNummer: UInt) {
		self.teilNummer = teilNummer
		super.init()
	}
	
	
	// Codable
	enum CodingKeys: CodingKey {
		case teilNummer
		case buchstabe
	}
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		teilNummer = try container.decode(UInt.self, forKey: .teilNummer)
		buchstabe = try container.decodeIfPresent(String.self, forKey: .buchstabe)
		try super.init(from: decoder)
	}
	override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(teilNummer, forKey: .teilNummer)
		try container.encodeIfPresent(buchstabe, forKey: .buchstabe)
		try super.encode(to: encoder)
	}
}



class Kapitel: Codable, Equatable {
	let titel: String
	var start: Int?
	var end: Int?
	
	init(titel: String) {
		self.titel = titel
	}
	
	static func == (lhs: Kapitel, rhs: Kapitel) -> Bool {
		return lhs.titel == rhs.titel && lhs.start == rhs.start && lhs.end == rhs.end 
	}
}


class Links: Codable {
	var json: String?
	var ffmetadata: String?
	var xld_log: String?
	var cover: String?
	var cover_itunes: String?
	var cover_kosmos: String?
}

