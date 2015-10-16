//
//  MultiEditContext.m
//  XcodeMultiEdit
//
//  Created by Timothy Edwards on 14/10/2015.
//  Copyright © 2015 Tim. All rights reserved.
//

#import "MultiEditContext.h"

#import "MultiEditView.h"

@interface MultiEditContext (){
    NSTextView *mainTextView;
    IDESourceCodeDocument *mainDocument;
    DVTSourceTextStorage *mainTextStorage;
    
    NSMutableArray *editViewsBeforeSelected;
    NSMutableArray *editViewsAfterSelected;
    NSString *selectedString;
    NSRange selectedRange;
    NSView *containerView;
    NSTextField *textField;
}

@end

@implementation MultiEditContext

-(instancetype)initWithEditor:(IDESourceCodeEditor *)editor{
    self = [super init];
    if (self) {
        mainTextView = [editor textView];
        mainDocument = [editor sourceCodeDocument];
        mainTextStorage = [editor sourceCodeDocument].textStorage;
        
        editViewsBeforeSelected = [[NSMutableArray alloc] init];
        editViewsAfterSelected = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)setupFirstOccurence{
    selectedString = [mainTextView.string substringWithRange:mainTextView.selectedRange];
    selectedRange = mainTextView.selectedRange;
    [self createTextFieldViewForStringRange:selectedRange];
    [mainTextView setEditable:NO];
}

-(void)addNextOccurrence{
    
    if ((editViewsBeforeSelected.count==0) && (editViewsAfterSelected.count==0)) {
        [self setupFirstOccurence];
    }
    
    if (![textField.stringValue isEqualToString:selectedString]) { // if started editing text, no more selecting occurences
        NSBeep();
        return;
    }
    
    NSRange latestRange; // last range to be added
    
    BOOL loopedAround = NO; // are we looped to the beginning of the document
    
    if (editViewsBeforeSelected.count>0) {
        latestRange = [[editViewsBeforeSelected lastObject] presentedRange];
        loopedAround = YES;
    } else if (editViewsAfterSelected.count>0){
        latestRange = [[editViewsAfterSelected lastObject] presentedRange];
    } else { // havn't got any saved ranges yet
        latestRange = selectedRange;
    }
    
    NSUInteger locationOfSearchRange = latestRange.location+latestRange.length;
    NSUInteger lengthOfSearchRange;
    
    if (loopedAround) { // if we're looped around to the beginning of the document
        lengthOfSearchRange = selectedRange.location-locationOfSearchRange;
    } else { // else we're still on the first read-through
        lengthOfSearchRange = mainTextView.string.length - locationOfSearchRange;
    }
    
    NSRange rangeToSearch = NSMakeRange(locationOfSearchRange, lengthOfSearchRange);
    
    // the search
    NSRange newRange = [mainTextView.string rangeOfString:selectedString options:0 range:rangeToSearch];
    
    BOOL foundResult = NO;
    if (newRange.location != NSNotFound) { // if a range is found, use it.
        foundResult = YES;
        [self createEditViewForStringRange:newRange];
    } else {
        if (!loopedAround) { // so we only loop around once
            NSRange rangeLoopedAround = NSMakeRange(0, selectedRange.location); // from beginning of document
            newRange = [mainTextView.string rangeOfString:selectedString options:0 range:rangeLoopedAround];
            if (newRange.location != NSNotFound) { // to selected range
                foundResult = YES;
                [self createEditViewForStringRange:newRange];
            }
        }
    }
    if (!foundResult) {
        NSBeep();
    }
}

-(void)removeLastOccurrence{
    if (editViewsBeforeSelected.count>0){
        [mainTextView scrollRangeToVisible:[editViewsBeforeSelected.lastObject presentedRange]];
        [editViewsBeforeSelected.lastObject removeFromSuperview];
        [editViewsBeforeSelected removeLastObject];
    } else if(editViewsAfterSelected.count>0){
        [mainTextView scrollRangeToVisible:[editViewsAfterSelected.lastObject presentedRange]];
        [editViewsAfterSelected.lastObject removeFromSuperview];
        [editViewsAfterSelected removeLastObject];
    }
    if ((editViewsBeforeSelected.count==0) && (editViewsAfterSelected.count==0)) {
        [self enterKeyPressed]; // no more views to remove
    }
}

-(void)skipNextOccurrence{
    MultiEditView *viewToSkip;
    [self addNextOccurrence];
    if (editViewsBeforeSelected.count>0) { // get last view added
        viewToSkip = editViewsBeforeSelected.lastObject;
    } else viewToSkip = editViewsAfterSelected.lastObject;
    [self addNextOccurrence];
    [editViewsBeforeSelected removeObject:viewToSkip];
    [editViewsAfterSelected removeObject:viewToSkip];
    [viewToSkip removeFromSuperview];
}

-(void)createEditViewForStringRange:(NSRange)range{
    // currently using NSViews but perhaps should be editing the NSAttributedString's background color
    NSRect rangeRect = [[mainTextView layoutManager] boundingRectForGlyphRange:range inTextContainer:mainTextView.textContainer];
    MultiEditView *editView = [[MultiEditView alloc] initWithFrame:rangeRect];
    [editView setPresentedRange:range];
    [mainTextView addSubview:editView];
    if ((range.location+range.length)<selectedRange.location) {
        [editViewsBeforeSelected addObject:editView];
    } else {
        [editViewsAfterSelected addObject:editView];
    }
    [mainTextView scrollRangeToVisible:range];
}

-(void)createTextFieldViewForStringRange:(NSRange)range{
    
    // maybe worth subclassing NSTextView
    NSRect rangeRect = [[mainTextView layoutManager] boundingRectForGlyphRange:range inTextContainer:mainTextView.textContainer];
    
    containerView = [[NSView alloc] initWithFrame:rangeRect];
    [containerView setWantsLayer:YES];
    
    CGColorRef bgColor = CGColorCreateGenericGray(1.0, 1.0);
    [containerView.layer setBackgroundColor:bgColor];
    CGColorRelease(bgColor);
    
    CGColorRef borderColor = CGColorCreateGenericGray(0.0, 1.0);
    [containerView.layer setBorderColor:borderColor];
    CGColorRelease(borderColor);
    
    [containerView.layer setBorderWidth:1.0];
    [containerView.layer setCornerRadius:2.0];
    [mainTextView addSubview:containerView];
    
    textField = [[NSTextField alloc] init];
    [textField setStringValue:selectedString];
    [textField setFont:mainTextView.font];
    [textField setBezeled:NO];
    [textField setDrawsBackground:NO];
    [textField setUsesSingleLineMode:YES];
    
    [textField sizeToFit];
    CGRect textFrame = CGRectMake(-2, -1, textField.frame.size.width, textField.frame.size.height);
    [textField setFrame:NSRectFromCGRect(textFrame)];
    
    [containerView addSubview:textField];
    [textField setDelegate:self];
    [[NSApp mainWindow] makeFirstResponder:textField];
    
    [textField setTarget:self];
    [textField setAction:@selector(enterKeyPressed)];

}

-(void)controlTextDidChange:(NSNotification *)obj{
    
    [textField setStringValue:textField.stringValue];
    if (![textField.stringValue hasSuffix:@" "]) {
        [textField sizeToFit]; // sizeToFit screws up with spaces for some reason
    }
    [containerView setFrame:NSRectFromCGRect(CGRectMake(containerView.frame.origin.x,
                                                        containerView.frame.origin.y,
                                                        textField.frame.size.width,
                                                        containerView.frame.size.height))];
    
    // views for before selected range
    [editViewsBeforeSelected enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        int locationOffset = (int)textField.stringValue.length - (int)selectedString.length;
        locationOffset = locationOffset * (int)idx;
        NSRange rangeToEdit = NSMakeRange([obj presentedRange].location+locationOffset, [obj presentedRange].length);
        [mainTextStorage replaceCharactersInRange:rangeToEdit withString:textField.stringValue withUndoManager:mainDocument.undoManager];
        [obj setPresentedRange:NSMakeRange([obj presentedRange].location, textField.stringValue.length)];
        NSRect rangeRect = [[mainTextView layoutManager] boundingRectForGlyphRange:rangeToEdit inTextContainer:mainTextView.textContainer];
        [obj setFrame:NSRectFromCGRect(CGRectMake(rangeRect.origin.x, rangeRect.origin.y, containerView.frame.size.width, containerView.frame.size.height))];
    }];
    
    // calculate new range for edit box
    int locationOffset = (int)textField.stringValue.length - (int)selectedString.length;
    locationOffset = locationOffset * (int)editViewsBeforeSelected.count;
    NSRange rangeToEdit = NSMakeRange(selectedRange.location+locationOffset, selectedRange.length);
    [mainTextStorage replaceCharactersInRange:rangeToEdit withString:textField.stringValue withUndoManager:mainDocument.undoManager];
    selectedRange = NSMakeRange(selectedRange.location, textField.stringValue.length);
    
    // views for after selected range
    [editViewsAfterSelected enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        int locationOffset = (int)textField.stringValue.length - (int)selectedString.length;
        locationOffset = locationOffset * ((int)idx+(int)editViewsBeforeSelected.count+1);
        NSRange rangeToEdit = NSMakeRange([obj presentedRange].location+locationOffset, [obj presentedRange].length);
        [mainTextStorage replaceCharactersInRange:rangeToEdit withString:textField.stringValue withUndoManager:mainDocument.undoManager];
        [obj setPresentedRange:NSMakeRange([obj presentedRange].location, textField.stringValue.length)];
        
        NSRect rangeRect = [[mainTextView layoutManager] boundingRectForGlyphRange:rangeToEdit inTextContainer:mainTextView.textContainer];
        [obj setFrame:NSRectFromCGRect(CGRectMake(rangeRect.origin.x, rangeRect.origin.y, containerView.frame.size.width, containerView.frame.size.height))];
    }];
}

-(void)controlTextDidEndEditing:(NSNotification *)obj {
    [self stopMultiEdit];
}

-(void)enterKeyPressed{
    [self stopMultiEdit];
}

-(void)stopMultiEdit{
    [editViewsBeforeSelected enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [editViewsAfterSelected enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [editViewsBeforeSelected removeAllObjects];
    [editViewsAfterSelected removeAllObjects];
    [textField removeFromSuperview];
    [containerView removeFromSuperview];
    [mainTextView setEditable:YES];
    [[NSApp mainWindow] makeFirstResponder:mainTextView];
}

@end
