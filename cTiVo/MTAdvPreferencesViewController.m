//
//  MTAdvPreferencesViewController.m
//  cTiVo
//
//  Created by Hugh Mackworth on 2/7/13.
//  Copyright (c) 2013 Scott Buchanan. All rights reserved.
//

#import "MTAdvPreferencesViewController.h"
#import "DDLog.h"
#import "MTTiVoManager.h"

#define tiVoManager [MTTiVoManager sharedTiVoManager]

@interface MTAdvPreferencesViewController ()
@property (nonatomic, strong) NSArray * debugClasses;   //all classes registered with DDLog (including autogenerated)
@property (nonatomic, strong) NSMutableArray * classNames; //all class names that are actually displayed
@property (nonatomic, strong) NSMutableArray * popups;
@end

@implementation MTAdvPreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
	
    return self;
}

-(IBAction)selectTmpDir:(id)sender
{
	NSOpenPanel *myOpenPanel = [[NSOpenPanel alloc] init];
	myOpenPanel.canChooseFiles = NO;
	myOpenPanel.canChooseDirectories = YES;
	myOpenPanel.canCreateDirectories = YES;
	myOpenPanel.prompt = @"Choose";
	myOpenPanel.directoryURL = [NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] objectForKey:kMTTmpFilesDirectory]];
	[myOpenPanel setTitle:@"Select Temp Directory for Files"];
	[myOpenPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger ret){
		if (ret == NSFileHandlingPanelOKButton) {
			NSString *directoryName = myOpenPanel.URL.path;
			[[NSUserDefaults standardUserDefaults] setObject:directoryName forKey:kMTTmpFilesDirectory];
		}
		[myOpenPanel close];
	}];
	
}


-(NSTextField *) newTextField: (NSRect) frame {
	NSTextField *textField;
	
    textField = [[NSTextField alloc] initWithFrame:frame];
    [textField setBezeled:NO];
    [textField setDrawsBackground:NO];
    [textField setEditable:NO];
    [textField setSelectable:NO];
	[textField setAlignment: NSRightTextAlignment ];
	[textField setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	[textField setAutoresizingMask: NSViewMinXMargin | NSViewWidthSizable | NSViewMaxXMargin | NSViewMinYMargin | NSViewHeightSizable | NSViewMaxYMargin];
	return textField;
}

-(void) addMenuTo:(NSPopUpButton*) cell withCurrentLevel: (NSInteger) currentLevel{

	NSArray * debugNames = @[@"None",@"Normal" ,@"Major" ,@"Detail" , @"Verbose"];
	int debugLevels[] = {LOG_LEVEL_OFF, LOG_LEVEL_REPORT, LOG_LEVEL_MAJOR, LOG_LEVEL_DETAIL, LOG_LEVEL_VERBOSE};

	[cell addItemsWithTitles: debugNames];
	for (int index = 0; index < cell.numberOfItems; index++) {
		//	for (NSMenuItem * item in [cell itemArray]) {
		NSMenuItem * menu = [cell itemAtIndex:index];
		menu.tag = debugLevels[index];
		if (menu.tag == currentLevel) {
			[cell selectItem:menu];
		}
	}
}

-(void) resetAllPopups: (int) newVal {
}

-(void) awakeFromNib {
	
	[self addMenuTo:self.masterDebugLevel withCurrentLevel:[[NSUserDefaults standardUserDefaults] integerForKey:kMTDebugLevel]];

	self.debugClasses = [DDLog registeredClasses] ;
	self.popups= [NSMutableArray arrayWithCapacity:self.debugClasses.count ];
	self.classNames = [NSMutableArray arrayWithCapacity:self.debugClasses.count];
	for (Class class in self.debugClasses) {
		NSString * className =  NSStringFromClass(class);
		if ([className hasPrefix:@"NSKVONotifying"]) continue;
		[self.classNames addObject:className];
	}
	[self.classNames sortUsingSelector:  @selector(localizedCaseInsensitiveCompare:)];
	
	int numItems = (int)[self.classNames count];
	int itemNum = 0;
	for (NSString * className in self.classNames) {
		Class class =  NSClassFromString(className);
		const int vertBase = self.debugLevelView.frame.size.height-40;
		const int labelWidth = 150;
		const int popupHeight = 25;
		const int popupWidth = 80;
		const int vertMargin = 5;
		const int horizMargin = 10;
		const int columnWidth = labelWidth+vertMargin+popupWidth+vertMargin*4;
		int columNum = (itemNum < numItems/2)? 0:1;
		int rowNum = (itemNum < numItems/2) ? itemNum: itemNum-numItems/2;
		
		NSRect labelFrame = NSMakeRect(columNum*columnWidth,vertBase-rowNum*(popupHeight+vertMargin)-4,labelWidth,popupHeight);
		NSTextField * label = [self newTextField:labelFrame];
		NSString * displayName = [NSString stringWithFormat:@"%@:",className];
		if ([displayName hasPrefix:@"MT"]) {
			displayName = [displayName substringFromIndex:2]; //delete "MT"
		}
		[label setStringValue:displayName];
		
		NSRect frame = NSMakeRect(columNum*columnWidth+labelWidth+horizMargin,vertBase-rowNum*(popupHeight+vertMargin),popupWidth,popupHeight);
		NSPopUpButton * cell = [[NSPopUpButton alloc] initWithFrame:frame pullsDown:NO];
		
		cell.title = className;
		cell.font= 	[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];

		[self addMenuTo:cell withCurrentLevel: [DDLog logLevelForClass:class]];
		cell.target = self;
		cell.action = @selector(newValue:);
		
		[self.debugLevelView addSubview:label];
		[self.debugLevelView addSubview:cell];
		[self.popups addObject: cell];
		itemNum++;
	}
	
//	for (row = 0; row < numRows; row++) {
//		for ( col = 0; col < kNumColumns; col++) {
//			NSInteger itemNum = row*kNumColumns +col;
//			NSCell * cell = [self.debugLevelForm cellAtRow:row column:col];
//			if (itemNum < numItems) {
//				cell.title = NSStringFromClass([self.debugClasses objectAtIndex:itemNum]);
//			}
//		}
//	}

}

-(IBAction) newMasterValue:(id) sender {
	NSPopUpButton * cell =  (NSPopUpButton *) sender;
	
	int newVal = (int) cell.selectedItem.tag;
	for (Class class in [DDLog registeredClasses]) {
		[class ddSetLogLevel:newVal];
	}
	for (NSPopUpButton * cell in self.popups) {
		[cell selectItemWithTag:newVal];
	}
	[DDLog writeAllClassesLogLevelToUserDefaults];
}

-(IBAction) newValue:(id) sender {
	NSPopUpButton * cell =  (NSPopUpButton *) sender;
	NSInteger whichPopup = [self.popups indexOfObject:sender];
	NSString * className = self.classNames[whichPopup];
	
	int newVal = (int) cell.selectedItem.tag;
	
	[DDLog setLogLevel:newVal forClassWithName :className];
	[DDLog writeAllClassesLogLevelToUserDefaults];
}

-(IBAction)emptyCaches:(id)sender
{
    NSAlert *cacheAlert = [NSAlert alertWithMessageText:@"Emptying the Caches will force a reload of all Details from the TiVos and from TheTVDB./nDo you want to continue?" defaultButton:@"Yes" alternateButton:@"No" otherButton:nil informativeTextWithFormat:@""];
    NSInteger returnButton = [cacheAlert runModal];
    if (returnButton != 1) {
        return;
    }
    //Remove TVDB Cache
    [[NSUserDefaults standardUserDefaults] setObject:@{} forKey:kMTTheTVDBCache];
    
    //Remove TiVo Detail Cache
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:kMTTmpDetailsDir error:nil];
    for (NSString *file in files) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",kMTTmpDetailsDir,file];
        [fm removeItemAtPath:filePath error:nil];
    }
    [tiVoManager resetAllDetails];
    [tiVoManager refreshAllTiVos];
}


@end
