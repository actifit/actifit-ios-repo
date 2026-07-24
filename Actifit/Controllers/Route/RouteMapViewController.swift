//
//  RouteMapViewController.swift
//  Actifit
//
//  iOS port of Android RouteMapActivity — MapKit map with LIVE recording
//  (growing polyline + live distance/timer/pace, driven by RouteRecordingManager
//  broadcasts) and VIEW replay of a saved route (polyline + fit-to-bounds).
//

import UIKit
import MapKit
import SafariServices

final class RouteMapViewController: UIViewController, MKMapViewDelegate {

    enum Mode { case live, view }

    private var mode: Mode = .view
    private var activityType = "Recording"
    private var viewDate: Int = 0

    private let mapView = MKMapView()
    private var routeCoords: [CLLocationCoordinate2D] = []
    private var polyline: MKPolyline?
    private let currentMarker = MKPointAnnotation()

    private let activityLabel = UILabel()
    private let distanceLabel = UILabel()
    private let durationLabel = UILabel()
    private let paceLabel = UILabel()
    private let stopButton = UIButton(type: .system)
    private var liveTimer: Timer?
    private var liveStartMs = 0

    private var brandRed: UIColor { UIColor(named: "primaryRed") ?? UIColor(red: 1, green: 0.067, blue: 0.176, alpha: 1) }

    static func create(mode: Mode, activityType: String = "Recording", date: Int = 0) -> RouteMapViewController {
        let vc = RouteMapViewController()
        vc.mode = mode
        vc.activityType = activityType
        vc.viewDate = date
        vc.modalPresentationStyle = .fullScreen
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupMap()
        setupStatsBar()
        setupCloseButton()
        if mode == .live { setupLive() } else { setupView() }
    }

    private func setupMap() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupCloseButton() {
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        close.tintColor = brandRed
        close.backgroundColor = .white
        close.layer.cornerRadius = 20
        close.translatesAutoresizingMaskIntoConstraints = false
        close.widthAnchor.constraint(equalToConstant: 40).isActive = true
        close.heightAnchor.constraint(equalToConstant: 40).isActive = true
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(close)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }

    private func setupStatsBar() {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowRadius = 6
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.translatesAutoresizingMaskIntoConstraints = false

        activityLabel.font = .systemFont(ofSize: 15, weight: .bold)
        activityLabel.textColor = brandRed
        activityLabel.textAlignment = .center

        func statColumn(_ title: String, _ value: UILabel) -> UIView {
            value.font = .systemFont(ofSize: 20, weight: .bold)
            value.textColor = UIColor(white: 0.13, alpha: 1)
            value.textAlignment = .center
            value.text = "--"
            let t = UILabel(); t.text = title; t.font = .systemFont(ofSize: 11); t.textColor = .gray; t.textAlignment = .center
            let col = UIStackView(arrangedSubviews: [value, t]); col.axis = .vertical; col.spacing = 2
            return col
        }
        let statsRow = UIStackView(arrangedSubviews: [
            statColumn("Distance", distanceLabel),
            statColumn("Time", durationLabel),
            statColumn("Pace", paceLabel)
        ])
        statsRow.axis = .horizontal
        statsRow.distribution = .fillEqually

        stopButton.setTitle("Stop & Save", for: .normal)
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        stopButton.backgroundColor = brandRed
        stopButton.layer.cornerRadius = 12
        stopButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        stopButton.isHidden = true
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [activityLabel, statsRow, stopButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        view.addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    // MARK: - LIVE mode

    private func setupLive() {
        activityLabel.text = activityType
        stopButton.isHidden = false
        currentMarker.title = "You"
        liveStartMs = Int(Date().timeIntervalSince1970 * 1000)
        NotificationCenter.default.addObserver(self, selector: #selector(onWaypoint(_:)), name: RouteRecordingManager.waypointUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onStopped(_:)), name: RouteRecordingManager.recordingStopped, object: nil)
        liveTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tickTimer() }
    }

    private func tickTimer() {
        let ms = Int(Date().timeIntervalSince1970 * 1000) - liveStartMs
        let h = ms / 3_600_000, m = (ms / 60_000) % 60, s = (ms / 1000) % 60
        durationLabel.text = h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    @objc private func onWaypoint(_ note: Notification) {
        guard let info = note.userInfo,
              let lat = info["lat"] as? Double, let lng = info["lng"] as? Double else { return }
        addPoint(lat: lat, lng: lng)
        let distance = info["distance"] as? Double ?? 0
        distanceLabel.text = String(format: "%.2f km", distance / 1000.0)
        if distance > 50, let durationMs = info["durationMs"] as? Int, durationMs > 0 {
            let secPerKm = (Double(durationMs) / 1000.0) / (distance / 1000.0)
            paceLabel.text = String(format: "%d:%02d/km", Int(secPerKm) / 60, Int(secPerKm) % 60)
        }
    }

    @objc private func onStopped(_ note: Notification) {
        let date = note.userInfo?["date"] as? Int ?? viewDate
        liveTimer?.invalidate(); liveTimer = nil
        NotificationCenter.default.removeObserver(self)
        // Re-open the just-saved route in VIEW mode in place.
        mode = .view
        viewDate = date
        stopButton.isHidden = true
        currentMarker.coordinate = kCLLocationCoordinate2DInvalid
        mapView.removeAnnotation(currentMarker)
        setupView()
    }

    private func addPoint(lat: Double, lng: Double) {
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        routeCoords.append(coord)
        redrawPolyline()
        currentMarker.coordinate = coord
        if !mapView.annotations.contains(where: { $0 === currentMarker }) { mapView.addAnnotation(currentMarker) }
        mapView.setCenter(coord, animated: true)
    }

    // MARK: - VIEW mode

    private func setupView() {
        guard let route = Route.forDate(viewDate) else {
            activityLabel.text = "Route not found"
            return
        }
        activityLabel.text = (route.activityType.isEmpty ? "Activity" : route.activityType) + "  •  GPS"
        distanceLabel.text = route.formattedDistance
        durationLabel.text = route.formattedDuration
        paceLabel.text = route.formattedPace
        routeCoords = route.waypoints.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
        redrawPolyline()
        fitToRoute()
    }

    // MARK: - Shared

    private func redrawPolyline() {
        if let existing = polyline { mapView.remove(existing) }
        guard routeCoords.count >= 2 else { return }
        let line = MKPolyline(coordinates: routeCoords, count: routeCoords.count)
        mapView.add(line)
        polyline = line
    }

    private func fitToRoute() {
        guard !routeCoords.isEmpty else { return }
        if routeCoords.count < 2 {
            mapView.setRegion(MKCoordinateRegionMakeWithDistance(routeCoords[0], 400, 400), animated: true)
        } else if let line = polyline {
            mapView.setVisibleMapRect(line.boundingMapRect, edgePadding: UIEdgeInsets(top: 80, left: 60, bottom: 200, right: 60), animated: true)
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let line = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
        let renderer = MKPolylineRenderer(polyline: line)
        renderer.strokeColor = brandRed
        renderer.lineWidth = 6
        renderer.lineJoin = .round
        renderer.lineCap = .round
        return renderer
    }

    // MARK: - Actions

    @objc private func stopTapped() {
        let alert = UIAlertController(title: "Stop Recording?", message: "Save this route?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Keep Going", style: .cancel))
        alert.addAction(UIAlertAction(title: "Stop & Save", style: .default) { _ in
            RouteRecordingManager.shared.stop()
        })
        present(alert, animated: true)
    }

    @objc private func closeTapped() { dismiss(animated: true) }

    deinit { NotificationCenter.default.removeObserver(self); liveTimer?.invalidate() }
}
