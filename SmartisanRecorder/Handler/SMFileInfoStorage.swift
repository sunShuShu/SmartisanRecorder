//
//  SMAudioStorage.swift
//  SmartisanRecorder
//
//  Created by sunda on 2017/12/19.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

import Foundation

class SMFileInfoStorage {
    static let filePath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last!
    private let storage: SMStorage
    
    init?() {
        let newStorage = SMStorage.init(databasePath: "\(SMFileInfoStorage.filePath)/SMAudioFile.db", table: "AudioInfo", class: SMFileStorageModel.self) { (error) in
            assert(false, "\(error)")
            SMLog("\(error)", error: error as NSError, level: .high)
        }
        if newStorage == nil {
            return nil
        } else {
            storage = newStorage!
        }
    }
    
    deinit {
        SMLog("\(type(of: self)) RELEASE! :\(self)")
    }
    
    func addFile(_ model: SMFileStorageModel) -> Bool {
        return storage.insert(model)
    }
    
    func deleteFile(_ model: SMFileStorageModel) -> Bool {
        return storage.deleteObject(model.localID)
    }
    
    func updateFile(_ model: SMFileStorageModel) -> Bool {
        return storage.modifyObject(model)
    }
    
    /// Try to cache the return value, the function will check the validity of each file and take longer.
    ///
    /// - Returns: All audio file info.
    func getAllFiles() -> [SMFileStorageModel]? {
        if let allFiles = (storage.getAllObjects() as? [SMFileStorageModel]) {
            var finalDic = [SMFileStorageModel]()
            for fileInfo in allFiles {
                var checkResult = false
                let fileAttributes: [FileAttributeKey:Any]
                do {
                    try fileAttributes = FileManager.default.attributesOfItem(atPath: SMFileInfoStorage.filePath + "/\(fileInfo.name)")
                } catch {
                    SMLog("Get file attributes failed.", error: error as NSError, level: .high)
                    if (error as NSError).code == 260 {
                        //No such file
                        checkResult = false
                    } else {
                        //Only if there is no file to delete it from the database, do not delete the file at will
                        checkResult = true
                    }
                }
                let fileModifayData = fileAttributes[FileAttributeKey.modificationDate]
                let fileSize = fileAttributes[FileAttributeKey.size]
//                if fileModifayData == fileInfo.createTime && fileSize == fileInfo.fileSize {
                    finalDic.append(fileInfo)
//                }
            }
            return finalDic
        }
        return nil
    }

}
