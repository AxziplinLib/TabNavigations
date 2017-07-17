//
//  Object.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/13.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import Foundation
import RealmSwift
import CloudKit

open class AxObject: Object {
    dynamic var id: String = "_Root_Object"
    dynamic var uid: String?
    dynamic var index: Int = 0
    dynamic var atCreation: Date = Date()
    dynamic var atUpdation: Date = Date()
    
    override open class func primaryKey() -> String? {
        return "id"
    }
    override open class func indexedProperties() -> [String] {
        return ["id", "uid", "index", "atCreation", "atUpdation"]
    }
}

public protocol RealmGetter: class {
    static var current: Realm { get }
    static var memory: Realm { get }
}

extension Realm {
    class var `default`: Realm {
        return try! Realm(configuration: .default)
    }
    class var schemaVersion: UInt64 {
        return 0
    }
}

extension Realm.Configuration {
    static var `default`: Realm.Configuration {
        return Realm.Configuration.defaultConfiguration
    }
}
extension AxRealmManager {
    public typealias AxRealmWriteTransaction = (Realm) -> Void
}
public struct AxRealmManager {
    public static var `default`: AxRealmManager { return AxRealmManager() }
    private var _queue: DispatchQueue = DispatchQueue(label: "com.axreminder.realm.transaction")
    
    public func synsWrites(`in` realm: Realm = .default, transaction: AxRealmWriteTransaction) {
        _queue.sync {
            autoreleasepool {
                realm.beginWrite()
                transaction(realm)
                defer {
                    if realm.isInWriteTransaction {
                        realm.cancelWrite()
                    }
                    if !realm.autorefresh {
                        realm.refresh()
                    }
                }
                do {
                    try realm.commitWrite()
                } catch let error as NSError {
                    print("Transaction of realm failed: \(error)")
                }
            }
        }
    }
    
    public func asynsWrites(`in` realm: Realm = .default, transaction: @escaping AxRealmWriteTransaction, completion: (()->Void)? = nil) {
        _queue.async {
            autoreleasepool {
                realm.beginWrite()
                transaction(realm)
                defer {
                    if realm.isInWriteTransaction {
                        realm.cancelWrite()
                    }
                    if !realm.autorefresh {
                        realm.refresh()
                    }
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
                do {
                    try realm.commitWrite()
                } catch let error as NSError {
                    print("Transaction of realm failed: \(error)")
                }
            }
        }
    }
}
