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
    [self.layer setBackgroundColor:CGColorCreateGenericGray(0.5, 0.3)];
    [self.layer setBorderColor:CGColorCreateGenericGray(0.0, 1.0)];
    [self.layer setBorderWidth:1.0];
    [self.layer setCornerRadius:2.0];
    return self;
}

@end
