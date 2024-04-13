//
//  ContentView.swift
//  SystemInfo
//
//  Created by Tanner Lovelace on 4/12/24.
//

import Foundation
import SwiftUI
import Charts





struct ContentView: View {
    let mountedVolumes: [VolumeInfo] = getVolumeInfo()
    
    var body: some View {
        TabView {
            CPUUsageView()
                .tabItem {
                    Text("CPU Usage")
                }

            MemoryUsageView()
                .tabItem {
                    Text("Memory Usage")
                }
            
            VolumeUsageView()
                .tabItem {
                    Text("Volume Usage")
                }
        }
        .padding()
    }

}

func getVolumeInfo() -> [VolumeInfo] {
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

func getMaxVolumeSize(volumes: [VolumeInfo]) -> Int64 {
    var maxSize : Int64 = 0
    for volume in volumes {
        if (volume.totalSpaceInBytes > maxSize) {
            maxSize = volume.totalSpaceInBytes
        }
    }
    return maxSize
}


#Preview {
    ContentView()
}
