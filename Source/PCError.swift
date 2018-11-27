//
//  PCError.swift
//  Purchaser
//
//  Created by Luis Cardenas on 27/11/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import Foundation

enum PCError: Error {
    case iapResponseFailed(reason: IAPResponseFailureReason)
    
    enum IAPResponseFailureReason: Int {
        case noIAPReceiptUrl
        case missingProductIdentifiers
    }
}


// MARK: - Error Descriptions
extension PCError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .iapResponseFailed(let reason):
            return reason.localizedDescription
        }
    }
}

extension PCError.IAPResponseFailureReason {
    var localizedDescription: String {
        switch self {
        case .noIAPReceiptUrl:              return NSLocalizedString("no_iap_receipt_url", comment: "Missing appStore receipt url")
        case .missingProductIdentifiers:    return NSLocalizedString("missing_product_identifiers", comment: "User has not been set any product identifier")
        }
    }
}
