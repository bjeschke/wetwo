//
//  RelationshipStatus.swift
//  WeTwo
//
//  Created by Benjamin Jeschke on 04.08.25.
//

import Foundation

enum RelationshipStatus: String, CaseIterable, Codable {
    case single = "single"
    case inRelationship = "in_relationship"
    case engaged = "engaged"
    case married = "married"
    case complicated = "complicated"
    
    var localizedName: String {
        switch self {
        case .single:
            return NSLocalizedString("relationship_status_single", comment: "Single")
        case .inRelationship:
            return NSLocalizedString("relationship_status_in_relationship", comment: "In a relationship")
        case .engaged:
            return NSLocalizedString("relationship_status_engaged", comment: "Engaged")
        case .married:
            return NSLocalizedString("relationship_status_married", comment: "Married")
        case .complicated:
            return NSLocalizedString("relationship_status_complicated", comment: "It's complicated")
        }
    }
    
    var emoji: String {
        switch self {
        case .single:
            return "💔"
        case .inRelationship:
            return "💕"
        case .engaged:
            return "💍"
        case .married:
            return "👰"
        case .complicated:
            return "🤷‍♀️"
        }
    }
}
