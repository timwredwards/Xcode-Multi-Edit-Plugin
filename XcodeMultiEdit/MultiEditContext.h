//
//  MultiEditContext.h
//  XcodeMultiEdit
//
//  Created by Timothy Edwards on 14/10/2015.
//  Copyright © 2015 Tim. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "XCPrivateMethods.h"

@interface MultiEditContext : NSObject <NSTextFieldDelegate>

-(instancetype)initWithEditor:(IDESourceCodeEditor*)editor;

-(void)addNextOccurrence; // returns wrapped NSRange of new occurence
-(void)removeLastOccurrence;
-(void)skipNextOccurrence;

@end