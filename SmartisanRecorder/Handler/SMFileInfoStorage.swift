//
//  SMAudioStorage.swift
//  SmartisanRecorder
//
//  Created by sunda on 2017/12/19.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

import Foundation

class SMFileInfoStorage {
    static let filePath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last! + "/AudioInfo"
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
        SMLog("\(type(of: self)) RELEASE!")
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
                var isFileExist = true
                defer {
                    if isFileExist {
                        finalDic.append(fileInfo)
                    } else {
                        storage.deleteObject(fileInfo.localID)
                    }
                }
                let fileAttributes: [FileAttributeKey:Any]
                do {
                    try fileAttributes = FileManager.default.attributesOfItem(atPath: SMRecorder.filePath + "/" + fileInfo.name)
                } catch {
                    SMLog("\(error)", error: error as NSError, level: .high)
                    //Only if there is no such file, delete it from the database, do not delete the file at will
                    isFileExist = (error as NSError).code != 260 //No such file
                    continue
                }
                let creationDate = fileAttributes[FileAttributeKey.creationDate] as? Date
                let fileSize = fileAttributes[FileAttributeKey.size] as? Int
                if creationDate != nil && fileSize != nil {
                    if Int(creationDate!.timeIntervalSince1970) != Int(fileInfo.createTime.timeIntervalSince1970) ||
                        fileSize != fileInfo.fileSize {
                        isFileExist = false
                        SMLog("Check file info faile! database:\(fileInfo.createTime),\(fileInfo.fileSize). file:\(creationDate!),\(fileSize!)", level: .high)
                    }
                }
            }
            return finalDic
        }
        return nil
    }

}
