//
//  xcodeplugin.m
//  xcodeplugin
//
//  Created by Tim on 03/03/2015.
//  Copyright (c) 2015 Tim. All rights reserved.
//

#import "MultiEdit.h"

#import <objc/runtime.h>

static xcodeplugin *sharedPlugin;

@interface xcodeplugin(){
    NSMenu *multiEditSubmenu;
}

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@end

static int kMultiEditContextKey;

@implementation xcodeplugin

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
    NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
    
    if (editMenuItem) {
        [editMenuItem.submenu addItem:[NSMenuItem separatorItem]];
        
        multiEditSubmenu = [[NSMenu alloc] init];
        NSMenuItem *multiEditMenuItem = [[NSMenuItem alloc] initWithTitle:@"MultiEdit" action:nil keyEquivalent:@""];
        
        [editMenuItem.submenu addItem:multiEditMenuItem];
        [multiEditMenuItem setSubmenu:multiEditSubmenu];
        
        // if the user wants a custom keybinding, that might be tricky
        NSMenuItem *editNextMenuItem = [[NSMenuItem alloc] initWithTitle:@"Select Next" action:@selector(editNextItem) keyEquivalent:@""];
        [editNextMenuItem setTarget:self];
        [multiEditSubmenu addItem:editNextMenuItem];
        
        NSMenuItem *undoLastMenuItem = [[NSMenuItem alloc] initWithTitle:@"Undo Last Selection" action:@selector(undoLastSelection) keyEquivalent:@""];
        [undoLastMenuItem setTarget:self];
        [multiEditSubmenu addItem:undoLastMenuItem];
        
        NSMenuItem *skipNextMenuItem = [[NSMenuItem alloc] initWithTitle:@"Skip Last Selection" action:@selector(skipLastSelection) keyEquivalent:@""];
        [skipNextMenuItem setTarget:self];
        [multiEditSubmenu addItem:skipNextMenuItem];
        
//        NSMenuItem *settingsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Settings" action:@selector(settingsItem) keyEquivalent:@""];
//        [settingsMenuItem setTarget:self];
//        [multiEditSubmenu addItem:settingsMenuItem];
        
        [self setSubmenuKeyEquivalents];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setSubmenuKeyEquivalents{
    [[multiEditSubmenu itemAtIndex:0] setKeyEquivalent:@"a"];
    [[multiEditSubmenu itemAtIndex:0] setKeyEquivalentModifierMask:NSShiftKeyMask | NSAlternateKeyMask];
    
    [[multiEditSubmenu itemAtIndex:1] setKeyEquivalent:@"z"];
    [[multiEditSubmenu itemAtIndex:1] setKeyEquivalentModifierMask:NSShiftKeyMask | NSAlternateKeyMask];
    
    [[multiEditSubmenu itemAtIndex:2] setKeyEquivalent:@"s"];
    [[multiEditSubmenu itemAtIndex:2] setKeyEquivalentModifierMask:NSShiftKeyMask | NSAlternateKeyMask];
}

-(void)editNextItem{
    MultiEditContext *context = [self getCurrentContext];
    if (context) {
        [context addNextOccurrence];
    }
}

-(void)undoLastSelection{
    MultiEditContext *context = [self getCurrentContext];
    if (context) {
        [context removeLastOccurrence];
    }
}

-(void)skipLastSelection{
    MultiEditContext *context = [self getCurrentContext];
    if (context) {
        [context skipNextOccurrence];
    }
}

-(MultiEditContext*)getCurrentContext{
    @try{ // trying to access some private methods if not in a source code editor causes an exception
        IDEWorkspaceWindowController    *windowController = (IDEWorkspaceWindowController*)[[NSApp keyWindow] windowController];
        IDEEditorArea                   *editorArea = [windowController editorArea];
        IDEEditorContext                *editorAreaContext = [editorArea lastActiveEditorContext];
        IDESourceCodeEditor             *editor = [editorAreaContext editor];
        if (![[editor className] isEqualToString:@"IDESourceCodeEditor"]) {
            @throw[NSException exceptionWithName:@"Wrong Editor" reason:@"Not inside IDESourceCodeEditor" userInfo:nil];
        }
        
        MultiEditContext *context = objc_getAssociatedObject(editor, &kMultiEditContextKey); // get context from this editor
        
        if (!context) { // if no context exists inside this editor
            context = [[MultiEditContext alloc] initWithEditor:editor];
            objc_setAssociatedObject(editor, &kMultiEditContextKey, context, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return context;
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        return nil;
    }
}

//-(void)settingsItem{
//    NSWindow *window = [[NSPanel alloc] initWithContentRect:NSRectFromCGRect(CGRectMake(0, 0, 200, 200))
//                                                  styleMask:NSTitledWindowMask
//                                                    backing:NSBackingStoreBuffered
//                                                      defer:NO];
//    [[NSApp mainWindow] beginSheet:window completionHandler:nil];
//}
@end
