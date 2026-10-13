import Foundation

enum TrackGeometry {
    struct Point {
        let x: Double
        let y: Double
        let breakBefore: Bool
    }

    static func normalized(_ positions: [FileSummary.Coordinate]) -> [Point] {
        guard positions.count > 1 else { return [] }
        let latitudeMean = positions.map(\.latitude).reduce(0, +) / Double(positions.count)
        let longitudeFactor = max(0.05, abs(cos(latitudeMean * .pi / 180)))
        var longitudes: [Double] = []
        longitudes.reserveCapacity(positions.count)
        for position in positions {
            var longitude = position.longitude
            if let previous = longitudes.last {
                while longitude - previous > 180 { longitude -= 360 }
                while longitude - previous < -180 { longitude += 360 }
            }
            longitudes.append(longitude * longitudeFactor)
        }
        let xMin = longitudes.min() ?? 0
        let xMax = longitudes.max() ?? 0
        let yMin = positions.map(\.latitude).min() ?? 0
        let yMax = positions.map(\.latitude).max() ?? 0
        let xRange = max(xMax - xMin, 0.000001)
        let yRange = max(yMax - yMin, 0.000001)
        let span = max(xRange, yRange)
        return zip(longitudes, positions).map { longitude, position in
            Point(x: 0.06 + 0.88 * ((longitude - xMin) / span + (span - xRange) / (2 * span)),
                  y: 0.06 + 0.88 * (1 - ((position.latitude - yMin) / span + (span - yRange) / (2 * span))),
                  breakBefore: position.breakBefore)
        }
    }
}
