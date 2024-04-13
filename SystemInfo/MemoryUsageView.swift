//
//  MemoryUsageView.swift
//  SystemInfo
//
//  Created by Tanner Lovelace on 4/12/24.
//

import Foundation
import SwiftUI
import Charts

public class MemoryUsage {
    public static func getUsedMemoryInBytes() -> Int64
    {
        var usedMemory: Int64 = 0
        let hostPort: mach_port_t = mach_host_self()
        var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        var pagesize:vm_size_t = 0
        host_page_size(hostPort, &pagesize)
        var vmStat = vm_statistics_data_t()
        let capacity = MemoryLayout.size(ofValue: vmStat) / MemoryLayout<Int32>.stride
        
        let status: kern_return_t = withUnsafeMutableBytes(of: &vmStat) {
            let boundPtr = $0.baseAddress?.bindMemory(to: Int32.self, capacity: capacity)
            return host_statistics(hostPort, HOST_VM_INFO, boundPtr, &host_size)
        }
        
        // Now take a look at what we got and compare it against KERN_SUCCESS
        if status == KERN_SUCCESS {
            usedMemory = (Int64)((vm_size_t)(vmStat.active_count + vmStat.inactive_count + vmStat.wire_count) * pagesize)
        }
        
        return usedMemory
    }
}

struct MemoryUsageView: View {
    @State var usedMemory: Int64 = MemoryUsage.getUsedMemoryInBytes()
    let physicalMemory = ProcessInfo.processInfo.physicalMemory

    var body: some View {
        Chart {
            SectorMark(
                angle: .value("Used memory", usedMemory),
                innerRadius: .ratio(0.618),
                angularInset: 1.5
                )
                .foregroundStyle(.red)
            SectorMark(
                angle: .value("Free memory", Int64(physicalMemory)-usedMemory),
                innerRadius: .ratio(0.618),
                angularInset: 1.5
                )
                .foregroundStyle(.green)
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                let frame = geometry[chartProxy.plotFrame!]
                VStack {
                    Text("Memory")
                        .font(.largeTitle)
                    Text("Used: \(ByteCountFormatter.string(fromByteCount: usedMemory, countStyle: .memory))")
                        .foregroundStyle(.red)
                    Text("Free: \(ByteCountFormatter.string(fromByteCount: Int64(physicalMemory)-usedMemory, countStyle: .memory))")
                        .foregroundStyle(.green)
                    Text("Total memory: \(ByteCountFormatter.string(fromByteCount: Int64(physicalMemory), countStyle: .memory))")
                }
                .position(x: frame.midX, y: frame.midY)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                usedMemory = MemoryUsage.getUsedMemoryInBytes()
            }
        }
    }
}

#Preview {
    MemoryUsageView()
}
