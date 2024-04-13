//
//  VolumeUsageView.swift
//  SystemInfo
//
//  Created by Tanner Lovelace on 4/12/24.
//

import Foundation
import SwiftUI
import Charts

struct VolumeInfo: Hashable {
    var path: URL
    var totalSpaceInBytes: Int64 {
        do {
            let totalValues = try path.resourceValues(forKeys: [.volumeTotalCapacityKey])
            let totalCapacity = totalValues.volumeTotalCapacity
            return Int64(totalCapacity!)
        } catch {
            return Int64(0)
        }
    }
    var freeSpaceInBytes: Int64 {
        do {
            let availValues = try path.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            let availCapacity = availValues.volumeAvailableCapacity
            return Int64(availCapacity!)
        } catch {
            return Int64(0)
        }
    }
    var usedSpaceInBytes: Int64 {
        return totalSpaceInBytes - freeSpaceInBytes
    }
}

struct MountedVolumes {
    static var volumes: [VolumeInfo] {
        return getVolumeInfo()
    }
    
    static var maxVolumeSizeInBytes: Int64 {
        var maxSize: Int64 = 0
        for volume in volumes {
            if volume.totalSpaceInBytes > maxSize {
                maxSize = volume.totalSpaceInBytes
            }
        }
        return maxSize
    }
    
    private static func getVolumeInfo() -> [VolumeInfo] {
        var volInfo: [VolumeInfo] = []
        
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey,
            
        ]
        let volumePaths =  FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: .skipHiddenVolumes)
        
        for path in volumePaths! {
            volInfo.append(VolumeInfo(path: path))
        }

        return volInfo
    }
}

struct VolumeUsageView: View {
    let mountedVolumes = MountedVolumes.volumes
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Mounted volumes")
                .font(.largeTitle)
            
            ForEach(mountedVolumes, id: \.self) { volume in
                Chart {
                    BarMark(
                        x: .value("Used", volume.usedSpaceInBytes),
                        y: .value("Volume", volume.path.path),
                        stacking: .normalized
                    )
                    .foregroundStyle(.red)
                    .annotation(position: .bottom) {
                        Text("Used: \(ByteCountFormatter.string(fromByteCount: volume.usedSpaceInBytes, countStyle:.file))")
                            .font(.caption)
                    }
                    BarMark(
                        x: .value("Free", volume.freeSpaceInBytes),
                        y: .value("Volume", volume.path.path),
                        stacking: .normalized
                    )
                    .foregroundStyle(.green)
                    .annotation(position: .bottom) {
                        Text("Free: \(ByteCountFormatter.string(fromByteCount: volume.freeSpaceInBytes, countStyle:.file))")
                            .font(.caption)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(.clear)
                        AxisValueLabel()
                    }
                }
            
                Spacer()
                Spacer()
                Text("Total disk size: \(ByteCountFormatter.string(fromByteCount: volume.totalSpaceInBytes, countStyle:.file))")
                // Put a line between each volume but not after the last one
                if mountedVolumes.last != volume {
                    Divider()
                }
            }
        }
        .padding()
    }
}



#Preview {
    VolumeUsageView()
}
