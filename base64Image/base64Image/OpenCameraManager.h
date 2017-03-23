//
//  OpenCameraManager.h
//  AuthorityTest
//
//  Created by njxh on 17/1/14.
//  Copyright © 2017年 LianghaoAn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCameraManager : NSObject

/**
 *  单例类
 *
 *  @return 您可以通过此方法，获取CameraAudioManager的单例，访问对象中的属性和方法
 */
+ (instancetype)defaultCameraAudioManager;

/**
 *  拍照或者录制视频
 *
 *  @param viewController 控制器
 *  @param typeString     @“camera”拍照  “audio”录制视频
 */
- (void)takeCameraAndAudioWithImageName:(NSString *)nameString WithViewController:(UIViewController *)viewController WithType:(NSString *)typeString;
/**
 *  视频拍照类的回调block
 */
@property (nonatomic, copy) void (^cameraAudioBlock) (NSString *description, UIImage *image);
@end
