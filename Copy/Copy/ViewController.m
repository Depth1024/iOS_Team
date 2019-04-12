//
//  ViewController.m
//  Copy
//
//  Created by 周朗睿 on 2019/4/10.
//  Copyright © 2019 周朗睿. All rights reserved.
//

#import "ViewController.h"
#import <AipOcrSdk/AipOcrSdk.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
// 将图片的剪切区域作为成员属性clipView
@property (nonatomic, weak) UIView *clipView;
// 增加成员属性startPoint用于记录手势开始的点
@property (nonatomic, assign) CGPoint startPoint;

@end

@implementation ViewController{
    // 默认的识别成功的回调
    void (^_successHandler)(id);
    // 默认的识别失败的回调
    void (^_failHandler)(NSError *);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    /**创建手势**/
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    /**
     *每当pan手势的位置发生变化，就会调用pan:方法，并将手势作为参数传递
     */
    /**添加手势**/
    [self.view addGestureRecognizer:pan];
}

//- (void)configCallback {
//    __weak typeof(self) weakSelf = self;
//
//    // 这是默认的识别成功的回调
//    _successHandler = ^(id result){
//        NSLog(@"%@", result);
//        NSString *title = @"识别结果";
//        NSMutableString *message = [NSMutableString string];
//
//        if(result[@"words_result"]){
//            if([result[@"words_result"] isKindOfClass:[NSDictionary class]]){
//                [result[@"words_result"] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//                    if([obj isKindOfClass:[NSDictionary class]] && [obj objectForKey:@"words"]){
//                        [message appendFormat:@"%@: %@\n", key, obj[@"words"]];
//                    }else{
//                        [message appendFormat:@"%@: %@\n", key, obj];
//                    }
//
//                }];
//            }else if([result[@"words_result"] isKindOfClass:[NSArray class]]){
//                for(NSDictionary *obj in result[@"words_result"]){
//                    if([obj isKindOfClass:[NSDictionary class]] && [obj objectForKey:@"words"]){
//                        [message appendFormat:@"%@\n", obj[@"words"]];
//                    }else{
//                        [message appendFormat:@"%@\n", obj];
//                    }
//
//                }
//            }
//
//        }else{
//            [message appendFormat:@"%@", result];
//        }
//
//        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:weakSelf cancelButtonTitle:@"确定" otherButtonTitles:nil];
//            [alertView show];
//        }];
//    };
//
//    _failHandler = ^(NSError *error){
//        NSLog(@"%@", error);
//        NSString *msg = [NSString stringWithFormat:@"%li:%@", (long)[error code], [error localizedDescription]];
//        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//            [[[UIAlertView alloc] initWithTitle:@"识别失败" message:msg delegate:weakSelf cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
//        }];
//    };
//}

// 懒加载，建立clipView
- (UIView *)clipView
{
    //如果clipView为被创建，就创建
    if (_clipView == nil)
    {
        UIView *view = [[UIView alloc] init];
        _clipView = view;
        //设置clipView的背景色和透明度
        view.backgroundColor = [UIColor blackColor];
        view.alpha = 0.5;
        //将clipView添加到控制器的view上，此时的clipView不会显示（未设置其frame）
        [self.view addSubview:_clipView];
    }
    return _clipView;
}

- (void)pan:(UIPanGestureRecognizer *)pan
{
    CGPoint endPoint = CGPointZero;
    
    if (pan.state == UIGestureRecognizerStateBegan)
    {
        /**开始点击时，记录手势的起点**/
        self.startPoint = [pan locationInView:self.view];
    }
    else if(pan.state == UIGestureRecognizerStateChanged)
    {
        /**当手势移动时，动态改变终点的值，并计算起点与终点之间的矩形区域**/
        endPoint = [pan locationInView:self.view];
        //计算矩形区域的宽高
        CGFloat w = endPoint.x - self.startPoint.x;
        CGFloat h = endPoint.y - self.startPoint.y;
        //计算矩形区域的frame
        CGRect clipRect = CGRectMake(self.startPoint.x, self.startPoint.y, w, h);
        //设置剪切区域的frame
        self.clipView.frame = clipRect;
    }
    else if(pan.state == UIGestureRecognizerStateEnded)
    {
        /**若手势停止，将剪切区域的图片内容绘制到图形上下文中**/
        //开启位图上下文
        UIGraphicsBeginImageContextWithOptions(self.imageView.bounds.size, NO, 0);
        //创建大小等于剪切区域大小的封闭路径
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.clipView.frame];
        //设置超出的内容不显示，
        [path addClip];
        //获取绘图上下文
        CGContextRef context = UIGraphicsGetCurrentContext();
        //将图片渲染的上下文中
        [self.imageView.layer renderInContext:context];
        //获取上下文中的图片
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        //关闭位图上下文
        UIGraphicsEndImageContext();
        //移除剪切区域视图控件，并清空
        [self.clipView removeFromSuperview];
        self.clipView = nil;
        //将图片显示到imageView上
        self.imageView.image = image;
        //        //通过alertView提示用户，是否将图片保存至相册
        //        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"保存图片" message:@"是否将图片保存至相册？" delegate:self cancelButtonTitle:@"否" otherButtonTitles:@"是", nil];
        //        [alertView show];
//        UIViewController * vc = [AipGeneralVC ViewControllerWithHandler:^(UIImage *image) {
//            NSDictionary *options = @{@"language_type": @"CHN_ENG", @"detect_direction": @"true"};
//            [[AipOcrService shardService] detectTextBasicFromImage:self.imageView.image
//                                                       withOptions:options
//                                                    successHandler:_successHandler
//                                                       failHandler:_failHandler];
//
//        }];
//        [self presentViewController:vc animated:YES completion:nil];

    }
}

//- (void)alertView:(nonnull UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    //若点击了“是”，则保存图片
//    if (buttonIndex == 1)
//    {
//        UIImageWriteToSavedPhotosAlbum(self.imageView.image, nil, nil, nil);
//        /**
//         * 该方法可以设置保存完毕调用的方法，此处未进行设置
//         */
//    }
//}

@end
