//
//  MultiEditContext.h
//  XcodeMultiEdit
//
//  Created by Timothy Edwards on 14/10/2015.
//  Copyright © 2015 Tim. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "MultiEdit.h"

@interface MultiEditContext : NSObject <NSTextFieldDelegate>

@property (nonatomic, readonly) BOOL isEditing;

@property (weak, nonatomic) xcodeplugin *mainPlugin;

-(instancetype)initWithEditor:(IDESourceCodeEditor*)editor;

-(void)addNextRangeForStringRepeatingPage;

@end
