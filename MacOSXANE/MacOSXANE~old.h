//
//  MacOSXANE.h
//

#ifndef MacOSXANE_MacOSXANE_h
#define MacOSXANE_MacOSXANE_h

// macros //

// DEBUG_MSG() -- display message box with debug string
#define DEBUG_MSG(msg) { NSAlert* alert = [[NSAlert alloc] init]; alert.alertStyle = NSInformationalAlertStyle; alert.informativeText = msg; [alert runModal]; [alert release]; }

// SAFE_FREE() -- safe release of memory pointers
#define SAFE_FREE(ptr) if(ptr) { free((void*) ptr); ptr = NULL; }

// SAFE_RELEASE() -- safe release of interface objects
#define SAFE_RELEASE(obj) if(obj) { [obj release];     obj = nil;  }

// TRY_CATCH_DONT_CARE() -- compiler requires try/catch but result doesn't matter
#define TRY_CATCH_DONT_CARE(fn) @try { fn; } @catch(NSException* e) {}

// library function prototypes //

#define DECL_LIB_FN_PROTOTYPE(fn) FREObject fn (FREContext, void*, uint32_t, FREObject*)

void MacOSXANEExtensionInitializer(void**, FREContextInitializer*, FREContextFinalizer*);
void MacOSXANEContextInitializer(void*, const uint8_t*, FREContext, uint32_t*, const FRENamedFunction**);
void MacOSXANEContextFinalizer(void*);

DECL_LIB_FN_PROTOTYPE(addFullScreenButton);
DECL_LIB_FN_PROTOTYPE(getDesktopBottom);
DECL_LIB_FN_PROTOTYPE(getDesktopLeft);
DECL_LIB_FN_PROTOTYPE(getDesktopRight);
DECL_LIB_FN_PROTOTYPE(getDesktopTop);
DECL_LIB_FN_PROTOTYPE(getLongestDisplaySide);
DECL_LIB_FN_PROTOTYPE(getWindowHeight);
DECL_LIB_FN_PROTOTYPE(getWindowPosX);
DECL_LIB_FN_PROTOTYPE(getWindowPosY);
DECL_LIB_FN_PROTOTYPE(getWindowWidth);
DECL_LIB_FN_PROTOTYPE(isFullScreen);
DECL_LIB_FN_PROTOTYPE(isMaximized);
DECL_LIB_FN_PROTOTYPE(maximize);
DECL_LIB_FN_PROTOTYPE(messageBox);
DECL_LIB_FN_PROTOTYPE(moveWindow);
DECL_LIB_FN_PROTOTYPE(testANE);
DECL_LIB_FN_PROTOTYPE(toggleFullScreen);

// class interfaces //

// ATFMenuItem -- item to be added to window menu
@interface ATFMenuItem : NSMenuItem
{
	// no members
}

+ (void) newAction: (id)sender;
@end

// BestVisibleRect -- compute best rect for window to display
@interface BestVisibleRect : NSObject
{
	// no members
}

+ (NSRect) forWindow: (NSRect)window;
@end

// DeminListener -- item to receive deminiaturize notifications
@interface DeminListener : NSObject
{
	// no members
}

- (void) newAction: (id)sender;
@end

// FSMenuItem -- item to be added to window menu
@interface FSMenuItem : NSMenuItem
{
	// no members
}

+ (void) newAction: (id)sender;
@end

// FSButtonRedirect -- take over function of zoom button
@interface FSButtonRedirect : NSObject
{
	// no members
}

+ (void) newAction: (id)sender;
@end

// MinListener -- item to receive miniaturize notifications
@interface MinListener : NSObject
{
	// no members
}

- (void) newAction: (id)sender;
@end

// MinMenuItem -- item to be added to window menu
@interface MinMenuItem : NSMenuItem
{
	// no members
}

+ (void) newAction: (id)sender;
@end

// ZoomMenuItem -- item to be added to window menu
@interface ZoomMenuItem : NSMenuItem
{
	// no members
}

+ (void) newAction: (id)sender;
@end

#endif // MacOSXANE_MacOSXANE_h
