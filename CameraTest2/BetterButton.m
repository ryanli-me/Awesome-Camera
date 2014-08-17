//
//  BetterButton.m
//  SketchOff
//
//  Created by Frank Luan on 7/5/14.
//  Copyright (c) 2014 SketchOff. All rights reserved.
//

#include "BetterButton.h"

@implementation BetterButton

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (UIEdgeInsetsEqualToEdgeInsets(self.hitTestEdgeInsets, UIEdgeInsetsZero) || !self.enabled || self.hidden) {
        return [super hitTest:point withEvent:event];
    }
    // The point that is being tested is relative to self, so remove origin
    CGRect relativeFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, self.hitTestEdgeInsets);
    if (CGRectContainsPoint(hitFrame, point)) {
        return self;
    }
    return nil;
}

@end
