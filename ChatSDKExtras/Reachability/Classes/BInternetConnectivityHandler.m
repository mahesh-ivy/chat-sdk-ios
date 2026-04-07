//
//  BInternetConnectivity.m

//
//  Created by Ben on 10/10/18.
//

#import "BInternetConnectivityHandler.h"
#import <ChatSDK/Core.h>
#import <Network/Network.h>

@implementation BInternetConnectivityHandler {
    nw_path_monitor_t _monitor;
    BOOL _isConnected;
}

-(instancetype) init {
    if ((self = [super init])) {
        _isConnected = YES;
        _monitor = nw_path_monitor_create();
        nw_path_monitor_set_update_handler(_monitor, ^(nw_path_t path) {
            self->_isConnected = nw_path_get_status(path) == nw_path_status_satisfied;
            [BHookNotification notificationInternetConnectivityDidChange];
        });
        nw_path_monitor_set_queue(_monitor, dispatch_get_main_queue());
        nw_path_monitor_start(_monitor);
    }
    return self;
}

-(BOOL) isConnected {
    return _isConnected;
}

@end
