//
//  xcodeplugin.m
//  xcodeplugin
//
//  Created by Tim on 03/03/2015.
//  Copyright (c) 2015 Tim. All rights reserved.
//

#import "MultiEdit.h"

#import "MultiEditContext.h"

static xcodeplugin *sharedPlugin;

@interface xcodeplugin(){
    MultiEditContext *context;
}

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@end

@implementation xcodeplugin

// future todo:
// alcatraz
// settings panel
// readme

+ (void)pluginDidLoad:(NSBundle *)pluginBundle {
    
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    
    static dispatch_once_t onceToken;
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:pluginBundle]; // init once
        });
    }
}

+ (instancetype)sharedPlugin {
    return sharedPlugin;
}

-(id)initWithBundle:(NSBundle *)plugin{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

-(void)didApplicationFinishLaunchingNotification:(NSNotification*)notification{
    
    // Sample Menu Item:
    NSMenuItem *menuItem = [[[NSApplication sharedApplication] mainMenu] itemWithTitle:@"Edit"];
    
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        // if the user wants a custom keybinding, that might be tricky
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Do Action" action:@selector(doAction) keyEquivalent:@"d"];
        [actionMenuItem setTarget:self];
        [[menuItem submenu] addItem:actionMenuItem];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)doAction{
    
    if (!context) {
        IDEWorkspaceWindowController    *windowController = (IDEWorkspaceWindowController*)[[NSApp keyWindow] windowController];
        IDEEditorArea                   *editorArea = [windowController editorArea];
        IDEEditorContext                *editorAreaContext = [editorArea lastActiveEditorContext];
        id editor = [editorAreaContext editor];
        
        if (![[editor className] isEqualToString:@"IDESourceCodeEditor"]) { // if we're not looking at code, return
            return;
        }

        context = [[MultiEditContext alloc] initWithEditor:editor];
        [context setMainPlugin:self];
    } else {
        [context addNextRangeForStringRepeatingPage];
    }
}

-(void)finishedEditing{
    context = nil;
}

@end
