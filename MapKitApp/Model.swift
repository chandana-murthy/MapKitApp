//
//  Model.swift
//  MapKitApp
//
//  Created by Chandana Murthy on 11.08.23.
//

import Foundation

struct Route: Codable {
    let features: [Feature]
}

struct Properties: Codable {
    let trackFid: Int
    let trackSegId: Int
    let trackSegPointId: Int
    let ele: Int

    private enum CodingKeys: String, CodingKey {
        case trackFid = "track_fid"
        case trackSegId = "track_seg_id"
        case trackSegPointId = "track_seg_point_id"
        case ele
    }
}

struct Geometry: Codable {
    let type: String
    let coordinates: [Double]
}

struct Feature: Codable {
    let type: String
    let properties: Properties
    let geometry: Geometry
}
