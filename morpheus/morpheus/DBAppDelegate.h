//
//  DBAppDelegate.h
//  morpheus
//
//  Created by Moskvin Andrey on 6/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DBLoginViewController;
@interface DBAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) DBLoginViewController* loginController;

@end
