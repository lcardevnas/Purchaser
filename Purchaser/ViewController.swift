//
//  ViewController.swift
//  Purchaser
//
//  Created by Luis Cardenas on 27/11/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import UIKit
import StoreKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView?
    
    var products = [SKProduct]()
    var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestProducts()
    }


    // MARK: - Helpers
    func requestProducts() {
        Purchaser.requestProducts { [unowned self] (products, _, error) in
            if let error = error {
                print("error requesting products: \(error)")
            } else {
                self.products = products
                self.reload()
            }
        }
    }

    fileprivate func buy(_ product: SKProduct) {
        Purchaser.buy(product) { (state, _, _, error) in
            if let error = error {
                print("error buying product: \(error)")
            } else {
                if state == .purchasing || state == .deferred { return }
                print("product purchased or restored!")
            }
        }
    }
    
    fileprivate func reload() {
        tableView?.reloadData()
    }
}


extension ViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let product = products[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)
        cell.textLabel?.text = product.localizedTitle
        
        formatter.locale = product.priceLocale
        cell.detailTextLabel?.text = formatter.string(from: product.price)
        return cell
    }
}


extension ViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = products[indexPath.row]
        buy(product)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

