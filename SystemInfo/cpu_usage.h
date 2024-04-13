//
//  cpu_usage.h
//  SystemInfo
//
//  Created by Tanner Lovelace on 4/12/24.
//

#ifndef cpuload_h
#define cpuload_h

#include <stdio.h>
#include <mach/mach.h>
#include <mach/processor_info.h>
#include <mach/mach_host.h>

host_cpu_load_info_data_t hostCPULoadInfo(void);

#endif /* cpu_usage.h */
