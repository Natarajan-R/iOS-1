/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
`DirectoryMonitor` is used to monitor the contents of the provided directory by using a GCD dispatch source.
*/

import Foundation

/// A protocol that allows delegates of `DirectoryMonitor` to respond to changes in a directory.
protocol DirectoryMonitorDelegate: class {
    func directoryMonitorDidObserveChange()
}

class DirectoryMonitor {
    // MARK: Properties
    
    /// The `DirectoryMonitor`'s delegate who is responsible for responding to `DirectoryMonitor` updates.
    weak var delegate: DirectoryMonitorDelegate?
    
    /// A file descriptor for the monitored directory.
    var monitoredDirectoryFileDescriptor: CInt = -1
    
    /// A dispatch queue used for sending file changes in the directory.
    let directoryMonitorQueue = DispatchQueue(label: "org.kiwix.directorymonitor", attributes: DispatchQueueAttributes.concurrent)
    
    /// A dispatch source to monitor a file descriptor created from the directory.
    var directoryMonitorSource: DispatchSource?
    
    /// URL for the directory being monitored.
    var URL: Foundation.URL
    
    // MARK: Initializers
    init(URL: Foundation.URL) {
        self.URL = URL
    }
    
    // MARK: Monitoring
    
    func startMonitoring() {
        // Listen for changes to the directory (if we are not already).
        if directoryMonitorSource == nil && monitoredDirectoryFileDescriptor == -1 {
            // Open the directory referenced by URL for monitoring only.
            monitoredDirectoryFileDescriptor = open(URL.path!, O_EVTONLY)
            
            // Define a dispatch source monitoring the directory for additions, deletions, and renamings.
            directoryMonitorSource = DispatchSource.fileSystemObject(fileDescriptor: monitoredDirectoryFileDescriptor, eventMask: DispatchSource.FileSystemEvent.write, queue: directoryMonitorQueue) /*Migrator FIXME: Use DispatchSourceFileSystemObject to avoid the cast*/ as! DispatchSource
            
            // Define the block to call when a file change is detected.
            directoryMonitorSource!.setEventHandler {
                // Call out to the `DirectoryMonitorDelegate` so that it can react appropriately to the change.
                self.directoryContentDidChange()
                return
            }
            
            // Define a cancel handler to ensure the directory is closed when the source is cancelled.
            directoryMonitorSource!.setCancelHandler {
                close(self.monitoredDirectoryFileDescriptor)
                
                self.monitoredDirectoryFileDescriptor = -1
                
                self.directoryMonitorSource = nil
            }
            
            // Start monitoring the directory via the source.
            directoryMonitorSource!.resume()
        }
    }
    
    func stopMonitoring() {
        // Stop listening for changes to the directory, if the source has been created.
        if directoryMonitorSource != nil {
            // Stop monitoring the directory via the source.
            directoryMonitorSource!.cancel()
        }
    }
    
    // MARK: - Custom Methods
    
    var isCheckingChanges = false
    var previousDirectoryHash: [String]? = nil
    var currentDirectoryHash: [String]? = nil
    var hashEqualCheck = 0
    
    private func directoryContentDidChange() {
        hashEqualCheck = 0
        if isCheckingChanges == false {
            checkDirectoryChanges()
        }
    }
    
    private func checkDirectoryChanges() {
        isCheckingChanges = true
        
        previousDirectoryHash = currentDirectoryHash
        currentDirectoryHash = directoryHashes()
        if let previousDirectoryHash = previousDirectoryHash, let currentDirectoryHash = currentDirectoryHash {
            if previousDirectoryHash == currentDirectoryHash {
                hashEqualCheck += 1
                if hashEqualCheck > 2 {
                    hashEqualCheck = 0
                    isCheckingChanges = false
                    self.previousDirectoryHash = nil
                    self.currentDirectoryHash = nil
                    directoryDidReachStasis()
                } else {
                    waitAndCheckAgain()
                }
            } else {
                hashEqualCheck = 0
                waitAndCheckAgain()
            }
        } else {
            checkDirectoryChanges()
        }
    }
    
    private func directoryDidReachStasis() {
        DispatchQueue.main.after(when: DispatchTime.now() + Double(Int64(NSEC_PER_SEC/10)) / Double(NSEC_PER_SEC) , execute: { () -> Void in
            self.delegate?.directoryMonitorDidObserveChange()
        })
    }
    
    private func waitAndCheckAgain() {
        directoryMonitorQueue.after(when: DispatchTime.now() + Double(Int64(NSEC_PER_SEC/2)) / Double(NSEC_PER_SEC) , execute: { () -> Void in
            self.checkDirectoryChanges()
        })
    }
    
    // MARK: - Generate directory file info array
    
    private func directoryHashes() -> [String] {
        var hashes = [String]()
        if let path = self.URL.path {
            do {
                let contents = try Foundation.FileManager.default.contentsOfDirectory(atPath: path)
                for file in contents {
                    if let hash = fileHash(file) {
                        hashes.append(hash)
                    }
                }
            } catch let error as NSError {
                // failure
                print("contentsOfDirectoryAtPath failed: \(error.localizedDescription)")
            }
        }
        return hashes
    }
    
    private func fileHash(_ fileName: String) -> String? {
        if let fileSize = fileSize(fileName) {
            return fileName + "_\(fileSize)"
        } else {
            return nil
        }
    }
    
    private func fileSize(_ fileName: String) -> Int64? {
        if let path = try! self.URL.appendingPathComponent(fileName).path {
            if Foundation.FileManager.default.fileExists(atPath: path) {
                do {
                    let attributes = try Foundation.FileManager.default.attributesOfItem(atPath: path)
                    let fileSize = attributes[FileAttributeKey.size] as? NSNumber
                    return fileSize?.int64Value
                } catch let error as NSError {
                    // failure
                    print("attributesOfItemAtPath failed: \(error.localizedDescription)")
                }
            }
        }
        return nil
    }
}
