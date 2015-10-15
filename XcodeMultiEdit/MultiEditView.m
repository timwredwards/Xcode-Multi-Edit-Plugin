//
//  RangeEditView.m
//  xcodeplugin
//
//  Created by Timothy Edwards on 12/10/2015.
//  Copyright © 2015 Tim. All rights reserved.
//

#import "MultiEditView.h"

@implementation MultiEditView

-(instancetype)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    [self setWantsLayer:YES];
    
    CGColorRef bgColor = CGColorCreateGenericGray(0.5, 0.3);
    [self.layer setBackgroundColor:bgColor];
    CGColorRelease(bgColor);
    
    CGColorRef borderColor = CGColorCreateGenericGray(0.0, 1.0);
    [self.layer setBorderColor:borderColor];
    CGColorRelease(borderColor);

    [self.layer setBorderWidth:1.0];
    [self.layer setCornerRadius:2.0];
    return self;
}

@end
