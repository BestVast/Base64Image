//
//  OpenCameraManager.m
//  AuthorityTest
//
//  Created by njxh on 17/1/14.
//  Copyright © 2017年 LianghaoAn. All rights reserved.
//

#import "OpenCameraManager.h"
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
@interface OpenCameraManager () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation OpenCameraManager
{
    UIViewController *_viewController;
    NSString *_nameString;
}
+ (instancetype)defaultCameraAudioManager
{
    static OpenCameraManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[OpenCameraManager alloc] init];
    });
    return _instance;
}
//判断文件的大小
- (long long) fileSizeAtPath:(NSString*) filePath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}
- (void)takeCameraAndAudioWithImageName:(NSString *)nameString WithViewController:(UIViewController *)viewController WithType:(NSString *)typeString
{
    _nameString = nameString;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.view.frame = viewController.view.bounds;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([typeString isEqualToString:@"camera"]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.mediaTypes =  [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    }
    else if ([typeString isEqualToString:@"audio"]) {
        picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
        picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [viewController presentViewController:picker animated:YES completion:nil];
    });
}

#pragma mark - UIImagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    //关闭相册界面
    [picker dismissViewControllerAnimated:YES completion:^{
        NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
        //        NSLog(@"type=%@",type);
        UIImage *image = nil;
        //当选择的类型是图片
        if ([type isEqualToString:@"public.image"])
        {
            image = [self getCompressImage:info[UIImagePickerControllerEditedImage]];
            
        }
        if (self.cameraAudioBlock) {
            self.cameraAudioBlock([NSString stringWithFormat:@"%@/%@", [self documentsPath], _nameString], image);
        }
    }];
}
//documents路径
- (NSString *)documentsPath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        if (self.cameraAudioBlock) {
            self.cameraAudioBlock(@"取消", nil);
        }
    }];
}

#pragma mark ==获取压缩的图片==
- (UIImage *)getCompressImage:(UIImage *)image
{
    NSData *data1;
    if (UIImagePNGRepresentation(image) == nil)
    {
        data1 = UIImageJPEGRepresentation(image, 0.5);
    }
    else
    {
        data1 = UIImagePNGRepresentation(image);
    }
    //图片保存的路径
    //这里将图片放在沙盒的documents文件夹中
    NSString * DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    //文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //把刚刚图片转换的data对象拷贝至沙盒中 并保存为image.png
    
    [fileManager createDirectoryAtPath:DocumentsPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createFileAtPath:[DocumentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@", _nameString]] contents:data1 attributes:nil];
    //得到选择后沙盒中图片的完整路径
    NSString *filePath = [[NSString alloc]initWithFormat:@"%@/%@",DocumentsPath, _nameString];
    //    NSLog(@"print file-->%@",filePath);
    
    long long abc = [self fileSizeAtPath:filePath];
//    NSLog(@"111->%lld", abc);
    
    if (abc < 204800) {
        return image;
    }
    else {
        UIImage *small = [self imageWithImageSimple:image scaledToSize:CGSizeMake(image.size.width/sqrt(abc/204800), image.size.height/sqrt(abc/204800))];
        NSData *data;
        if (UIImagePNGRepresentation(small) == nil)
        {
            data = UIImageJPEGRepresentation(small, 1);
        }
        else
        {
            data = UIImagePNGRepresentation(small);
        }
        //沙盒中图片的完整路径
        NSString *string1 = [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Documents/%@", _nameString]];
        NSFileManager *fileManage = [NSFileManager defaultManager];
        [fileManage removeItemAtPath:string1 error:nil];
        [fileManager createFileAtPath:[DocumentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@", _nameString]] contents:data attributes:nil];
//        abc = [self fileSizeAtPath:filePath];
//        NSLog(@"222->%lld", abc);
        return small;
    }
}
//压缩图片
- (UIImage*)imageWithImageSimple:(UIImage*)image scaledToSize:(CGSize)newSize
{
    // Create a graphics image context
    UIGraphicsBeginImageContext(newSize);
    // Tell the old image to draw in this new context, with the desired
    // new size
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    // End the context
    UIGraphicsEndImageContext();
    // Return the new image.
    return newImage;
}

@end
