Overview
==============
<!--
[![Pod Version](http://img.shields.io/cocoapods/v/Purchaser.svg?style=flat)](https://github.com/ThXou/Purchaser)
[![Pod Platform](http://img.shields.io/cocoapods/p/Purchaser.svg?style=flat)](https://github.com/ThXou/Purchaser)
[![Pod License](http://img.shields.io/cocoapods/l/Purchaser.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0.html)-->

Purchaser is a set of classes written in Swift to help iOS developers to simplify the process of implementing In-App purchases in their applications.

TO-DO
==============

* Support all kinds of products (Now only supports Auto-Renewable subscriptions).
* Add receipt validation.
* Add receipt refresh.


Requirements
==============

* iOS 9.0+
* Xcode 10.0+
* Swift 4.2+

<!--
Install
==============
-->
<!--
### Cocoapods
-->
<!--Add this line to your podfile:-->
<!--
```ruby
pod 'Purchaser'
```
-->
Setup
==============

Import `Purchaser` in your source file:

```swift
import Purchaser
```

Now you have the option of setup the product idenfitiers at the beginning, so the actions the library do, will be done using these identifiers; Or you have the option to setup identifiers manually in the future on demand. In any case, it is strongly recommended that you setup `Purchaser` in the `AppDelegate.swift` subclass. Simply call:

```ruby
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Setup with product identifiers
    Purchaser.setup(with: ["my_awesome_product_identifier"])
    // Setup identifiers later
    Purchaser.setup()
    return true
}
```
This step is mandatory so all the transactions can be processed as expected, even if they initially fail due to a lack of internet connection or app termination.

⚠️ Considerations
==============

### Closures

In order to not feed the Strong Reference Cycle monster, make sure you use `self` marked as `weak` or `unowned` as in the example code provided when needed. `Purchaser` stores the completion closures in a property retaining the objects inside the closure.

Request products
==============

To request a list of products from the App Store use the following:

```swift
Purchaser.requestProducts { [unowned self] (products, _, error) in
    if let error = error {
        print("error requesting products: \(error)")
    } else {
        self.products = products
        self.reload()
    }
}
```

It returns an array of `SKProduct` objects, an array of invalid product identifiers and an `Error` object identifying the error if any.

If you choose to setup product identifiers later, you should pass an array of product identifiers with the call:

```swift
let identifiers = ["my_awesome_product_identifier"]
Purchaser.requestProducts(with: identifiers) { (products, _, error) in
    // Handle response
}
```
If not provided, the call returns a "Missing product identifiers" error.

Buying products
==============

Once you've got the list of valid products from Apple, you can call the `buy(product:)` function on each product:

```swift
Purchaser.buy(product) { (state, _, _, error) in
    if let error = error {
        print("error buying product: \(error)")
    } else {
        if state == .purchasing || state == .deferred { return }
        print("product purchased!")
    }
}
```
The closure will be called for each finished transactions. For unfinished transactions, the closure will be called after the system recoveries from whatever doesn't have had allowed to finish the transaction.

Additionally (**and recommended**), you can pass an `account` parameter that will be used in the `SKPayment` object's `applicationUsername` parameter. The value of this property can be a String which identifies the user making the transaction (username, email, etc). `Purchaser` creates a SHA256 hash of the value you pass and sets the `applicationUsername` parameter with it.

#### Checking purchase state of a product
You can check if a product have been purchased by calling:

```swift
Purchaser.isProductPurchased(with: "my_awesome_product_identifier")
```

#### Check if user can make payments

Sometimes the payments feature is restricted due to, for example, parental controls configured in the device. To check if the user can make payments use:

```swift
Purchaser.canMakePayments()
```

Developers usually hide payment related UI if the user is unable to make payments.

Restoring products
==============

To restore previously finished transactions, you need to call:

```swift
Purchaser.restorePurchases { (state, _, finished, error) in
    if let error = error {
        print("error restoring products: \(error)")
    } else {
        if state == .purchasing || state == .deferred { return }
        print("products restored!")
    }
}
```
You can inspect the `finished` parameter to know if all the transactions have been finished. It will be set a `false` for any single transaction restored but will be set to `true` when all the transactions has been restored.