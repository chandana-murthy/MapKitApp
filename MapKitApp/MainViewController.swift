//
//  ViewController.swift
//  MapKitApp
//
//  Created by Chandana Murthy on 11.08.23.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var currentLocButton: UIButton!

    private let locationManager = CLLocationManager()
    private var routeData: Route?
    private var routeCoordinates: [CLLocation] = []
    private let ANNOTATION_ID = "customAnn"
    private var routeOverlay: MKOverlay?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.overrideUserInterfaceStyle = .dark
        mapView.delegate = self
        locationManager.delegate = self
        currentLocButton.layer.cornerRadius = currentLocButton.frame.width / 2
        setupMapData()
    }

    private func setupMapData() {
        if let routeJson = getJson() {
            parseJson(jsonData: routeJson)
            addPins()
        }
    }

    private func getJson() -> Data? {
        if let path = Bundle.main.path(forResource: "mapData", ofType: "json") {
            do {
                let data = try String(contentsOfFile: path).data(using: .utf8)
                print("success, read")
                return data
            } catch {
                print("\(#function) error")
            }
        }
        return nil
    }

    private func parseJson(jsonData: Data) {
        do {
            routeData = try JSONDecoder().decode(Route.self, from: jsonData)
            for feature in routeData?.features ?? [] {
                if let lat = feature.geometry.coordinates.last, let long = feature.geometry.coordinates.first {
                    let location = CLLocation(latitude: lat, longitude: long)
                    routeCoordinates.append(location)
                }
            }
        } catch {
            print("\(#function) error")
        }
    }

    private func addPins() {
        if routeCoordinates.isEmpty {
            return
        }
        let startPin = MKPointAnnotation()
        startPin.title = "Start"
        guard let startLat = routeCoordinates.first?.coordinate.latitude, let endLat = routeCoordinates.first?.coordinate.longitude else {
            return
        }
        startPin.coordinate = CLLocationCoordinate2D(latitude: startLat, longitude: endLat)
        mapView.addAnnotation(startPin)

        let endPin = MKPointAnnotation()
        endPin.title = "End"
        guard let startLat = routeCoordinates.last?.coordinate.latitude, let endLat = routeCoordinates.last?.coordinate.longitude else {
            return
        }
        endPin.coordinate = CLLocationCoordinate2D(latitude: startLat, longitude: endLat)
        mapView.addAnnotation(endPin)

        drawARoute(data: routeCoordinates)
    }

    private func drawARoute(data: [CLLocation]) {
        if routeCoordinates.isEmpty {
            print("No coordinates")
            return
        }
        let coordinates = data.map { location -> CLLocationCoordinate2D in
            return location.coordinate
        }
        DispatchQueue.main.async {
            self.routeOverlay = MKPolyline(coordinates: coordinates, count: coordinates.count)
            guard let routeOverlay = self.routeOverlay else {
                return
            }
            self.mapView.addOverlay(routeOverlay, level: .aboveRoads)
            let customEdgePadding = UIEdgeInsets(top: 56, left: 56, bottom: 56, right: 56)
            self.mapView.setVisibleMapRect(routeOverlay.boundingMapRect, edgePadding: customEdgePadding, animated: true)
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    @IBAction func didTapCurrentLocationButton(_ sender: Any) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
            var mapRegion = MKCoordinateRegion()
            mapRegion.center = location.coordinate
            mapRegion.span.longitudeDelta = 0.2
            mapRegion.span.latitudeDelta = 0.2
            let currentLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            let annotation = MKPointAnnotation()
        annotation.title = "You are here"
            annotation.coordinate = location.coordinate
            mapView.addAnnotation(annotation)
            mapView.setRegion(mapRegion, animated: true)

            locationManager.stopUpdatingLocation()
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: ANNOTATION_ID) as? MKMarkerAnnotationView
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: ANNOTATION_ID)
        } else {
            annotationView?.annotation = annotation
        }

        switch annotation.title {
        case "Start":
            annotationView?.markerTintColor = .red
            annotationView?.canShowCallout = true
        case "End":
            annotationView?.markerTintColor = .green
        case "You are here":
            annotationView?.markerTintColor = .systemBlue
        default:
            break
        }

        return annotationView
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKGradientPolylineRenderer(overlay: overlay)
        renderer.setColors([.red, .yellow, .green], locations: [])
        renderer.lineCap = .round
        renderer.lineWidth = 3

        return renderer
    }
}
