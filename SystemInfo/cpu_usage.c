//
//  cpu_usage.c
//  SystemInfo
//
//  Created by Tanner Lovelace on 4/12/24.
//

#include "cpu_usage.h"

host_cpu_load_info_data_t hostCPULoadInfo(void)
{
    kern_return_t kr;
    mach_msg_type_number_t count;
    host_cpu_load_info_data_t r_load;

    count = HOST_CPU_LOAD_INFO_COUNT;
    kr = host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, (int *)&r_load, &count);
    if (kr != KERN_SUCCESS) {
        printf("oops: %s\n", mach_error_string(kr));
        // Set to zero for error return
        r_load.cpu_ticks[CPU_STATE_SYSTEM] = 0;
        r_load.cpu_ticks[CPU_STATE_USER] = 0;
        r_load.cpu_ticks[CPU_STATE_IDLE] = 0;
        r_load.cpu_ticks[CPU_STATE_NICE] = 0;
    }

    return r_load;
}
