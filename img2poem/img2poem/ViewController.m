//
//  ViewController.m
//  img2poem
//
//  Created by 周朗睿 on 2019/9/8.
//  Copyright © 2019 周朗睿. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking.h>

@interface ViewController ()
// 用于传递关键词的textfield
@property (weak, nonatomic) IBOutlet UITextField *setTextField;
// 显示结果的uilabel
@property (weak, nonatomic) IBOutlet UILabel *poemLabel;
// 传递图片的imgview
@property (weak, nonatomic) IBOutlet UIImageView *imgView;


@end

// 重写类方法，更改编码模式 Unicode->中文
@interface NSArray (Log)
@end

@interface NSDictionary (Log)
@end

@implementation NSArray (Log)
/// 打印数组和字典时会自动调用这个方法,在分类中重写这个方法时,在使用时不需要导入头文件
- (NSString *)descriptionWithLocale:(id)locale
{
    // 创建可变字符串
    NSMutableString *stringM = [NSMutableString string];
    // 拼接开头
    [stringM appendString:@"(\n"];
    // 遍历出元素,拼接中间的内容部分
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [stringM appendFormat:@"\t%@,\n",obj];
    }];
    // 拼接结尾
    [stringM appendString:@")\n"];
    return stringM;
}
@end

@implementation NSDictionary (Log)
- (NSString *)descriptionWithLocale:(id)locale
{
    // 创建可变字符串
    NSMutableString *stringM = [NSMutableString string];
    // 拼接开头
    [stringM appendString:@"{\n"];
    //  遍历出元素,拼接中间的内容部分
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [stringM appendFormat:@"\t%@ = %@;\n",key,obj];
    }];
    // 拼接结尾
    [stringM appendString:@"}\n"];
    
    return stringM;
}
@end



// 全局变量 生成诗歌项目的access token
NSString *poem_token = nil;
NSString *cc = nil;

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    [self getPoemAccessToken]; //获取poem的accesstoken
    //[self base64toimg];
}

// 通过拖线添加generateButton 点击该按钮可以根据setLabel中的关键词生成诗，并返回至getLabel
- (IBAction)generateButton:(id)sender {
    [self word2poem];
}

// 图像识别
- (IBAction)img:(id)sender {
    [self img2word];
}

// 获取access_token的方法
- (void)getPoemAccessToken{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //一但用了这个返回的那个responseObject就是NSData，如果不用就是简单的
    //manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html",@"image/jpeg",@"text/plain", nil];
    NSDictionary *dict = @{
                           @"grant_type":@"client_credentials",
                           //@"client_id":@"填写你的API Key",
                           @"client_id":@"XQ0RtMswC6Ll7hYDoNN1UDls",
                           //@"client_secret":@"填写你的Secret Key"
                           @"client_secret":@"vazlGzdbOzZ1fGk7Z3y1ccZBI4Guxx3y"
                           };
    [manager POST:@"https://aip.baidubce.com/oauth/2.0/token" parameters:dict progress:nil
success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
         NSDictionary *dict = (NSDictionary *)responseObject;
         
         NSString *accessToken = dict[@"access_token"];
         //d_accessToken = dict[@"access_token"];
         NSLog(@"accessToken请求成功%@",accessToken);
        poem_token = dict[@"access_token"];
 
     }
    failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
         NSLog(@"请求失败--%@",error);
     }];
}

// 图像识别
-(void)img2word{
    
    //1 创建会话管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // 设置请求头 header
    AFHTTPRequestSerializer *requestSerializer =  [AFHTTPRequestSerializer serializer];
    NSDictionary *headerFieldValueDictionary = @{@"Content-Type":@"application/x-www-form-urlencoded"};
    if (headerFieldValueDictionary != nil) {
        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
            NSString *value = headerFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    manager.requestSerializer = requestSerializer;
    
    NSString *code = [self img2base64];
    // 请求的url
    NSString *img_url = [NSString stringWithFormat:@"https://aip.baidubce.com/rest/2.0/image-classify/v1/plant?access_token=%@",poem_token];
    
    NSDictionary *paramDict = @{
                                @"image":code
                                };
    
    [manager POST:img_url parameters:paramDict progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"图像识别请求成功%@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"请求失败----%@", error);
    }];
}
// 关键词生成诗
-(void)word2poem{
    //1 创建会话管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // 设置请求头 header
    AFHTTPRequestSerializer *requestSerializer =  [AFJSONRequestSerializer serializer];
    NSDictionary *headerFieldValueDictionary = @{@"Content-Type":@"application/json"};
    if (headerFieldValueDictionary != nil) {
        for (NSString *httpHeaderField in headerFieldValueDictionary.allKeys) {
            NSString *value = headerFieldValueDictionary[httpHeaderField];
            [requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
    }
    manager.requestSerializer = requestSerializer;
    
    //2 发送post请求
    NSDictionary *paramDict = @{
                                @"text":_setTextField.text
                                };
    [manager POST:[NSString stringWithFormat:@"https://aip.baidubce.com/rpc/2.0/creation/v1/poem?access_token=%@",poem_token] parameters:paramDict progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"请求成功%@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"请求失败----%@", error);
    }];
}

// 获取base64的方法
-(NSString *)img2base64{
    //UIImage *originImage = [UIImage imageNamed:@"xiaoming.png"];
    
    NSData *imgData = UIImageJPEGRepresentation(self.imgView.image, 1.0f);
    
    NSString *encodedImageStr = [imgData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    //NSLog(@"base64 success%@",encodedImageStr);
    return encodedImageStr;
}


// 反向解码，检验img2base64是否奏效
-(void)base64toimg{
    NSData *decodedImageData = [[NSData alloc]initWithBase64EncodedString:[self img2base64] options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *decodedImage = [UIImage imageWithData:decodedImageData];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(60, 100, 200, 400)];
    [imgView setImage:decodedImage];
    [self.view addSubview:imgView];
    NSLog(@"decodedImage==%@",decodedImageData);
}


// 进行urlencode处理
- (NSString *)urlEncodeStr:(NSString *)input{
    NSCharacterSet *encode_set= [NSCharacterSet URLUserAllowedCharacterSet];
    NSString * nickname = [input stringByAddingPercentEncodingWithAllowedCharacters:encode_set];
    //return nickname;
    NSString * charaters = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| ";
    NSCharacterSet * set = [[NSCharacterSet characterSetWithCharactersInString:charaters] invertedSet];
    //NSString * hStr2 = @"这是一对小括号 ()<>[]{}";
    NSString * hString2 = [nickname stringByAddingPercentEncodingWithAllowedCharacters:set];
   // NSLog(@"hString2 ====== %@",hString2);
    return hString2;
}


@end



