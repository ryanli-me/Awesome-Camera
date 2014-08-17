//
//  SimpleCustom.m
//  CIFunHouse
//
//  Created by Yihe Li on 8/15/14.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <CoreImage/CoreImage.h>
#else
#import <QuartzCore/QuartzCore.h>
#endif

@interface SimpleCustom : CIFilter
{
    CIImage *inputImage;
}
@property (retain, nonatomic) CIImage *inputImage;
@end


@implementation SimpleCustom

@synthesize inputImage;

- (CIImage *)outputImage
{
    CIImage *output = [CIFilter filterWithName:@"CISepiaTone" keysAndValues:kCIInputImageKey, inputImage, @"inputIntensity", @0.8, nil].outputImage;
    output = [CIFilter filterWithName:@"CIHueAdjust" keysAndValues:kCIInputImageKey, output, @"inputAngle", @0.8, nil].outputImage;
    return output;
}
@end
