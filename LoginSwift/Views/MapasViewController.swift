//
//  MapasViewController.swift
//  LoginSwift
//
//  Created by Joaquin Ucha Gallo on 02/12/2025.
//

import Foundation


import MapKit

class ViewController: UIViewController, MKMapViewDelegate, UISearchResultsUpdating {
    
    
    
    @IBOutlet weak var mapView: MKMapView!
    let searchVC = UISearchController(searchResultsController:ResultsViewController())
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title  = "Mapas"
        view.addSubview(mapView)
        searchVC.searchBar.backgroundColor = .secondarySystemBackground
        searchVC.searchBar.placeholder = "Buscar"
        searchVC.searchResultsUpdater = self
        navigationItem.searchController = searchVC
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.frame = CGRect(x: 0, y: view.safeAreaInsets.top, width:view.frame.size.width, height: view.frame.size.height - view.safeAreaInsets.bottom)
            
            
            
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
}
