//
//  ViewController.m
//  CameraTest2
//
//  Created by Yihe Li on 8/15/14.
//  Copyright (c) 2014 Self. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "PhotoProcessingViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "BetterButton.h"
#import "UIImage+TintColor.h"
#import "UIImage+Crop.h"

#define FLASH_MODE_OFF 0
#define FLASH_MODE_ON 1
#define FLASH_MODE_AUTO 2
#define FLASH_MODE_COUNT 3

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *frameForCapture;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (nonatomic, strong) NSNumber *flashMode;
@property (weak, nonatomic) IBOutlet BetterButton *selfieButton;
@property (weak, nonatomic) IBOutlet UIButton *libraryButton;

@end

#define ORIGINAL_MAX_WIDTH 640.0f

@implementation ViewController
{
    AVCaptureSession *session;
    AVCaptureStillImageOutput *stillImageOutput;
    CIFilter *filter;
    CIContext *context;
    BOOL front;
    AVCaptureVideoPreviewLayer *previewLayer;
}

- (void)setFlashMode:(NSNumber *)flashMode
{
	_flashMode = flashMode;
	[self.flashButton setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"Flash %@", flashMode]] forState:UIControlStateNormal];
}

#pragma mark - view controller life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    context = [CIContext contextWithOptions:nil];
    
    session = [[AVCaptureSession alloc]init];
    [session setSessionPreset:AVCaptureSessionPreset1280x720];
    
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    
    if ([session canAddInput:deviceInput]) {
        [session addInput:deviceInput];
    }
    
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    CGRect frame = self.frameForCapture.frame;
    
    [previewLayer setFrame:frame];
    
    [rootLayer insertSublayer:previewLayer above:0];
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey,nil];
    [stillImageOutput setOutputSettings:outputSettings];
    
    [session addOutput:stillImageOutput];
    [session startRunning];
	
	self.flashMode = @0;
    
    
    [self.libraryButton.layer setCornerRadius:4];
    [self.libraryButton.layer setBorderWidth:1];
    [self.libraryButton.layer setBorderColor:[UIColor colorWithWhite:1 alpha:0.3].CGColor];

    
    if ( [ALAssetsLibrary authorizationStatus] !=  ALAuthorizationStatusDenied ) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
        [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            
            // Within the group enumeration block, filter to enumerate just photos.
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            
            // Chooses the photo at the last index
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
                
                // The end of the enumeration is signaled by asset == nil.
                if (alAsset) {
                    ALAssetRepresentation *representation = [alAsset defaultRepresentation];
                    UIImage *latestPhoto = [UIImage imageWithCGImage:[representation fullScreenImage]];
                    
                    // Stop the enumerations
                    *stop = YES; *innerStop = YES;
                    
                    // Do something interesting with the AV asset.
                    UIImage *newImage = [self squareImageWithImage:latestPhoto scaledToSize:self.libraryButton.frame.size];
                    //newImage = [UIImage createRoundedRectImage:newImage size:newImage.size roundRadius:8];

                    [self.libraryButton setBackgroundImage:newImage forState:UIControlStateNormal];
                    self.libraryButton.clipsToBounds = YES;
                }
            }];
        } failureBlock: ^(NSError *error) {
            // Typically you should handle an error more gracefully than this.
            NSLog(@"No groups");
        }];
    }

}

- (UIImage *)squareImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    double ratio;
    double delta;
    CGPoint offset;
    
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.width);
    
    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize.width / image.size.width;
        delta = (ratio*image.size.width - ratio*image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.width / image.size.height;
        delta = (ratio*image.size.height - ratio*image.size.width);
        offset = CGPointMake(0, delta/2);
    }
    
    //make the final clipping rect based on the calculated values
    CGRect clipRect = CGRectMake(-offset.x, -offset.y,
                                 (ratio * image.size.width) + delta,
                                 (ratio * image.size.height) + delta);
    
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (IBAction)openLibrary:(UIButton *)sender
{
    if ([self isPhotoLibraryAvailable]) {
        UIImagePickerController *controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
        [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
        controller.mediaTypes = mediaTypes;
        controller.delegate = self;
        [self presentViewController:controller
                           animated:YES
                         completion:^(void){
                             NSLog(@"Picker View Controller is presented");
                         }];
    }

}

- (IBAction)toggleCamera:(id)sender
{
	AVCaptureDevicePosition desiredPosition;
	if (front) {
		desiredPosition = AVCaptureDevicePositionBack;
        [self.selfieButton setBackgroundImage:[UIImage imageNamed:@"flip"] forState:UIControlStateNormal];
    }
	else {
		desiredPosition = AVCaptureDevicePositionFront;
        [self.selfieButton setBackgroundImage:[[UIImage imageNamed:@"flip"] tintImageWithColor:[UIColor colorWithRed:255/255.0f green:212/255.0f blue:45/255.0f alpha:1.0f]] forState:UIControlStateNormal];
    }
	for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([d position] == desiredPosition) {
			[session beginConfiguration];
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
			for (AVCaptureInput *oldInput in [session inputs]) {
				[session removeInput:oldInput];
			}
			[session addInput:input];
			[session commitConfiguration];
			break;
		}
	}
    front = !front;
}

- (IBAction)shootPressed:(UIButton *)sender
{

    AVCaptureConnection *videoConnection = nil;
    
    for (AVCaptureConnection *connection in stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType]isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer != NULL) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            CIImage *image = [CIImage imageWithData:imageData];
            NSLog(@"%@",[image.properties valueForKey:(NSString *)kCGImagePropertyOrientation]);
                        CIImage* newImage = [image imageByApplyingTransform:CGAffineTransformMakeRotation(-M_PI/2.0f)];
            CGPoint origin = [newImage extent].origin;
            newImage = [newImage imageByApplyingTransform:CGAffineTransformMakeTranslation(-origin.x, -origin.y)];
            
            filter = [CIFilter filterWithName:@"CICrop"
                                keysAndValues:@"inputImage", newImage, @"inputRectangle",
                      [CIVector vectorWithX:0 Y:(newImage.extent.size.height - newImage.extent.size.width)/2 Z: newImage.extent.size.width W:  newImage.extent.size.width], nil];
            CIImage *croppedImage = [filter valueForKey:@"outputImage"];
            
            NSLog(@"%@",[croppedImage.properties valueForKey:(NSString *)kCGImagePropertyOrientation]);
            //[croppedImage.properties setValue:@1 forKey:(NSString *)kCGImagePropertyOrientation];
            UIView *view = [[UIView alloc] initWithFrame:self.view.frame];
            view.backgroundColor = [UIColor blackColor];
            view.alpha = 1;
            [self.view addSubview:view];
            [UIView animateWithDuration:0.3 animations:^{
                view.alpha = 0;
            } completion:^(BOOL finished) {
                [self performSegueWithIdentifier:@"Process Photo" sender:croppedImage];
            }];

            CIContext *softwareContext = [CIContext
                                          contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)} ];
            // 3
            CGImageRef cgImg = [softwareContext createCGImage:image
                                                     fromRect:[image extent]];
            // 4
            ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
            [library writeImageToSavedPhotosAlbum:cgImg
                                         metadata:[image properties]
                                  completionBlock:^(NSURL *assetURL, NSError *error) {
                                      // 5
                                      CGImageRelease(cgImg);
                                  }];
            

        }
    }];
}

- (IBAction)toggleFlash:(id)sender
{
	self.flashMode = @(([self.flashMode intValue] + 1) % 3);
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device hasFlash]) {
            [device lockForConfiguration:nil];

            switch ([self.flashMode intValue]) {
                case FLASH_MODE_ON:
                    if ([device isFlashModeSupported:AVCaptureFlashModeOn])
                        [device setFlashMode:AVCaptureFlashModeOn];
                    break;
                case FLASH_MODE_OFF:
                    if ([device isFlashModeSupported:AVCaptureFlashModeOff])
                        [device setFlashMode:AVCaptureFlashModeOff];
                    break;
                case FLASH_MODE_AUTO:
                    if ([device isFlashModeSupported:AVCaptureFlashModeAuto])
                        [device setFlashMode:AVCaptureFlashModeAuto];
            }
        }
        [device unlockForConfiguration];
        break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"Sender: %@",sender);
    if ([sender isKindOfClass:[CIImage class]]) {
        if ([segue.identifier isEqualToString:@"Process Photo"]) {
            NSLog(@"Oh Yeah");
            ((PhotoProcessingViewController *)segue.destinationViewController).image = (CIImage *)sender;
        }
    }
}

// callback when cropping finished
- (void)imageCropper:(VPImageCropperViewController *)cropperViewController didFinished:(UIImage *)editedImage
{
    CIImage *beginImage = [CIImage imageWithCGImage:editedImage.CGImage];

    [cropperViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self performSegueWithIdentifier:@"Process Photo" sender:beginImage];
    }];
}

// callback when cropping cancelled
- (void)imageCropperDidCancel:(VPImageCropperViewController *)cropperViewController
{
    [cropperViewController dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^() {
        UIImage *portraitImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        portraitImg = [self imageByScalingToMaxSize:portraitImg];
        // present the cropper view controller
        VPImageCropperViewController *imgCropperVC = [[VPImageCropperViewController alloc] initWithImage:portraitImg cropFrame:CGRectMake(0, 100.0f, self.view.frame.size.width, self.view.frame.size.width) limitScaleRatio:3.0];
        imgCropperVC.delegate = self;
        [self presentViewController:imgCropperVC animated:YES completion:^{
            // TO DO
        }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^(){
    }];
}

#pragma mark image scale utility
- (UIImage *)imageByScalingToMaxSize:(UIImage *)sourceImage {
    if (sourceImage.size.width < ORIGINAL_MAX_WIDTH) return sourceImage;
    CGFloat btWidth = 0.0f;
    CGFloat btHeight = 0.0f;
    if (sourceImage.size.width > sourceImage.size.height) {
        btHeight = ORIGINAL_MAX_WIDTH;
        btWidth = sourceImage.size.width * (ORIGINAL_MAX_WIDTH / sourceImage.size.height);
    } else {
        btWidth = ORIGINAL_MAX_WIDTH;
        btHeight = sourceImage.size.height * (ORIGINAL_MAX_WIDTH / sourceImage.size.width);
    }
    CGSize targetSize = CGSizeMake(btWidth, btHeight);
    return [self imageByScalingAndCroppingForSourceImage:sourceImage targetSize:targetSize];
}

- (UIImage *)imageByScalingAndCroppingForSourceImage:(UIImage *)sourceImage targetSize:(CGSize)targetSize {
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
    }
    UIGraphicsBeginImageContext(targetSize); // this will crop
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) NSLog(@"could not scale image");
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark camera utility
- (BOOL) isCameraAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL) isRearCameraAvailable{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (BOOL) isFrontCameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

- (BOOL) doesCameraSupportTakingPhotos {
    return [self cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL) isPhotoLibraryAvailable{
    return [UIImagePickerController isSourceTypeAvailable:
            UIImagePickerControllerSourceTypePhotoLibrary];
}
- (BOOL) canUserPickVideosFromPhotoLibrary{
    return [self
            cameraSupportsMedia:(__bridge NSString *)kUTTypeMovie sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}
- (BOOL) canUserPickPhotosFromPhotoLibrary{
    return [self
            cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL) cameraSupportsMedia:(NSString *)paramMediaType sourceType:(UIImagePickerControllerSourceType)paramSourceType{
    __block BOOL result = NO;
    if ([paramMediaType length] == 0) {
        return NO;
    }
    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    [availableMediaTypes enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *mediaType = (NSString *)obj;
        if ([mediaType isEqualToString:paramMediaType]){
            result = YES;
            *stop= YES;
        }
    }];
    return result;
}

@end
