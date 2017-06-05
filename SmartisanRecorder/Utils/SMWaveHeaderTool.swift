//
//  SMWaveHeaderTool.swift
//  SmartisanRecorder
//
//  Created by sunda on 17/05/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation

class SMWaveHeaderTool {
    
    static let supportedBitWidth = 2 * BYTE_SIZE
    static let waveHeader = Data(bytes:
        [0x52,0x49,0x46,0x46,//RIFF
        0x00,0x00,0x00,0x00, //size(placeholder)
        0x57,0x41,0x56,0x45, //WAVE
        0x66,0x6D,0x74,0x20, //fmt
        0x10,0x00,0x00,0x00, //
        0x01,0x00,           //1(pcm)
        0x01,0x00,           //1(mono)
        0x00,0x00,0x00,0x00, //sample rate(placeholder)
        0x00,0x00,0x00,0x00, //bytes per second(placeholder)
        0x02,0x00,           //2(block align)
        0x10,0x00,           //16(bits per sample) //Currently only 16-bit PCM data is supported
        0x64,0x61,0x74,0x61, //data
        0x00,0x00,0x00,0x00  //size(placeholder)
        ])
    private static let waveSize1Range = 0x04...0x07
    private static let waveSampleRateRange = 0x18...0x1B
    private static let waveBPSRange = 0x1C...0x1F
    private static let waveSize2Range = 0x28...0x2B
    
    /// Check wave file header validity
    ///
    /// - Parameter url: file URL
    /// - Returns: (validity, sampl rate)
    static func check(file: URL) -> (isValid: Bool, sampleRate:Int) {
        var handle: FileHandle?
        do {
            try handle = FileHandle(forReadingFrom: file)
        } catch  {
            return (false, 0)
        }
        
        let headerLength = SMWaveHeaderTool.waveHeader.count;
        let iData = handle!.readData(ofLength: headerLength)
        handle!.closeFile()
        guard iData.count == headerLength else {
            return (false, 0)
        }
        
        let range = SMWaveHeaderTool.waveSampleRateRange
        let sampleRate = Int(iData.subData(range.first!, range.count).toInt32(isLittleEndian: true))
        guard SMRecorder.QualitySettings.low.sampleRate <= sampleRate
            && sampleRate <= SMRecorder.QualitySettings.high.sampleRate
            && sampleRate % SMRecorder.QualitySettings.low.sampleRate == 0 else {
                return (false, 0)
        }
        
        var headerData = iData.subData(0, headerLength)
        headerData.replaceSubrange(SMWaveHeaderTool.waveSize1Range,
                                   with: Data(repeatElement(0, count: SMWaveHeaderTool.waveSize1Range.count)))
        headerData.replaceSubrange(SMWaveHeaderTool.waveSampleRateRange,
                                   with: Data(repeatElement(0, count: SMWaveHeaderTool.waveSampleRateRange.count)))
        headerData.replaceSubrange(SMWaveHeaderTool.waveBPSRange,
                                   with: Data(repeatElement(0, count: SMWaveHeaderTool.waveBPSRange.count)))
        headerData.replaceSubrange(SMWaveHeaderTool.waveSize2Range,
                                   with: Data(repeatElement(0, count: SMWaveHeaderTool.waveSize2Range.count)))
        
        return headerData == SMWaveHeaderTool.waveHeader ? (true, sampleRate) : (false, 0)
    }
    
    
    /// Set size,sample reta and BPS info for wave file
    ///
    /// - Parameter file: file URL
    /// - Returns: success or not
    static func setHeaderInfo(file: URL, sampleRate: Int) -> Bool {
        var finalFileSize = 0
        var handle: FileHandle?
        do {
            let info = try FileManager.default.attributesOfItem(atPath: file.path)
            finalFileSize = Int(info[FileAttributeKey.size] as! UInt64)
            try handle = FileHandle(forWritingTo: file)
        } catch  {
            return false
        }
        guard finalFileSize > 0 else {
            return false
        }
        
        let size1 = finalFileSize - (SMWaveHeaderTool.waveSize1Range.last! + 1)
        let bps = Int32(sampleRate) * (SMWaveHeaderTool.supportedBitWidth / BYTE_SIZE)
        let size2 = finalFileSize - (SMWaveHeaderTool.waveSize2Range.last! + 1)
        handle?.seek(toFileOffset: UInt64(SMWaveHeaderTool.waveSize1Range.first!))
        handle?.write(UInt32(size1).toData())
        handle?.seek(toFileOffset: UInt64(SMWaveHeaderTool.waveSampleRateRange.first!))
        handle?.write(UInt32(sampleRate).toData())
        handle?.seek(toFileOffset: UInt64(SMWaveHeaderTool.waveBPSRange.first!))
        handle?.write(UInt32(bps).toData())
        handle?.seek(toFileOffset: UInt64(SMWaveHeaderTool.waveSize2Range.first!))
        handle?.write(UInt32(size2).toData())
        handle?.closeFile()
        return true
    }
    
}
