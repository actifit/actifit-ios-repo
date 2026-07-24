//
//  Route.swift
//  Actifit
//
//  GPS route recording model — port of Android RouteModel + WaypointModel +
//  the ActivityRoutes table. Waypoint JSON keys match Android exactly so stored
//  routes stay cross-readable.
//

import Foundation
import RealmSwift

/// Matches Android WaypointModel Gson shape: lat, lng, altitudeMeters, timestampMs, accuracy, speedMps.
struct RouteWaypoint: Codable {
    let lat: Double
    let lng: Double
    let altitudeMeters: Double
    let timestampMs: Int
    let accuracy: Double
    let speedMps: Double
}

class Route: Object {
    @objc dynamic var routeId: Int = 0
    @objc dynamic var date: Int = 0                 // yyyyMMdd (from START time)
    @objc dynamic var activityType: String = ""
    @objc dynamic var sourceType: String = "GPS"
    @objc dynamic var startTimeMs: Int = 0
    @objc dynamic var endTimeMs: Int = 0
    @objc dynamic var distanceMeters: Double = 0
    @objc dynamic var elevationGainMeters: Double = 0
    @objc dynamic var waypointsJson: String = ""

    override static func primaryKey() -> String? { return "routeId" }

    // MARK: - Formatting (ported 1:1 from Android RouteModel)

    var durationMs: Int { endTimeMs <= startTimeMs ? 0 : endTimeMs - startTimeMs }

    var formattedDistance: String {
        if distanceMeters < 1000 { return String(format: "%.0f m", distanceMeters) }
        return String(format: "%.2f km", distanceMeters / 1000.0)
    }

    var formattedDuration: String {
        let ms = durationMs
        let hours = ms / 3_600_000
        let minutes = (ms / 60_000) % 60
        let seconds = (ms / 1000) % 60
        if hours > 0 { return String(format: "%d:%02d:%02d", hours, minutes, seconds) }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// avg pace as min/km, "--" if no movement.
    var formattedPace: String {
        let durationSec = durationMs / 1000
        let distKm = distanceMeters / 1000.0
        if distKm < 0.01 || durationSec == 0 { return "--" }
        let secPerKm = Double(durationSec) / distKm
        let paceMin = Int(secPerKm) / 60
        let paceSec = Int(secPerKm) % 60
        return String(format: "%d:%02d/km", paceMin, paceSec)
    }

    var waypoints: [RouteWaypoint] {
        guard let data = waypointsJson.data(using: .utf8),
              let list = try? JSONDecoder().decode([RouteWaypoint].self, from: data) else { return [] }
        return list
    }

    // MARK: - Realm access (mirrors StepsDBHelper queries: order by startTime DESC)

    static func mostRecent() -> Route? {
        guard let realm = AppDelegate.defaultRealm() else { return nil }
        return realm.objects(Route.self).sorted(byKeyPath: "startTimeMs", ascending: false).first
    }

    static func forDate(_ date: Int) -> Route? {
        guard let realm = AppDelegate.defaultRealm() else { return nil }
        return realm.objects(Route.self).filter("date == %@", date).sorted(byKeyPath: "startTimeMs", ascending: false).first
    }

    static func nextRouteId() -> Int {
        guard let realm = AppDelegate.defaultRealm() else { return 1 }
        let maxId = (realm.objects(Route.self).max(ofProperty: "routeId") as Int?) ?? 0
        return maxId + 1
    }

    func save() {
        guard let realm = AppDelegate.defaultRealm() else { return }
        try? realm.write { realm.add(self, update: .modified) }
    }
}
