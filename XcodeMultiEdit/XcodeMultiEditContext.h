//
//  XcodeMultiEditContext.h
//  XcodeMultiEdit
//
//  Created by Timothy Edwards on 14/10/2015.
//  Copyright © 2015 Tim. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "XCFXcodePrivate.h"

@interface XcodeMultiEditContext : NSObject <NSTextFieldDelegate>

-(instancetype)initWithEditor:(IDESourceCodeEditor*)editor;

-(void)addNextRangeForStringRepeatingPage;

@end
