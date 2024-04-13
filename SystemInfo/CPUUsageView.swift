//
//  CPUUsageView.swift
//  SystemInfo
//
//  Created by Tanner Lovelace on 4/12/24.
//

import Foundation
import SwiftUI
import Charts

public struct CPUUsage {
    var user: Double
    var system: Double
    var idle: Double
}

struct CPUUsageAtTime : Identifiable {
    public let id = UUID()
    var field: String
    var time: Date
    var amount: Double
    
    init(field: String, amount: Double) {
        self.time = Date.now
        self.field = field
        self.amount = amount
    }
}

public class CPUInfo {
    static private let HOST_CPU_LOAD_INFO_COUNT : mach_msg_type_number_t = UInt32(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)

    private static var previousLoad = host_cpu_load_info()
    
    public static func getCPUUsage() -> CPUUsage
    {
        let currentLoad = hostCPULoadInfo()
        
        let userDelta   = Double(currentLoad.cpu_ticks.0 - previousLoad.cpu_ticks.0)
        let systemDelta = Double(currentLoad.cpu_ticks.1 - previousLoad.cpu_ticks.1)
        let idleDelta   = Double(currentLoad.cpu_ticks.2 - previousLoad.cpu_ticks.2)
        let niceDelta   = Double(currentLoad.cpu_ticks.3 - previousLoad.cpu_ticks.3)
        
        let totalTicks = userDelta + systemDelta + idleDelta + niceDelta
        
        // Guard against division by zero
        if (totalTicks == 0) {
            return CPUUsage(user: 0.0, system: 0.0, idle: 0.0)
        }
        
        // User is made up of user and nice
        let currentUser   = (userDelta + niceDelta) / totalTicks * 100.0
        let currentSystem = systemDelta / totalTicks * 100.0
        let currentIdle   = idleDelta / totalTicks * 100.0
        
        // Save for next call
        previousLoad = currentLoad

        return CPUUsage(user: currentUser, system: currentSystem, idle: currentIdle)
    }
    

}

struct CPUUsageView: View {
    @State var usage: CPUUsage = CPUUsage(user: 0.0, system: 0.0, idle: 0.0)
    
    let maxInterval = 5
    @State var interval = 5
    
    @State var entries: [CPUUsageAtTime] = []
    // Since in order to plot multiple lines on a graph, we need to store system and user
    // values in the same array at one per second, the maxEntries value is twice the
    // number of seconds we want to save.  Currently set for 2 minutes of values on the graph
    let maxEntries = 240
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("CPU Usage")
                .font(.largeTitle)
            
            HStack {
                VStack {
                    Text("System usage: \(String(format: "%.2f", usage.system))")
                        .foregroundStyle(.blue)
                    Text("User usage: \(String(format: "%.2f", usage.user))")
                        .foregroundStyle(.red)
                    Text("Idle usage: \(String(format: "%.2f", usage.idle))")
                        .foregroundStyle(.green)
                }
                
                Spacer()
                
                Chart {
                    
                    BarMark(x: .value("System", usage.system), stacking: .normalized)
                        .foregroundStyle(.blue)
                    BarMark(x: .value("User", usage.user), stacking: .normalized)
                        .foregroundStyle(.red)
                    BarMark(x: .value("Idle", usage.idle), stacking: .normalized)
                        .foregroundStyle(.green)
                }
                .frame(height: 32)
                .chartXAxis(.hidden)
            }
            
            Chart(entries) {
                LineMark(x: .value("Seconds", $0.time),
                         y: .value("Amount", $0.amount)
                )
                .foregroundStyle(by: .value("Field", $0.field))
                .interpolationMethod(.cardinal)
            }
            .chartXAxis(.hidden)
            .chartForegroundStyleScale([
                "System": Color(.blue),
                "User": Color(.red)
            ])
            .frame(height: 128)
            .padding()
        }
        .padding()
        .onAppear() {
            // Update usage information when we start and then every second after
            updateUsage()
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateUsage()
            }
        }
    }
    
    func updateUsage() {
        let tempUsage = CPUInfo.getCPUUsage()
        // Sometimes we get zero values for all three but don't show that to the user because it's
        // wrong and confusing
        if !(tempUsage.system == 0 && tempUsage.user == 0 && tempUsage.idle == 0) {
            usage = tempUsage
            
            // Stored in a weird way to appease SwiftUI multiline Charts
            entries.append(CPUUsageAtTime(field: "System", amount: usage.system))
            entries.append(CPUUsageAtTime(field: "User", amount: usage.user))
            
            if entries.count > maxEntries {
                entries.removeFirst()
            }
        }
    }
    
}


#Preview {
    CPUUsageView()
}
