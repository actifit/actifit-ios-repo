//
//  RouteRecordingManager.swift
//  Actifit
//
//  iOS port of Android RouteRecordingService — CoreLocation recording with
//  pairwise CLLocation.distance accumulation, wall-clock duration, and
//  save-on-stop into the Realm Route model. Broadcasts via NotificationCenter
//  (the Android LocalBroadcastManager equivalent).
//

import Foundation
import CoreLocation

final class RouteRecordingManager: NSObject, CLLocationManagerDelegate {

    static let shared = RouteRecordingManager()
    static var isRunning = false

    static let waypointUpdate = Notification.Name("RouteWaypointUpdate")
    static let recordingStopped = Notification.Name("RouteRecordingStopped")

    private let locationManager = CLLocationManager()
    private(set) var activityType = "Walking"
    private var startTimeMs = 0
    private var waypoints: [RouteWaypoint] = []
    private var totalDistance: Double = 0
    private var lastLocation: CLLocation?
    private var authContinuation: (() -> Void)?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone   // parity: no min-distance gate
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    var authorizationStatus: CLAuthorizationStatus { locationManager.authorizationStatus }

    /// Requests When-In-Use auth; `granted` runs when access is (already/newly) authorized.
    func requestAuthorization(_ granted: @escaping () -> Void) {
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            granted()
        } else if status == .notDetermined {
            authContinuation = granted
            locationManager.requestWhenInUseAuthorization()
        }
        // denied/restricted -> caller shows a message
    }

    func start(activityType: String) {
        self.activityType = activityType
        startTimeMs = Self.nowMs()
        waypoints = []
        totalDistance = 0
        lastLocation = nil
        RouteRecordingManager.isRunning = true
        // Background updates require the "location" UIBackgroundMode (added to Info.plist).
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        RouteRecordingManager.isRunning = false
        let endTimeMs = Self.nowMs()

        let json = (try? JSONEncoder().encode(waypoints)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX"); df.dateFormat = "yyyyMMdd"
        let dateInt = Int(df.string(from: Date(timeIntervalSince1970: Double(startTimeMs) / 1000.0))) ?? 0

        let route = Route()
        route.routeId = Route.nextRouteId()
        route.date = dateInt
        route.activityType = activityType
        route.sourceType = "GPS"
        route.startTimeMs = startTimeMs
        route.endTimeMs = endTimeMs
        route.distanceMeters = totalDistance
        route.waypointsJson = json
        route.save()

        NotificationCenter.default.post(name: RouteRecordingManager.recordingStopped, object: nil, userInfo: [
            "routeId": route.routeId,
            "distance": totalDistance,
            "durationMs": endTimeMs - startTimeMs,
            "date": dateInt
        ])
    }

    private static func nowMs() -> Int { Int(Date().timeIntervalSince1970 * 1000) }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            authContinuation?()
            authContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let wp = RouteWaypoint(
                lat: location.coordinate.latitude,
                lng: location.coordinate.longitude,
                altitudeMeters: location.verticalAccuracy >= 0 ? location.altitude : 0,
                timestampMs: Int(location.timestamp.timeIntervalSince1970 * 1000),
                accuracy: location.horizontalAccuracy,
                speedMps: max(0, location.speed))
            waypoints.append(wp)
            if let last = lastLocation { totalDistance += location.distance(from: last) }
            lastLocation = location
            let durationMs = Self.nowMs() - startTimeMs
            NotificationCenter.default.post(name: RouteRecordingManager.waypointUpdate, object: nil, userInfo: [
                "lat": location.coordinate.latitude,
                "lng": location.coordinate.longitude,
                "distance": totalDistance,
                "durationMs": durationMs
            ])
        }
    }
}
