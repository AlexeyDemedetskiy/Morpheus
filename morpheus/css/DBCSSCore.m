//
//  DBCSSCore.m
//  morpheus
//
//  Created by Andrey Moskvin on 01.07.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DBCSSCore.h"
#import "DBViewRepository.h"
#import "DBCSSCache.h"
#import "DBCSSParser.h"
#import "DBStyleApplicator.h"
#import "DBStylesheet.h"
#import "DBFileGuard.h"
#import "DBFileGuardWorkspaceConstant.h"
#import "UIView+Repository.h"

@interface DBCSSCore () <DBFileGuardProtocol>

@property (nonatomic, readonly) DBViewRepository* viewRepository;
@property (nonatomic, readonly) DBCSSCache* styleCache;
@property (nonatomic, readonly) DBCSSParser* parser;
@property (nonatomic, readonly) DBStyleApplicator* applicator;
@property (nonatomic, readonly) DBFileGuard* guard;
@property (nonatomic, readonly) NSBundle* styleBundle;

@end

@implementation DBCSSCore

@synthesize viewRepository = _repository;
@synthesize styleCache = _styleCache;
@synthesize parser = _parser;
@synthesize applicator = _applicator;

@synthesize guard = _guard;
@synthesize styleBundle = _styleBundle;

+ (id)sharedCore
{
    static DBCSSCore* core;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        core = [DBCSSCore new];
    });
    
    return core;
}

- (void)start
{
    [self updateStylesFromBundle:self.styleBundle];
    [self.viewRepository addListener:self];
}

- (void)viewRepositoryDidAddView:(NSNotification*)n
{
    UIView* view = [n.userInfo objectForKey:@"view"];
    
    NSMutableSet* styles = [NSMutableSet set];
    
    [styles unionSet:[self.styleCache stylesForClasses:view.classes]];
    [styles unionSet:[self.styleCache stylesForIdentifier:view.identifier]];
    [styles unionSet:[self.styleCache stylesForType:NSStringFromClass(view.class)]];

    for (DBStylesheet* style in styles) 
    {
        [self.applicator applyStyle:style toView:view];
    }
}

- (id)init
{
    self = [super init];
    if (self) 
    {
        _repository = [DBViewRepository sharedRepository];
        _styleCache = [DBCSSCache new];
        _parser = [DBCSSParser new];
        _applicator = [DBStyleApplicator new];
        _styleBundle = [self selectBundle];

        [self updateStylesFromBundle:self.styleBundle];                           
    }
    return self;
}

- (NSBundle*)selectBundle
{
    NSBundle* result;
    if (TARGET_IPHONE_SIMULATOR) 
    {
        result = [NSBundle bundleWithPath:kDB_WORKSPACE_DEFAULT_PATH_KEY];
        _guard = [DBFileGuard fileGuardWithBundlePath:kDB_WORKSPACE_DEFAULT_PATH_KEY];
        _guard.delegate = self;
    }
    else 
    {
        NSString* path = [[NSBundle mainBundle] pathForResource:@"stylesheets" ofType:@"bundle"];
        result = [NSBundle bundleWithPath:path];
    }
    
    NSAssert(result != nil, @"Cannot load stylesheet bundle");
    return result;
}

- (void)updateStylesFromBundle:(NSBundle*)bundle
{
    [self.styleCache resetCache];
    NSArray* paths = [bundle pathsForResourcesOfType:@"css" inDirectory:nil];
    for (NSString* cssPath in paths) 
    {
        NSString* css = [NSString stringWithContentsOfFile:cssPath 
                                                  encoding:NSUTF8StringEncoding 
                                                     error:nil];
        NSArray* sheets = [self.parser parseStylesheet:css];
        
        [self.styleCache importStyleshhets:sheets];
    }
    
    [self applyAllStyles];
}

- (NSSet*)viewsForSelector:(NSString*)selector type:(enum DBCSSSelectorType)type
{
    switch (type) {
        case DBCSSSelectorType_Id: return [self.viewRepository viewsForIdentifier:selector];
        case DBCSSSelectorType_Class: return [self.viewRepository viewsForClass:selector];
        case DBCSSSelectorType_Type: return [self.viewRepository viewsForType:selector];
            
        default:    
            break;
    }
    return nil;
}

- (void)applyAllStyles
{
    NSSet* styles = [self.styleCache allStyles];
    for (DBStylesheet* style in styles) 
    {
        NSSet* views = [self viewsForSelector:style.selector 
                                         type:style.selectorType];
        [self applyStyle:style toViews:views];
    }
}

- (void)applyStyle:(DBStylesheet*)style toViews:(NSSet*)views
{
    for (UIView* view in views)
    {
        [self.applicator applyStyle:style toView:view];
    }
}

#pragma mark - DBFileGuardProtocol

-(void)fileGuardDidChangedFileInBundle:(DBFileGuard *)fileGuard
{
    [self updateStylesFromBundle:self.styleBundle];
}

@end
