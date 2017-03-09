//
//  SMLocalize.swift
//  SmartisanRecorder
//
//  Created by sunda on 07/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation

class SMLocalize {
    enum LocalizedStringKey: String {
        case promptTitle = "kPromptTitle"
        case micPermission = "kMicPermission"
        case goToSetPersion = "kGoToSetPermission"
        case cancel = "kCancel"
        case ok = "kOK"
    }
    
    static func string(_ key: LocalizedStringKey) -> String {
        let localizedString = NSLocalizedString(key.rawValue, comment: "")
        return localizedString
    }
}
