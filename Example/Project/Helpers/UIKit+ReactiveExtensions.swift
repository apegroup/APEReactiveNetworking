//
//  UIKit+ReactiveExtensions.swift
//  Example
//
//  Created by Magnus Eriksson on 2016-10-31.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import UIKit
import ReactiveSwift

struct AssociationKey {
    static var text: UInt8 = 3
}

func lazyMutableProperty<T>(host: AnyObject,
                         key: UnsafeRawPointer,
                         setter: @escaping (T) -> (),
                         getter: () -> T) -> MutableProperty<T> {
    return lazyAssociatedProperty(host: host, key: key, factory: {
        let property = MutableProperty<T>(getter())
        property.producer.startWithValues { newValue in
            setter(newValue)
        }
        return property
    })
}

// lazily creates a gettable associated property via the given factory
func lazyAssociatedProperty<T: AnyObject>(host: AnyObject,
                            key: UnsafeRawPointer,
                            factory: ()->T) -> T {
    return objc_getAssociatedObject(host, key) as? T ?? {
        let associatedProperty = factory()
        objc_setAssociatedObject(host, key, associatedProperty, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        return associatedProperty
        }()
}

extension UILabel {
    public var rac_text: MutableProperty<String> {
        return lazyMutableProperty(host: self,
                                   key: &AssociationKey.text,
                                   setter: { self.text = $0 },
                                   getter: { self.text ?? "" })
    }
}
