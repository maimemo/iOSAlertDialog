//
//  MyView.m
//  Sample
//
//  Created by TJT on 7/12/16.
//  Copyright © 2016 TJT. All rights reserved.
//

#import "AlertDialog.h"
#define BACKGROUND_DIM 0.3f

typedef void (^Callback)(AlertDialog * __autoreleasing);

@interface AlertDialog ()

@property (weak, nonatomic) IBOutlet UILabel            *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton           *negativeButton;
@property (weak, nonatomic) IBOutlet UIButton           *neturalButton;
@property (weak, nonatomic) IBOutlet UIButton           *positiveButton;
@property (weak, nonatomic) IBOutlet UIView             *contentContainer;
@property (weak, nonatomic) IBOutlet UITextView         *contentTextView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentTextBottomSpacing;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleTopSpacing;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerLeftSpacing;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerRightSpacing;


@end

@implementation AlertDialog

@synthesize positiveText = _positiveText;
@synthesize negativeText = _negativeText;
@synthesize neturalText = _neturalText;
@synthesize onDismiss = _onDismiss;
@synthesize onCancel = _onCancel;
@synthesize positiveBlock = _positiveBlock;
@synthesize negativeBlock = _negativeBlock;
@synthesize neturalBlock = _neturalBlock;
@synthesize customView = _customView;

UIView *parent;
UIView *maskView;
BOOL added = NO;
BOOL hasTitle = NO;

+ (UIWindow *)frontMostWindow {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (keyWindow != nil) {
        return keyWindow;
    }
    NSEnumerator *frontToBackWindows = [[[UIApplication sharedApplication] windows] reverseObjectEnumerator];
    for (UIWindow *window in frontToBackWindows) {
        if (window.windowLevel == UIWindowLevelNormal) {
            return window;
        }
    }
    return nil;
}

- (instancetype)init {
    NSLog(@"inited");
    if (self = [super init]) {
        maskView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
        maskView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha: 0.4f];
        
        self = [[[NSBundle mainBundle] loadNibNamed:@"AlertDialog" owner:self options:nil] firstObject];
        self.layer.cornerRadius = 2.0f;
        self.autoresizesSubviews = YES;

        [maskView addSubview:self];
        UIButton *transparentButton = [[UIButton alloc] initWithFrame:maskView.frame];
        transparentButton.backgroundColor = [UIColor clearColor];
        [maskView insertSubview:transparentButton atIndex:0];
        [transparentButton addTarget:self action:@selector(outsideClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [_positiveButton addTarget:self action:@selector(positiveClick:) forControlEvents:UIControlEventTouchUpInside];
        [_negativeButton addTarget:self action:@selector(negativeClick:) forControlEvents:UIControlEventTouchUpInside];
        [_neturalButton addTarget:self action:@selector(neturalClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

+ (CGFloat) getMinWidth {
    return 360;
}

- (CGFloat) measureWidth {
    if (_customView != nil) {
        _containerLeftSpacing.constant = 0;
        _containerRightSpacing.constant = 0;
        CGFloat customWidth = _customView.frame.size.width;
        return MAX([AlertDialog getMinWidth], customWidth);
    }
    _containerLeftSpacing.constant = 24;
    _containerRightSpacing.constant = 24;
    return [[UIScreen mainScreen] bounds].size.width * 0.9;
}

- (CGFloat) measureHeight {
    [_titleLabel layoutIfNeeded];
    CGFloat topSpace = 0;
    if (!hasTitle) {
        _titleTopSpacing.constant = -(_titleLabel.frame.size.height + (_customView == nil ? 0 : 4));
        topSpace = -_titleLabel.frame.size.height - 12;
    } else {
        _titleTopSpacing.constant = 16;
        topSpace = 0;
    }
    if (_customView != nil) {
        return 8 + CGRectGetHeight(_customView.frame) + 36 + 8 + 8;
    }
    [_titleLabel sizeToFit];
    CGFloat width = [self measureWidth] - 48;
    CGFloat originHeight = _contentTextView.frame.size.height;
    CGFloat containerHeight = [_contentTextView sizeThatFits:CGSizeMake(width, FLT_MAX)].height;
    NSLog(@"%f, %f", _contentTextBottomSpacing.constant, _contentTextView.contentSize.height);
    return MIN([[UIScreen mainScreen] bounds].size.height * 0.85, self.frame.size.height + containerHeight - originHeight + topSpace);
}

- (void) show {
    maskView.hidden = NO;
    if (!added) {
        [[AlertDialog frontMostWindow] addSubview:maskView];
        if (_customView != nil) {
            [_contentTextView removeFromSuperview];
            [_contentContainer addSubview:_customView];
        }
    }
    self.frame = CGRectMake(0, 0, [self measureWidth], [self measureHeight]);
    self.center = maskView.center;
    maskView.alpha = 0.f;
    [UIView animateWithDuration:0.2 animations:^() {
        maskView.alpha = 1;
    }];
}

- (void) hide {
    [self hideWithAnimate:nil];
}

- (void) hideWithAnimate:(void (^ __nullable) (BOOL finished)) callback  {
    [UIView animateWithDuration:0.3 animations:^() {
        maskView.alpha = 0;
    }completion: callback];
}

- (void) dismiss {
    [self hideWithAnimate:^(BOOL finished) {
        [maskView removeFromSuperview];
        if (_onDismiss != nil) {
            _onDismiss(self);
        }
    }];
}

- (void) setTitleText:(NSString *)titleText {
    if (titleText == nil) {
        hasTitle = NO;
    } else {
        _titleLabel.text = titleText;
        hasTitle = YES;
    }
}

- (void) setContentText:(NSString *)contentText {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 4;
    _contentTextView.attributedText = [[NSAttributedString alloc]
                                       initWithString:contentText
                                       attributes: @{NSParagraphStyleAttributeName: style,
                                                     NSForegroundColorAttributeName: [UIColor darkGrayColor]}];
}

- (void) setCustomView:(UIView *)customView {
    customView.frame = CGRectMake(0, 0, customView.frame.size.width, customView.frame.size.height);
    _customView = customView;
}


- (void) setPositiveText:(NSString *)positiveText {
    [_positiveButton setTitle:positiveText forState:UIControlStateNormal];
}

- (void) setNegativeText:(NSString *)negativeText {
    [_negativeButton setTitle:negativeText forState:UIControlStateNormal];
    _negativeButton.hidden = NO;
}

- (void) setNeturalText:(NSString *)neturalText {
    [_neturalButton setTitle:neturalText forState:UIControlStateNormal];
    _neturalButton.hidden = NO;
}

- (IBAction)positiveClick:(id)sender {
    if (_positiveBlock != nil) {
        _positiveBlock(self);
    }
    [self dismiss];
}

- (IBAction)neturalClick:(id)sender {
    if (_neturalBlock != nil) {
        _neturalBlock(self);
    }
    [self dismiss];
}

- (IBAction)negativeClick:(id)sender {
    if (_negativeBlock != nil) {
        _negativeBlock(self);
    }
    [self dismiss];
}

- (IBAction)outsideClick:(id)sender {
    if (_onCancel != nil) {
        _onCancel(self);
    }
    [self dismiss];
}

- (void) dealloc {
    NSLog(@"dealloced, %@", self);
}

@end
