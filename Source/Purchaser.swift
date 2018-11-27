//
//  Purchaser.swift
//  Purchaser
//
//  Created by Luis Cardenas on 27/11/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import UIKit
import StoreKit
import CommonCrypto

/// A convenience type for product identifiers.
public typealias ProductIdentifier = String

/// A closure returned after requesting a list of products
public typealias ProductsRequestCompletionHandler = (_ products: [SKProduct], _ invalidIdentifiers: [String], _ error: Error?) -> ()

/// A closure returned after transactions have been completed.
///
/// - parameter state:          The current state of the transaction.
/// - parameter transaction:    The transaction being processed.
/// - parameter finished:       Indicates if the transaction has finished processing up to the end.
/// - parameter error:          An error object if there was a problem with the transaction.
public typealias ProductsTransactionCompletionHandler = (_ state: PurchaserTransactionState, _ transaction: SKPaymentTransaction?, _ finished: Bool, _ error: Error?) -> ()

extension Notification.Name {
    static let PurchaseNotification = Notification.Name(rawValue: "PurchaserPurchaseNotification")
}

/// The state of the currently processing transaction.
public enum PurchaserTransactionState {
    case purchased
    case failed
    case restored
    case deferred
    case purchasing
}


public class Purchaser: NSObject {
    
    // A singleton object to manage In-App purchase data
    fileprivate static let manager = Purchaser()
    
    fileprivate var productIdentifiers: Set<ProductIdentifier> = []
    fileprivate var products = [SKProduct]()
    fileprivate var productsRequest: SKProductsRequest?
    fileprivate var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    fileprivate var productsTransactionCompletionHandler: ProductsTransactionCompletionHandler?

    
    // MARK: - Setup
    /// Use this if you want to manually set the product identifiers to request. It is strongly recommended
    /// to call this in the `AppDelegate.swift` class.
    public class func setup() {
        setup(with: [])
    }
    
    /// Use this if you have a fixed set of product identifiers to request every time. It sets the observer
    /// for transactions.
    /// ```
    /// Purchaser.setup(with: ["my_awesome_product_identifier"])
    /// ```
    /// It is strongly recommended to call this in the `AppDelegate.swift` class.
    ///
    /// - parameter productIdentifiers: A `Set` object with the product identifiers to request.
    public class func setup(with productIdentifiers: Set<String>) {
        Purchaser.manager.productIdentifiers = productIdentifiers
        // Setting up transaction observer
        SKPaymentQueue.default().add(Purchaser.manager)
    }
    
    
    // MARK: - Helpers
    /// Allows you to get a `SKProduct` object from the retrieved products.
    public func getProduct(with identifier: String) -> SKProduct? {
        return products.first(where: { $0.productIdentifier == identifier })
    }
    
    /// Gets the product identifier resource name: the last component in the reverse domain name of the
    /// identifier.
    public func resourceName(for productIdentifier: String) -> String? {
        return productIdentifier.components(separatedBy: ".").last
    }
    
    /// Deletes the stored state of purchased product identifiers.
    public func reset() {
        for productIdentifier in productIdentifiers {
            UserDefaults.standard.removeObject(forKey: productIdentifier)
        }
    }
    
    fileprivate class func hashedValue(forAccount: String) -> String? {
        guard let accountData = forAccount.data(using: String.Encoding.utf8) else {
            return nil
        }
        
        let hashSize = Int(CC_SHA256_DIGEST_LENGTH)
        var hashedChars = [UInt8](repeating: 0,  count: hashSize)
        accountData.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(accountData.count), &hashedChars)
        }
        
        var accountHash = ""
        for i in 0..<hashedChars.count {
            let byte = hashedChars[i]
            if i != 0 && i % 4 == 0 {
                accountHash.append("-")
            }
            accountHash += String(format:"%02x", UInt8(byte))
        }
        
        return accountHash
    }
    
    fileprivate func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}


// MARK: - StoreKit API
public extension Purchaser {
    
    /// Sends a request to the App Store with a specified list of products. If not provided, it returns a "Missing
    /// product identifiers" error.
    ///
    /// - parameter identifiers:    The product identifiers the user need to request from the App Store.
    /// - parameter completion:     The completion closure called after the request has finished or an error has occurred.
    public class func requestProducts(with identifiers: Set<String>, completion: @escaping ProductsRequestCompletionHandler) {
        let manager = Purchaser.manager
        if identifiers.count == 0 {
            let error = PCError.iapResponseFailed(reason: .missingProductIdentifiers)
            manager.productsRequestCompletionHandler?([], [], error)
            return
        }
        
        manager.productsRequest?.cancel()
        manager.productsRequestCompletionHandler = completion
        
        manager.productsRequest = SKProductsRequest(productIdentifiers: identifiers)
        manager.productsRequest?.delegate = manager
        manager.productsRequest?.start()
    }
    
    /// Sends a request to the App Store with the products the user has set in the `AppDelegate.swift` class using the
    /// `setup(with:)` function. If user has missed to setup the identifiers, it returns a "Missing product identifiers"
    /// error.
    ///
    /// - parameter completion:     The completion closure called after the request has finished or an error has occurred.
    public class func requestProducts(_ completion: @escaping ProductsRequestCompletionHandler) {
        requestProducts(with: Purchaser.manager.productIdentifiers, completion: completion)
    }
    
    ///
    public class func buy(_ product: SKProduct, account: String? = nil, completion: @escaping ProductsTransactionCompletionHandler) {
        Purchaser.manager.productsTransactionCompletionHandler = completion
        
        let payment = SKMutablePayment(product: product)
        if let account = account, let hash = hashedValue(forAccount: account) {
            payment.applicationUsername = hash
        }
        SKPaymentQueue.default().add(payment)
    }
    
    public class func isProductPurchased(with identifier: ProductIdentifier) -> Bool {
        return UserDefaults.standard.bool(forKey: identifier)
    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public class func restorePurchases(_ completion: @escaping ProductsTransactionCompletionHandler) {
        Purchaser.manager.productsTransactionCompletionHandler = completion
        
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}


// MARK: - SKProductsRequestDelegate
extension Purchaser : SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        
        productsRequestCompletionHandler?(products, response.invalidProductIdentifiers, nil)
        clearRequestAndHandler()
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        productsRequestCompletionHandler?([], [], error)
        clearRequestAndHandler()
    }
}


// MARK: - SKPaymentTransactionObserver
extension Purchaser : SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:    complete(transaction)
            case .failed:       failed(transaction)
            case .restored:     restored(transaction)
            case .deferred:     deferred(transaction)
            case .purchasing:   purchasing(transaction)
            }
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        productsTransactionCompletionHandler?(.restored, nil, false, error)
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        productsTransactionCompletionHandler?(.restored, nil, true, nil)
    }
}


// MARK: - Transaction Observer Custom Methods
extension Purchaser {
    fileprivate func complete(_ transaction: SKPaymentTransaction) {
        productsTransactionCompletionHandler?(.purchased, transaction, true, nil)
        
        finishTransation(transaction,
                         state: .purchased,
                         productIdentifier: transaction.payment.productIdentifier)
    }
    
    fileprivate func restored(_ transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        productsTransactionCompletionHandler?(.restored, transaction, false, nil)
        
        finishTransation(transaction,
                         state: .restored,
                         productIdentifier: productIdentifier)
    }
    
    fileprivate func failed(_ transaction: SKPaymentTransaction) {
        productsTransactionCompletionHandler?(.failed, transaction, false, transaction.error)
        
        finishTransation(transaction, state: .failed)
    }
    
    fileprivate func deferred(_ transaction: SKPaymentTransaction) {
        productsTransactionCompletionHandler?(.deferred, transaction, true, nil)
    }
    
    fileprivate func purchasing(_ transaction: SKPaymentTransaction) {
        productsTransactionCompletionHandler?(.purchasing, transaction, true, nil)
    }
    
    fileprivate func finishTransation(_ transaction: SKPaymentTransaction, state: PurchaserTransactionState, productIdentifier: String? = nil) {
        NotificationCenter.default.post(name: .PurchaseNotification, object: transaction)
        
        if let identifier = productIdentifier {
            UserDefaults.standard.set(true, forKey: identifier)
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}
