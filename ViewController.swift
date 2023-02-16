/* ************************************************************************** */
/*                                                                            */
/*                                                        ::::::::            */
/*   ViewController.swift                               :+:    :+:            */
/*                                                     +:+                    */
/*   By: quentinbeukelman <quentinbeukelman@stud      +#+                     */
/*                                                   +#+                      */
/*   Created: 2022/12/05 10:23:30 by quentinbeuk   #+#    #+#                 */
/*   Updated: 2022/12/08 15:50:04 by quentinbeuk   ########   odam.nl         */
/*                                                                            */
/* ************************************************************************** */

import Foundation
import UIKit
import TomTomSDKMapDisplay
import EventKit
import EventKitUI

class ViewController: UIViewController, MapViewDelegate {
    
    var mapView = MapView()
    let textBox = UITextView()
    let htmlResonse: String = ""
    let eventStore = EKEventStore()
    var addedEvents: [EKEvent] = []
    var eventLocation: String = ""
    var urlString: String = ""
    
    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        addMap()
        canalderRequest()
    }
    
    
    // MARK: Calendar
    func canalderRequest() -> Void {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        
        switch (status) {
        case .notDetermined:
            requestAccessToCalendar()
        case .authorized:
            self.fetchEventsFromCalendar(calendarTitle: "Calendar")
            break
        case .restricted, .denied: break
        }
    }
    
    // Request access to calander
    func requestAccessToCalendar() {
        eventStore.requestAccess(to: EKEntityType.event) { (accessGranted, error) in
            self.fetchEventsFromCalendar(calendarTitle: "Codam Event")
        }
    }
    var events: [EKEvent] = []
    func fetchEventsFromCalendar(calendarTitle: String) -> Void {
        
        let calendars = eventStore.calendars(for: .event)
        var i: Int = 0
        
        //PGAEventsCalendar
        for calendar:EKCalendar in calendars {
            let selectedCalendar = calendar
            let startDate = NSDate(timeIntervalSinceNow: -60*60*24*180)
            let endDate = NSDate(timeIntervalSinceNow: 60*60*24*180)
            let predicate = eventStore.predicateForEvents(withStart: startDate as Date, end: endDate as Date, calendars: [selectedCalendar])
            let events = eventStore.events(matching: predicate)
            addedEvents.append(contentsOf: events)
            
        }
    }
    
    
    // MARK: - addMap
    func addMap() {
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: mapView.leftAnchor),
            view.rightAnchor.constraint(equalTo: mapView.rightAnchor),
            view.topAnchor.constraint(equalTo: mapView.topAnchor),
            view.bottomAnchor.constraint(equalTo: mapView.bottomAnchor),
        ])
    }
    
        
    // MARK: - getGeo
    func getGeo(eventLocation: String, map: TomTomSDKMapDisplay.Map, iconImage: String) {
        var apiKey: String = "hSuSOhDGls2lMN9UmGJQtZuVO50yD3Pi"
        var baseURL: String = "api.tomtom.com"
        var versionNumber: String = "2"
        var exitValue: String = "json"
        
        // The url to make the request as URL
        let urlString = "https://\(baseURL)/search/\(versionNumber)/geocode/\(eventLocation).\(exitValue)?key=\(apiKey)"
        
        if var urlComponents = URLComponents(string: urlString) {
            
            if let url = urlComponents.url {
                // Create a URLSession
                let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                    guard let data = data else { return }
                    
                    let responseObj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

                    // Filter json response
                    if let results = responseObj?["results"] as? [[String: Any]] {
                        for result in results {
                            if let coordinates = result["position"] as? [String: Double] {
                                print(coordinates["lon"]!)
                                print(coordinates["lat"]!)
                                
                                let lon = coordinates["lon"]!
                                let lat = coordinates["lat"]!

                                let currentEventLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                var markerOptions = MarkerOptions(coordinate: currentEventLocation)
                                markerOptions.pinImage = UIImage(named: iconImage)
                                let marker = try? map.addMarker(options: markerOptions)
                            }
                        }
                    }
                }
                task.resume()
            }
       }
    }
    
    
    // MARK: - Map Deligate
    func mapView(_: MapView, onMapReady map: TomTomSDKMapDisplay.Map) {
        var iconImage = ""
        
        for event in addedEvents {
            if (event.calendar.title == "TomTom")
            {
                iconImage = "markerBackground"
                getGeo(eventLocation: event.location!, map: map, iconImage: iconImage)
            }
            if (event.calendar.title == "TomTom Sport") {
                iconImage = "markerBackgroundSport"
                getGeo(eventLocation: event.location!, map: map, iconImage: iconImage)
            }
        }
        map.setMarkerDistanceFadingRange(range: .init(uncheckedBounds: (lower: 200, upper: 500)))
        map.setMarkerDistanceShrinkingRange(range: .init(uncheckedBounds: (lower: 200, upper: 500)))
        map.isMarkersFadingEnabled = true
        map.isMarkersShrinkingEnabled = true
    }
    
    func mapView(_ mapView: MapView, onStyleLoad result: Result<StyleContainer, Error>) {
        // Based on `result` you can find out if default or style that you are trying to load succeed or failed.
        // Update Camera Position
        let amsterdam = CLLocationCoordinate2D(latitude: 52.3764527, longitude: 4.9062047)
        let cameraUpdate = CameraUpdate(
            position: amsterdam,
            zoom: 10.0,
            tilt: 45,
            rotation: 0,
            positionMarkerVerticalOffset: nil
        )
        let mapOptions = MapOptions(
            mapKey: "hSuSOhDGls2lMN9UmGJQtZuVO50yD3Pi",
            cameraUpdate: cameraUpdate,
            styleMode: .dark
        )
        self.mapView = MapView(mapOptions: mapOptions)
    }

} // End class
