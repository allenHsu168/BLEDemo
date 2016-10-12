//
//  MasterViewController.swift
//  BLEDemo
//
//  Created by 許家旗 on 2016/10/8.
//  Copyright © 2016年 許家旗. All rights reserved.
//

import UIKit
import CoreBluetooth

class MasterViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    var detailViewController: DetailViewController? = nil
    var objects = [Any]()

    var centralManager:CBCentralManager?
    
    var allItems = [String:DiscoveredItem]()
    
    var lastReloadDate:Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        ////
//        self.navigationItem.leftBarButtonItem = self.editButtonItem
//
//        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
//        self.navigationItem.rightBarButtonItem = addButton
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        centralManager = CBCentralManager(delegate: self, queue:nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(_ sender: Any) {
        objects.insert(NSDate(), at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.insertRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row] as! NSDate
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let allKeys = Array(allItems.keys)
        let targetKey = allKeys[indexPath.row]
        let targetItem = allItems[targetKey]
        
        let name = targetItem?.peripheral.name ?? "Unknown"
        cell.textLabel!.text = "\(name) RSSI: \(targetItem!.lastRSSI)"
        
        let lastSeenSecondsAgo = String(format: "%.1f", Date().timeIntervalSince(targetItem!.lastSeenDateTime))
        cell.detailTextLabel!.text = "Last seen \(lastSeenSecondsAgo) seconds ago."
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    func startToScan() {
        
        NSLog("Start Scan.")
        
        let options = [CBCentralManagerOptionShowPowerAlertKey:true]
        
        centralManager?.scanForPeripherals(withServices: nil, options: options)
    }
    
    func stopScanning() {
    
        centralManager?.stopScan()
    }
    
    func showAlert(_ msssage:String) {
        
        let alert = UIAlertController(title: "狀態", message: msssage, preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: CBCentralManagerDelegate Methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        let state = central.state
        
        if state != .poweredOn {
            // Error oucur.
            showAlert("BLE is not available. (Error: \(state.rawValue))")
        } else {
            
            startToScan()
        }
    }
 
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
     
        let existItem = allItems[peripheral.identifier.uuidString]
        
        if existItem == nil {
            
            // It is a new item
            let name = (peripheral.name ?? "Unknown")
            NSLog("Discovered: \(name), RSSI: \(RSSI), UUID: \(peripheral.identifier.uuidString), AdvData: \(advertisementData.description)) ")
        }
        let newItem = DiscoveredItem(newperipheral: peripheral, RSSI: Int(RSSI))
        allItems[peripheral.identifier.uuidString] = newItem
        
        // Decide when to reload TableView
        let now = Date()
        
        if existItem == nil || lastReloadDate == nil || now.timeIntervalSince(lastReloadDate!) > 2.0 {
            
            lastReloadDate = now
            
            // Refresh TableView
            tableView.reloadData()
        }
    }
}

