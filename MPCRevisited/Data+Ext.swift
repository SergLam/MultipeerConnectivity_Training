//
//  Data+Ext.swift
//  MPCRevisited
//
//  Created by Andrii Mazepa on 7/17/19.
//  Copyright © 2019 Appcoda. All rights reserved.
//

import Foundation

extension Data {
    
    init(reading input: InputStream) throws {
        self.init()
        input.open()
        defer {
            input.close()
        }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if read < 0 {
                //Stream error occured
                throw input.streamError!
            } else if read == 0 {
                //EOF
                break
            }
            self.append(buffer, count: read)
        }
    }
    
}
