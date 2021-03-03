//
//  MacOSXANE.m
//

// imports & includes //

@import AppKit;

#include <stdlib.h>

#import "FlashRuntimeExtensions.h"
#import "MacOSXANE.h"

// globals //

// function list
FRENamedFunction* g_pFunc = NULL;

// primary context
FREContext m_ctx = NULL;

// menu items
MinMenuItem*  g_minMenuItem  = nil;
ZoomMenuItem* g_zoomMenuItem = nil;
FSMenuItem*	  g_fsMenuItem   = nil;

// miniaturize listeners
DeminListener* g_deminListener = nil;
MinListener*   g_minListener   = nil;

// visibility listeners
VisibilityInListener*  g_visInListener  = nil;
VisibilityOutListener* g_visOutListener = nil;

// window state flag
bool g_bIsFullScreen = FALSE;
bool g_bIsZoomed     = FALSE;

// functions required by Flash //

// extension initializer
void MacOSXANEExtensionInitializer(void**                 ppExtDataToSet,
								   FREContextInitializer* pCtxInitializerToSet,
								   FREContextFinalizer*   pCtxFinalizerToSet)
{
	// reset data
	(*ppExtDataToSet) = NULL;
	
	// set context initializer
	(*pCtxInitializerToSet) = &MacOSXANEContextInitializer;
	
	// reset finalizer
	(*pCtxFinalizerToSet) = &MacOSXANEContextFinalizer;
}

// context initializer
void MacOSXANEContextInitializer(void*                    pExtData,
								 const uint8_t*           pCtxType,
								 FREContext               ctx,
								 uint32_t*                pNumFunctionsToSet,
								 const FRENamedFunction** pFunctionsToSet)
{
	// set number of functions
	(*pNumFunctionsToSet) = 9;
	
	// allocate memory for functions
	g_pFunc = g_pFunc ? g_pFunc : (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * (*pNumFunctionsToSet));
	
	// add functions
	#define SET_LIB_FN_POINTER(n, str, fn) g_pFunc[n].name = (const uint8_t*) str; g_pFunc[n].functionData = NULL; g_pFunc[n].function = &fn
	
	SET_LIB_FN_POINTER(0, "addFullScreenButton",     addFullScreenButton);
	SET_LIB_FN_POINTER(1, "detectVisibilityChanges", detectVisibilityChanges);
	SET_LIB_FN_POINTER(2, "getLongestDisplaySide",   getLongestDisplaySide);
	SET_LIB_FN_POINTER(3, "isFullScreen",            isFullScreen);
	SET_LIB_FN_POINTER(4, "isRectOnVisibleScreen",   isRectOnVisibleScreen);
	SET_LIB_FN_POINTER(5, "isZoomedOrZooming",       isZoomedOrZooming);
	SET_LIB_FN_POINTER(6, "messageBox",              messageBox);
	SET_LIB_FN_POINTER(7, "testANE",                 testANE);
	SET_LIB_FN_POINTER(8, "toggleFullScreen",        toggleFullScreen);
	
	// set function pointer
	(*pFunctionsToSet) = g_pFunc;
}

// context finalizer
void MacOSXANEContextFinalizer(void* pExtData)
{
	// free function list
	SAFE_FREE(g_pFunc);
	
	// release all objects
	SAFE_RELEASE(g_fsMenuItem);
	SAFE_RELEASE(g_minMenuItem);
	SAFE_RELEASE(g_zoomMenuItem);
	SAFE_RELEASE(g_fsMenuItem);
	SAFE_RELEASE(g_deminListener);
	SAFE_RELEASE(g_minListener);
	SAFE_RELEASE(g_visInListener);
	SAFE_RELEASE(g_visOutListener);
}

// library function implementations //

// addFullScreenButton() -- add full-screen button & menu items
FREObject addFullScreenButton(FREContext ctx,
							  void*      pFuncData,
							  uint32_t   argc,
							  FREObject  argv[])
{
	// get main application
	NSApplication* application = [NSApplication sharedApplication];
	
	// create miniaturize listeners
	g_deminListener = [[DeminListener alloc] init];
	g_minListener   = [[MinListener   alloc] init];
	
	// add fullscreen flags to all app windows
	for(NSWindow* window in [application windows])
	{
		// get behavior flags
		NSWindowCollectionBehavior behavior = [window collectionBehavior];
		
		// add fullscreen option
		behavior |= NSWindowCollectionBehaviorFullScreenPrimary;
		
		// replace behavior flags
		TRY_CATCH_DONT_CARE([window setCollectionBehavior: behavior]);
		
		// get zoom button
		NSButton* zoomButton = [window standardWindowButton: NSWindowZoomButton];
		
		// found it?
		if(zoomButton)
		{
			// change zoom button to full-screen button
			[zoomButton setTarget: [FSButtonRedirect class]];
			[zoomButton setAction: @selector(newAction:)];
		}
		
		// get fullscreen button
		NSButton* fsButton = [window standardWindowButton: NSWindowFullScreenButton];
		
		// found it?
		if(fsButton)
		{
			// hijack it
			[fsButton setTarget: [FSButtonRedirect class]];
			[fsButton setAction: @selector(newAction:)];
		}
		
		// register for minaturize notifications
		[[NSNotificationCenter defaultCenter] addObserver: g_minListener
												 selector: @selector(newAction:)
													 name: NSWindowDidMiniaturizeNotification
												   object: window ];
		
		// register for deminaturize notifications
		[[NSNotificationCenter defaultCenter] addObserver: g_deminListener
												 selector: @selector(newAction:)
													 name: NSWindowDidDeminiaturizeNotification
												   object: window ];
	}
	
	// get main menu
	NSMenu* mainMenu = [application mainMenu];
	
	// check main menu
	if(mainMenu)
	{
		// delete all menu items except root
		for(int c = 1; c < [mainMenu numberOfItems]; c++)
			[mainMenu removeItemAtIndex: c];
		
		// search for edit menu (hangs on for some reason?)
		NSMenuItem* editMenuItem = [mainMenu itemWithTitle: @"Edit"];
		
		// remove edit menu
		if(editMenuItem)
			[mainMenu removeItem: editMenuItem];
		
		// get root menu item
		NSMenuItem* rootMenuItem = [mainMenu itemAtIndex: 0];
		
		// get root submenu
		NSMenu* rootSubMenu = rootMenuItem ? [rootMenuItem submenu] : nil;
		
		// check submenu
		if(rootSubMenu)
		{
			// disable auto-enable for items
			[rootSubMenu setAutoenablesItems: NO];
			
			// add separator
			[rootSubMenu addItem: [NSMenuItem separatorItem]];
			
			// prepare minimize item
			g_minMenuItem = [[MinMenuItem alloc] initWithTitle: @"Minimize"
														action: @selector(newAction:)
												 keyEquivalent: @"m" ];
			
			// set proper target
			[g_minMenuItem setTarget: [MinMenuItem class]];
			
			// add to menu
			[rootSubMenu addItem: g_minMenuItem];
			
			// prepare zoom item
			g_zoomMenuItem = [[ZoomMenuItem alloc] initWithTitle: @"Zoom"
														  action: @selector(newAction:)
												   keyEquivalent: @"" ];
			
			// set proper target
			[g_zoomMenuItem setTarget: [ZoomMenuItem class]];
			
			// add to menu
			[rootSubMenu addItem: g_zoomMenuItem];
			
			// prepare full-screen menu item
			g_fsMenuItem = [[FSMenuItem alloc] initWithTitle: @"Enter Full Screen"
													  action: @selector(newAction:)
											   keyEquivalent: @"f" ];
			
			// set proper target
			[g_fsMenuItem setTarget: [FSMenuItem class]];
			
			// set key modifier mask
			NSInteger modifierMask = NSControlKeyMask |
									 NSCommandKeyMask ;
			
			// set key modifier
			[g_fsMenuItem setKeyEquivalentModifierMask: modifierMask];
			
			// add to menu
			[rootSubMenu addItem: g_fsMenuItem];
		}
	}
	
	// ok
	return(NULL);
}

// detectVisibilityChanges() -- add listeners for visibility-change events
FREObject detectVisibilityChanges(FREContext ctx,
								  void*      pFuncData,
								  uint32_t   argc,
								  FREObject  argv[])
{
	// get main application
	NSApplication* application = [NSApplication sharedApplication];
	
	// save global context
	m_ctx = ctx;
	
	// create visibility listeners
	g_visInListener  = [[VisibilityInListener  alloc] init];
	g_visOutListener = [[VisibilityOutListener alloc] init];
	
	// register for visibility-in notifications
	[[NSNotificationCenter defaultCenter] addObserver: g_visInListener
											 selector: @selector(newAction:)
												 name: NSApplicationDidUnhideNotification
											   object: application ];

	// register for visibility-out notifications
	[[NSNotificationCenter defaultCenter] addObserver: g_visOutListener
											 selector: @selector(newAction:)
												 name: NSApplicationDidHideNotification
											   object: application ];
	
	// add notifications for all app windows
	for(NSWindow* window in [application windows])
	{
		// register for deminiaturize notifications
		[[NSNotificationCenter defaultCenter] addObserver: g_visInListener
												 selector: @selector(newAction:)
													 name: NSWindowDidDeminiaturizeNotification
												   object: window ];
		
		// register for miniaturize notifications
		[[NSNotificationCenter defaultCenter] addObserver: g_visOutListener
												 selector: @selector(newAction:)
													 name: NSWindowDidMiniaturizeNotification
												   object: window ];
	}

	// ok
	return(NULL);
}

// getLongestDisplaySide() -- retrieve maximum value for resolution
FREObject getLongestDisplaySide(FREContext ctx,
								void*      pFuncData,
								uint32_t   argc,
								FREObject  argv[])
{
	// reset max dimensions
	int x1 = 0;
	int y1 = 0;
	int x2 = 0;
	int y2 = 0;
	
	// get max dimensions for all screens
	for(NSScreen* screen in [NSScreen screens])
	{
		// get frame
		NSRect frame = [screen frame];
		
		// convert dimensions
		int u1 = frame.origin.x;
		int v1 = frame.origin.y;
		int u2 = frame.origin.x + frame.size.width;
		int v2 = frame.origin.y + frame.size.height;
		
		// apply to max dimensions
		if(u1 < x1) x1 = u1;
		if(v1 < y1) y1 = v1;
		if(u2 > x2) x2 = u2;
		if(v2 > y2) y2 = v2;
	}
	
	// compute sides
	int nSideX = x2 - x1;
	int nSideY = y2 - y1;
	
	// set longest side
	int nRet = (nSideX > nSideY) ? nSideX : nSideY;

	// object to return
	FREObject pRet = NULL;
	
	// create object
	TRY_CATCH_DONT_CARE(FRENewObjectFromInt32(nRet, &pRet));
	
	// send it
	return(pRet);
}

// isFullScreen() -- retrieve full-screen flag
FREObject isFullScreen(FREContext ctx,
					   void*      pFuncData,
					   uint32_t   argc,
					   FREObject  argv[])
{
	// object to return
	FREObject pRet = NULL;
	
	// create object
	TRY_CATCH_DONT_CARE(FRENewObjectFromInt32((int32_t) (g_bIsFullScreen ? 1 : 0), &pRet));
	
	// ok
	return(pRet);
}

// isRectOnVisibleScreen() -- determine if rect fits within any visible screen
FREObject isRectOnVisibleScreen(FREContext ctx,
								void*      pFuncData,
								uint32_t   argc,
								FREObject  argv[])
{
	// flag to return
	bool flag = FALSE;
	
	// passed parameters
	int32_t nWindowX = 0;
	int32_t nWindowY = 0;
	int32_t nWindowW = 0;
	int32_t nWindowH = 0;
	
	// get parameters
	FREGetObjectAsInt32(argv[0], &nWindowX);
	FREGetObjectAsInt32(argv[1], &nWindowY);
	FREGetObjectAsInt32(argv[2], &nWindowW);
	FREGetObjectAsInt32(argv[3], &nWindowH);
	
	// get list of screens
	NSArray* screens = [NSScreen screens];
	
	// compute bounds of rect
	int x11 = nWindowX;
	int y11 = nWindowY;
	int x12 = nWindowX + nWindowW;
	int y12 = nWindowY + nWindowH;
	
	// determine if any portion of rect is visible
	for(NSScreen* screen in screens)
	{
		// get visible frame
		NSRect frame = [screen visibleFrame];
		
		// compute visible bounds
		int x21 = frame.origin.x;
		int y21 = frame.origin.y;
		int x22 = frame.origin.x + frame.size.width;
		int y22 = frame.origin.y + frame.size.height;
		
		// mathematical comparison macros
		#define Min(a, b) (((a) < (b)) ? (a) : (b))
		#define Max(a, b) (((a) > (b)) ? (a) : (b))
		
		// compute overlap values
		int nOverlapX = Max(0, Min(x12, x22) - Max(x11, x21));
		int nOverlapY = Max(0, Min(y12, y22) - Max(y11, y21));
		
		// kill macros
		#undef Min
		#undef Max
		
		// compute overlapping area
		int nArea = nOverlapX * nOverlapY;
		
		// check area
		if(nArea > 0)
			flag = TRUE;
	}
	
	// object to return
	FREObject pRet = NULL;
	
	// create object
	TRY_CATCH_DONT_CARE(FRENewObjectFromInt32((int32_t) (flag ? 1 : 0), &pRet));
	
	// ok
	return(pRet);
}

// isZoomedOrZooming() -- retrieve window zoom state
FREObject isZoomedOrZooming(FREContext ctx,
							void*      pFuncData,
							uint32_t   argc,
							FREObject  argv[])
{
	// object to return
	FREObject pRet = NULL;
	
	// create object
	TRY_CATCH_DONT_CARE(FRENewObjectFromInt32((int32_t) (g_bIsZoomed ? 1 : 0), &pRet));
	
	// ok
	return(pRet);
}

// messageBox() -- display simple modal message box
FREObject messageBox(FREContext ctx,
					 void*      pFuncData,
					 uint32_t   argc,
					 FREObject  argv[])
{
	// text lengths
	uint32_t nCaptionLen;
	uint32_t nMessageLen;
	
	// text data
	const uint8_t *pCaption;
	const uint8_t *pMessage;
	
	// get objects
	FREGetObjectAsUTF8(argv[0], &nCaptionLen, &pCaption);
	FREGetObjectAsUTF8(argv[1], &nMessageLen, &pMessage);
	
	// convert to strings
	NSString* caption = [NSString stringWithUTF8String: (const char*) pCaption];
	NSString* message = [NSString stringWithUTF8String: (const char*) pMessage];
	
	// create alert object
	NSAlert* alert = [[NSAlert alloc] init];
	
	// prepare alert
	[alert setAlertStyle:      NSInformationalAlertStyle];
	[alert setInformativeText: message];
	[alert setMessageText:     caption];
	
	// run & dismiss alert
	[alert runModal];
	[alert release];
	
	// ok
	return(NULL);
}

// testANE() -- verify that the library is working correctly
FREObject testANE(FREContext ctx,
				  void*      pFuncData,
				  uint32_t   argc,
				  FREObject  argv[])
{
	// passed parameter
	int32_t nData = 0;
	
	// get first parameter
	FREGetObjectAsInt32(argv[0], &nData);
	
	// object to return
	FREObject pRet = NULL;
	
	// create object
	TRY_CATCH_DONT_CARE(FRENewObjectFromInt32(nData, &pRet));
	
	// ok (errors will fall thru)
	return(pRet);
}

// toggleFullScreen() -- toggle full-screen mode
FREObject toggleFullScreen(FREContext ctx,
						   void*      pFuncData,
						   uint32_t   argc,
						   FREObject  argv[])
{
	// use static class method
	[FSMenuItem newAction: nil];
	
	// ok
	return(NULL);
}

// class implementations //

// DeminListener -- item to receive deminiaturize notifications
@implementation DeminListener

// newAction: replacement for default action
- (void) newAction: (id)sender
{
	// toggle menu items
	TRY_CATCH_DONT_CARE
	(
		if(g_minMenuItem)  [g_minMenuItem  setEnabled: YES];
		if(g_zoomMenuItem) [g_zoomMenuItem setEnabled: YES];
		if(g_fsMenuItem)   [g_fsMenuItem   setEnabled: YES];
	)
}
@end

// FSMenuItem -- item to be added to window menu
@implementation FSMenuItem

// newAction: replacement for default action
+ (void) newAction: (id)sender
{
	// get main application
	NSApplication* application = [NSApplication sharedApplication];
	
	// get main window
	NSWindow* mainWindow = [application mainWindow];
	
	// check window
	if(mainWindow)
	{
		// check fullscreen flag
		if(g_bIsFullScreen)
		{
			// toggle mode (back to normal)
			[mainWindow toggleFullScreen: nil];
		
			// clear flag
			g_bIsFullScreen = FALSE;

			// toggle menu items
			TRY_CATCH_DONT_CARE
			(
				if(g_fsMenuItem)   [g_fsMenuItem     setTitle: @"Enter Full Screen"];
				if(g_minMenuItem)  [g_minMenuItem  setEnabled: YES];
				if(g_zoomMenuItem) [g_zoomMenuItem setEnabled: YES];
			)
		}
		else
		{
			// set flag
			g_bIsFullScreen = TRUE;

			// toggle mode (to full screen)
			[mainWindow toggleFullScreen: nil];
			
			// toggle menu items
			TRY_CATCH_DONT_CARE
			(
				if(g_fsMenuItem)   [g_fsMenuItem     setTitle: @"Exit Full Screen"];
				if(g_minMenuItem)  [g_minMenuItem  setEnabled: NO];
				if(g_zoomMenuItem) [g_zoomMenuItem setEnabled: NO];
			)
		}
	}
}
@end

// FSButtonRedirect -- take over function of zoom button
@implementation FSButtonRedirect

// newAction: replacement for default action
+ (void) newAction: (id)sender
{
	// use static class method
	[FSMenuItem newAction: nil];
}
@end

// MinListener -- item to receive miniaturize notifications
@implementation MinListener

// newAction: replacement for default action
- (void) newAction: (id)sender
{
	// toggle menu items
	TRY_CATCH_DONT_CARE
	(
		if(g_minMenuItem)  [g_minMenuItem  setEnabled: NO];
		if(g_zoomMenuItem) [g_zoomMenuItem setEnabled: NO];
		if(g_fsMenuItem)   [g_fsMenuItem   setEnabled: NO];
	)
}
@end

// MinMenuItem -- item to be added to window menu
@implementation MinMenuItem

// newAction: replacement for default action
+ (void) newAction: (id)sender
{
	// get main application
	NSApplication* application = [NSApplication sharedApplication];
	
	// get main window
	NSWindow* mainWindow = [application mainWindow];
	
	// check window & miniaturize
	if(mainWindow)
		[mainWindow performMiniaturize: nil];
}
@end

// VisibilityInListener -- item to receive visibility-in notifications
@implementation VisibilityInListener

// newAction: replacement for default action
- (void) newAction: (id)sender
{
	// notify caller
	FREDispatchStatusEventAsync(m_ctx,
								(const uint8_t*)"onWindowVisibilityChanged",
								(const uint8_t*)"true");
}
@end

// VisibilityOutListener -- item to receive visibility-out notifications
@implementation VisibilityOutListener

// newAction: replacement for default action
- (void) newAction: (id)sender
{
	// notify caller
	FREDispatchStatusEventAsync(m_ctx,
								(const uint8_t*)"onWindowVisibilityChanged",
								(const uint8_t*)"false");
}
@end

// ZoomMenuItem -- item to be added to window menu
@implementation ZoomMenuItem

// newAction: replacement for default action
+ (void) newAction: (id)sender
{
	// get main application
	NSApplication* application = [NSApplication sharedApplication];
	
	// get main window
	NSWindow* mainWindow = [application mainWindow];
	
	// check window
	if(mainWindow)
	{
		// swap flag
		g_bIsZoomed = !g_bIsZoomed;
		
		// perform zoom
		[mainWindow performZoom: nil];
	}
}
@end

// eof //
