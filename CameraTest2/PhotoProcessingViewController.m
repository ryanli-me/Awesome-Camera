//
//  PhotoProcessingViewController.m
//  CameraTest2
//
//  Created by Yihe Li on 8/15/14.
//  Copyright (c) 2014 Self. All rights reserved.
//

#import "PhotoProcessingViewController.h"

@interface PhotoProcessingViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scroller;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *filterButtons;
@property (strong, nonatomic) NSArray *filters; // of filters

@end

@implementation PhotoProcessingViewController
{
    CIFilter *filter;
    CIContext *context;
}

- (NSArray *)filters
{
    if (!_filters)
        _filters = @[[CIFilter filterWithName:@"CISepiaTone" keysAndValues:kCIInputImageKey, self.image, @"inputIntensity", @0.8, nil], [CIFilter filterWithName:@"CIPhotoEffectMono" keysAndValues:kCIInputImageKey,self.image,nil], [CIFilter filterWithName:@"CIPhotoEffectTonal" keysAndValues:kCIInputImageKey,self.image,nil], [CIFilter filterWithName:@"CIPhotoEffectNoir" keysAndValues:kCIInputImageKey,self.image,nil], [CIFilter filterWithName:@"CIPhotoEffectFade" keysAndValues:kCIInputImageKey,self.image,nil], [CIFilter filterWithName:@"CIPhotoEffectChrome" keysAndValues:kCIInputImageKey,self.image,nil], [CIFilter filterWithName:@"CIPhotoEffectProcess" keysAndValues:kCIInputImageKey,self.image,nil], [CIFilter filterWithName:@"CIPhotoEffectTransfer" keysAndValues:kCIInputImageKey,self.image,nil], [CIFilter filterWithName:@"CIPhotoEffectInstant" keysAndValues:kCIInputImageKey,self.image,nil], [CIFilter filterWithName:@"SimpleCustom" keysAndValues:kCIInputImageKey,self.image, nil], [CIFilter filterWithName:@"OldeFilm" keysAndValues:kCIInputImageKey,self.image, nil],[CIFilter filterWithName:@"PixellatedPeople" keysAndValues:kCIInputImageKey, self.image, nil]];
    return _filters;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    context = [CIContext contextWithOptions:nil];
    
    filter = nil;
    
    [self.scroller setScrollEnabled:YES];
    [self.scroller setContentSize:CGSizeMake(795, 182)];
    for (UIButton *button in self.filterButtons) {
        [button addTarget:self action:@selector(updateFilter:) forControlEvents:UIControlEventTouchUpInside];
    }
    // Do any additional setup after loading the view.
}

- (void)updateFilter:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        filter = self.filters[((UIButton *)sender).tag-1];
    }
    CIImage *outputImage = [filter outputImage];
    
    CGImageRef cgimg = [context createCGImage:outputImage
                                     fromRect:[outputImage extent]];
    
    UIImage *newImage = [UIImage imageWithCGImage:cgimg];
    self.imageView.image = newImage;
    
    CGImageRelease(cgimg);

}

- (void)viewWillAppear:(BOOL)animated
{
    self.imageView.image = [UIImage imageWithCIImage: self.image];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)retakePressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}



@end
