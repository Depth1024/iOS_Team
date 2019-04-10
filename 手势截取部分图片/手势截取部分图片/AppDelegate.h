//
//  AppDelegate.h
//  手势截取部分图片
//
//  Created by zlr on 2019/4/8.
//  Copyright © 2019 Zhou Langrui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

