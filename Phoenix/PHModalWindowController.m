/*
 * Phoenix is released under the MIT License. Refer to https://github.com/kasper/phoenix/blob/master/LICENSE.md
 */

#import "PHModalWindowController.h"

@interface PHModalWindowController ()

#pragma mark - IBOutlet

@property (weak) IBOutlet NSView *containerView;
@property (weak) IBOutlet NSTextField *textField;

@end

@implementation PHModalWindowController

static NSString * const PHModalWindowControllerAppearanceDark = @"dark";
static NSString * const PHModalWindowControllerAppearanceLight = @"light";
static NSString * const PHModalWindowControllerAppearanceTransparent = @"transparent";
static NSString * const PHModalWindowControllerMessageKeyPath = @"message";
static NSString * const PHModalWindowControllerOriginKeyPath = @"origin";
static NSString * const PHModalWindowControllerTextKeyPath = @"text";
static NSString * const PHModalWindowControllerWeightKeyPath = @"weight";

#pragma mark - Initialising

- (instancetype) init {

    if (self = [super init]) {

        self.weight = 24.0;
        self.appearance = PHModalWindowControllerAppearanceDark;

        [self addObserverForKeyPaths:@[ PHModalWindowControllerMessageKeyPath,
                                        PHModalWindowControllerOriginKeyPath,
                                        PHModalWindowControllerTextKeyPath,
                                        PHModalWindowControllerWeightKeyPath ]];
    }

    return self;
}

#pragma mark - Deallocing

- (void) dealloc {

    [self removeObserverForKeyPaths:@[ PHModalWindowControllerMessageKeyPath,
                                       PHModalWindowControllerOriginKeyPath,
                                       PHModalWindowControllerTextKeyPath,
                                       PHModalWindowControllerWeightKeyPath ]];
}

#pragma mark - NSWindowController

- (NSString *) windowNibName {

    return @"ModalWindow";
}

- (void) windowDidLoad {

    self.window.alphaValue = 0.0;
    self.window.animationBehavior = NSWindowAnimationBehaviorAlertPanel;
    self.window.backgroundColor = [NSColor clearColor];
    self.window.ignoresMouseEvents = YES;
    self.window.level = NSFloatingWindowLevel;
    self.window.opaque = NO;
}

#pragma mark - Appearance

- (void) setupVibrantAppearance {

    CGFloat cornerRadius = 10.0;
    NSDictionary<NSString *, id> *views = @{ @"container": self.containerView };

    NSVisualEffectView *visualEffectView = [[NSVisualEffectView alloc] initWithFrame:self.window.contentView.frame];
    visualEffectView.material = NSVisualEffectMaterialDark;
    visualEffectView.state = NSVisualEffectStateActive;

    // Use light material
    if ([self.appearance.lowercaseString isEqualToString:PHModalWindowControllerAppearanceLight]) {
        visualEffectView.material = NSVisualEffectMaterialLight;
        self.textField.textColor = [NSColor blackColor];
    }

    // Set mask image to rounded rectangle
    CGFloat edgeSize = 1.0 + (2 * cornerRadius);
    NSSize maskSize = NSMakeSize(edgeSize, edgeSize);
    visualEffectView.maskImage = [NSImage imageWithSize:maskSize flipped:NO drawingHandler:^BOOL (NSRect destination) {

        [[NSBezierPath bezierPathWithRoundedRect:destination xRadius:cornerRadius yRadius:cornerRadius] fill];
        return YES;
    }];

    // Make edges smooth
    visualEffectView.maskImage.capInsets = NSEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius);

    // Add container view as subview
    [visualEffectView addSubview:self.containerView];

    [visualEffectView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[container]"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];

    [visualEffectView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[container]-(0)-|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];

    [visualEffectView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[container]"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];

    [visualEffectView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[container]-(0)-|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views]];
    // Set visual effect view as the content view
    self.window.contentView = visualEffectView;
}

#pragma mark - KVO

- (void) addObserverForKeyPaths:(NSArray<NSString *> *)keyPaths {

    for (NSString *keyPath in keyPaths) {
        [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void) removeObserverForKeyPaths:(NSArray<NSString *> *)keyPaths {

    for (NSString *keyPath in keyPaths) {
        [self removeObserver:self forKeyPath:keyPath];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)__unused object
                         change:(NSDictionary<NSString *, id> *)__unused change
                        context:(void *)__unused context {

    [self window];

    // Update text
    if ([keyPath isEqualToString:PHModalWindowControllerMessageKeyPath]) {
        NSLog(@"Deprecated: Property “message” for modal is deprecated and will be removed in later versions, use “text” instead.");
        self.text = self.message;
    }

    // Update frame origin
    if ([keyPath isEqualToString:PHModalWindowControllerOriginKeyPath]) {
        [self.window setFrameOrigin:self.origin];
    }

    // Update text field
    if ([keyPath isEqualToString:PHModalWindowControllerTextKeyPath]) {
        self.textField.stringValue = self.text;
    }

    // Update weight
    if ([keyPath isEqualToString:PHModalWindowControllerWeightKeyPath]) {
        self.textField.font = [NSFont systemFontOfSize:self.weight];
    }
}

#pragma mark - Displaying

- (NSRect) frame {

    [self.window layoutIfNeeded];
    return self.window.frame;
}

- (void) fadeWindowToAlpha:(CGFloat)alpha completionHandler:(void (^)())completionHandler {

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {

        context.duration = 0.2;
        [self.window animator].alphaValue = alpha;

    } completionHandler:completionHandler];
}

- (void) show {

    if (!self.text || isnan(self.origin.x) || isnan(self.origin.y)) {
        return;
    }

    // Set vibrant appearance
    if (![self.appearance.lowercaseString isEqualToString:PHModalWindowControllerAppearanceTransparent]) {
        [self setupVibrantAppearance];
    }

    [self showWindow:self];
    [self fadeWindowToAlpha:1.0 completionHandler:^{

        // Keep window open until closed
        if (self.duration == 0) {
            return;
        }

        [self performSelector:@selector(close) withObject:nil afterDelay:self.duration];
    }];
}

#pragma mark - Closing

- (void) close {

    [self fadeWindowToAlpha:0.0 completionHandler:^{

        [super close];
    }];
}

@end
