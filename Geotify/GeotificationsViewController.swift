import UIKit
import MapKit
import CoreLocation

struct PreferencesKeys {
  static let savedItems = "savedItems"
}

class GeotificationsViewController: UIViewController {
    
//    func addGeotificationViewController(controller: AddGeotificationViewController, radius: Double, identifier: String, note: String, eventType: EventType) {

    var collectingPoints = false
    var tempRadius: Double?
    var tempIdentifier: String?
    var tempNote: String?
    var tempEventType: EventType?
  
    var numPoints = 10.0
    
    var latCoordinate = 0.0
    var longCoordinate = 0.0
    var points = [CLLocationCoordinate2D]()
    
    
  @IBOutlet weak var mapView: MKMapView!
  
  var geotifications: [Geotification] = []
  let locationManager = CLLocationManager()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // 1
    locationManager.delegate = self
    // 2
    locationManager.requestAlwaysAuthorization()
    // 3
    
    
    loadAllGeotifications()
//    for geotification in geotifications{
//      remove(geotification: geotification)
//    }
//    saveAllGeotifications()
    
//    for g in geotifications{
//      print(g.coordinate)
//    }
    locationManager.requestLocation()
    locationManager.startUpdatingLocation()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "addGeotification" {
      let navigationController = segue.destination as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddGeotificationViewController
      vc.delegate = self
    }
  }
  
  // MARK: Loading and saving functions
  func loadAllGeotifications() {
    geotifications = []
    guard let savedItems = UserDefaults.standard.array(forKey: PreferencesKeys.savedItems) else { return }
    for savedItem in savedItems {
      guard let geotification = NSKeyedUnarchiver.unarchiveObject(with: savedItem as! Data) as? Geotification else { continue }
      add(geotification: geotification)
    }
  }
  
  func saveAllGeotifications() {
    var items: [Data] = []
    for geotification in geotifications {
      let item = NSKeyedArchiver.archivedData(withRootObject: geotification)
      items.append(item)
    }
    UserDefaults.standard.set(items, forKey: PreferencesKeys.savedItems)
  }
  
  // MARK: Functions that update the model/associated views with geotification changes
  func add(geotification: Geotification) {
    geotifications.append(geotification)
    mapView.addAnnotation(geotification)
    addRadiusOverlay(forGeotification: geotification)
    updateGeotificationsCount()
  }
  
  func remove(geotification: Geotification) {
    if let indexInArray = geotifications.index(of: geotification) {
      geotifications.remove(at: indexInArray)
    }
    mapView.removeAnnotation(geotification)
    removeRadiusOverlay(forGeotification: geotification)
    updateGeotificationsCount()
  }
  
  func updateGeotificationsCount() {
    title = "Locations (\(geotifications.count))"
  }
  
  // MARK: Map overlay functions
  func addRadiusOverlay(forGeotification geotification: Geotification) {
    mapView?.add(MKCircle(center: geotification.coordinate, radius: geotification.radius))
  }
  
  func removeRadiusOverlay(forGeotification geotification: Geotification) {
    // Find exactly one overlay which has the same coordinates & radius to remove
    guard let overlays = mapView?.overlays else { return }
    for overlay in overlays {
      guard let circleOverlay = overlay as? MKCircle else { continue }
      let coord = circleOverlay.coordinate
      if coord.latitude == geotification.coordinate.latitude && coord.longitude == geotification.coordinate.longitude && circleOverlay.radius == geotification.radius {
        mapView?.remove(circleOverlay)
        break
      }
    }
  }
  
  // MARK: Other mapview functions
  @IBAction func zoomToCurrentLocation(sender: AnyObject) {
    mapView.zoomToUserLocation()
  }
  
  func region(withGeotification geotification: Geotification) -> CLCircularRegion {
    // 1
    let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
    // 2
    region.notifyOnEntry = (geotification.eventType == .onEntry)
    region.notifyOnExit = !region.notifyOnEntry
    return region
  }
  
  func startMonitoring(geotification: Geotification) {
    // 1
    if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
      showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
      return
    }
    // 2
    if CLLocationManager.authorizationStatus() != .authorizedAlways {
      showAlert(withTitle:"Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.")
    }
    // 3
    let region = self.region(withGeotification: geotification)
    // 4
    
    print("about to begin monitoring")
    locationManager.startMonitoring(for: region)
    print("now monitoring")
  }
  
  func stopMonitoring(geotification: Geotification) {
    for region in locationManager.monitoredRegions {
      guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == geotification.identifier else { continue }
      locationManager.stopMonitoring(for: circularRegion)
    }
  }
  
}

// MARK: AddGeotificationViewControllerDelegate
extension GeotificationsViewController: AddGeotificationsViewControllerDelegate {
  
//  func addGeotificationViewController(controller: AddGeotificationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
    
    func addGeotificationViewController(controller: AddGeotificationViewController, radius: Double, identifier: String, note: String, eventType: EventType) {

//      controller.dismiss(animated: true, completion: nil)
    
      // Generate a VERY ACCURATE COORDINATE

//      var latCoordinate = 0.0
//      var longCoordinate = 0.0
//      var points = [CLLocationCoordinate2D]()
//      
//        
//        
//      while points.count < 100 {
//        if points.count == 0 {
//          
//          latCoordinate += mapView.userLocation.coordinate.latitude
//          print(mapView.userLocation.coordinate.latitude)
//        
//          longCoordinate += mapView.userLocation.coordinate.longitude
//          print(mapView.userLocation.coordinate.longitude)
//          
//            points.append(mapView.userLocation.coordinate)
//        }
//        else if mapView.userLocation.coordinate.latitude != points[points.count-1].latitude || mapView.userLocation.coordinate.longitude != points[points.count-1].longitude{
//          
//          latCoordinate += mapView.userLocation.coordinate.latitude
//          print(mapView.userLocation.coordinate.latitude)
//          longCoordinate += mapView.userLocation.coordinate.longitude
//          print(mapView.userLocation.coordinate.longitude)
//          
//            points.append(mapView.userLocation.coordinate)
//            
//        }
//        
//      }
//      
//      print(latCoordinate/100)
//      print(longCoordinate/100)

      
      
      
    // Generate coordinate
//      var coordinate = mapView.userLocation.coordinate
        tempRadius = radius
        tempIdentifier = identifier
        tempNote = note
        tempEventType = eventType
        collectingPoints = true
      points = [CLLocationCoordinate2D]()
      longCoordinate = 0.0
      latCoordinate = 0.0
        
//      let geotification = Geotification(coordinate: coordinate, radius: radius, identifier: identifier, note: note, eventType: eventType)
//      add(geotification: geotification)
//      saveAllGeotifications()
  }
  
}

// MARK: - Location Manager Delegate
extension GeotificationsViewController: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    mapView.showsUserLocation = (status == .authorizedAlways)
  }
  
  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    print("Monitoring failed for region with identifier: \(region!.identifier)")
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location Manager failed with the following error: \(error)")
  }
  
  
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var location = locations[locations.count - 1]
        if collectingPoints {
          print("Collecting Now")
            if points.count == 0 {
                
                latCoordinate += location.coordinate.latitude
                print(location.coordinate.latitude)
                longCoordinate += location.coordinate.longitude
                print(location.coordinate.longitude)
                          
                points.append(location.coordinate)
            }
            else if Double(points.count) < numPoints {
                
                latCoordinate += location.coordinate.latitude
                print(location.coordinate.latitude)
                longCoordinate += location.coordinate.longitude
                print(location.coordinate.longitude)
                
                points.append(location.coordinate)
              print(points.count)
            }
            if Double(points.count) == numPoints {
              print("add")
              collectingPoints = false
              print(latCoordinate/numPoints)
              print(longCoordinate/numPoints)
              let geoLoco = CLLocationCoordinate2D(latitude: latCoordinate/numPoints, longitude: longCoordinate/numPoints)
              
              let geotification = Geotification(coordinate: geoLoco, radius: tempRadius!, identifier: tempIdentifier!, note: tempNote!, eventType: tempEventType!)
              for g in geotifications{
                print(g.coordinate)
              }
              let clampedRadius = min(tempRadius!, locationManager.maximumRegionMonitoringDistance)
              
              add(geotification: geotification)
              startMonitoring(geotification: geotification)
              saveAllGeotifications()
              dismiss(animated: true, completion: nil)
          }

        }
  }
    
}

// MARK: - MapView Delegate
extension GeotificationsViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    let identifier = "myGeotification"
    if annotation is Geotification {
      var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView?.canShowCallout = true
        let removeButton = UIButton(type: .custom)
        removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
        removeButton.setImage(UIImage(named: "DeleteGeotification")!, for: .normal)
        annotationView?.leftCalloutAccessoryView = removeButton
      } else {
        annotationView?.annotation = annotation
      }
      return annotationView
    }
    return nil
  }
  
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if overlay is MKCircle {
      let circleRenderer = MKCircleRenderer(overlay: overlay)
      circleRenderer.lineWidth = 1.0
      circleRenderer.strokeColor = .purple
      circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
      return circleRenderer
    }
    return MKOverlayRenderer(overlay: overlay)
  }
  
  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    // Delete geotification
    let geotification = view.annotation as! Geotification
    remove(geotification: geotification)
    saveAllGeotifications()
  }
  
}
