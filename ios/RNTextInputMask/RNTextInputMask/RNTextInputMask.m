//
//  RNTextInputMask.m
//  RNTextInputMask
//
//  Created by Ivan Zotov on 7/29/17.
//
//

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTUIManager.h>
#import <React/RCTEventDispatcher.h>
#import "RCTSinglelineTextInputView.h"
#import "RCTUITextField.h"
#import "RNTextInputMask.h"
#import "RNTextInputMask-Swift.h"

@import InputMask;

@implementation RNTextInputMask {
    NSMutableDictionary *masks;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue {
    return self.bridge.uiManager.methodQueue;
}

RCT_EXPORT_METHOD(mask:(NSString *)maskString inputValue:(NSString *)inputValue autoComplete: (BOOL)autoComplete onResult:(RCTResponseSenderBlock)onResult) {
    NSString *output = [RNMask maskValueWithText:inputValue format:maskString autoComplete:autoComplete];
    onResult(@[output]);
}

RCT_EXPORT_METHOD(unmask:(NSString *)maskString inputValue:(NSString *)inputValue autoComplete: (BOOL)autoComplete onResult:(RCTResponseSenderBlock)onResult) {
    NSString *output = [RNMask unmaskValueWithText:inputValue format:maskString autoComplete:autoComplete];
    onResult(@[output]);
}

RCT_EXPORT_METHOD(setMask:(nonnull NSNumber *)reactNode mask:(NSString *)mask forceCapitals:(BOOL) forceCapitals autoCompleteOnFocus:(BOOL) autoCompleteOnFocus) {
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTSinglelineTextInputView *> *viewRegistry ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            RCTSinglelineTextInputView *view = viewRegistry[reactNode];
            RCTUITextField *textView = [view backedTextInputView];
            
            if (!masks) {
                masks = [[NSMutableDictionary alloc] init];
            }
            
            NSString *key = [NSString stringWithFormat:@"%@", reactNode];
            MaskedTextFieldDelegate* maskedDelegate;
            if (forceCapitals) {
                maskedDelegate = [[ForceCapitalsMaskedTextFieldDelegate alloc] init];
            } else {
                maskedDelegate = [[MaskedTextFieldDelegate alloc] init];
            }
            [maskedDelegate setPrimaryMaskFormat: mask];
            [maskedDelegate setAutocompleteOnFocus: autoCompleteOnFocus];
            masks[key] = maskedDelegate;
            [masks[key] setListener:self];
            textView.delegate = masks[key];
            
            [self updateTextField:maskedDelegate textView:textView];
        });
    }];
}

RCT_EXPORT_METHOD(setText:(nonnull NSNumber *)reactNode text:(NSString *)text){
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTSinglelineTextInputView *> *viewRegistry ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            RCTSinglelineTextInputView *view = viewRegistry[reactNode];
            UIView<RCTBackedTextInputViewProtocol>  *textView = [view backedTextInputView];
            [textView setAttributedText:[[NSAttributedString alloc] initWithString:text]];
        });
    }];
}

- (void)textField:(RCTUITextField *)textField didFillMandatoryCharacters:(BOOL)complete didExtractValue:(NSString *)value
{
    [self.bridge.eventDispatcher sendTextEventWithType:RCTTextEventTypeChange
                                              reactTag:[[textField reactSuperview] reactTag]
                                                  text:textField.attributedText.string
                                                   key:nil
                                            eventCount:1];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.bridge.eventDispatcher sendTextEventWithType:RCTTextEventTypeFocus
                                              reactTag:[[textField reactSuperview] reactTag]
                                                  text:textField.attributedText.string
                                                   key:nil
                                            eventCount:1];
}

- (void)textFieldDidEndEditing:(RCTUITextField *)textField
{
    [self.bridge.eventDispatcher sendTextEventWithType:RCTTextEventTypeBlur
                                              reactTag:[[textField reactSuperview] reactTag]
                                                  text:textField.attributedText.string
                                                   key:nil
                                            eventCount:1];
}

- (void)textFieldDidEndEditing:(UITextField *)textField reason:(UITextFieldDidEndEditingReason)reason
{
    [self.bridge.eventDispatcher sendTextEventWithType:RCTTextEventTypeBlur
                                              reactTag:[[textField reactSuperview] reactTag]
                                                  text:textField.attributedText.string
                                                   key:nil
                                            eventCount:1];
}

- (BOOL)textFieldShouldReturn:(RCTUITextField *)textField
{
    [self.bridge.eventDispatcher sendTextEventWithType:RCTTextEventTypeSubmit
                                              reactTag:[[textField reactSuperview] reactTag]
                                                  text:textField.attributedText.string
                                                   key:nil
                                            eventCount:1];
    return YES;
}

- (void)updateTextField:(MaskedTextFieldDelegate *)maskedDelegate textView:(RCTUITextField *)textView {
    if(textView.attributedText.string.length> 0){
        NSString *originalString = textView.attributedText.string;
        NSString *croppedText = [originalString substringToIndex:[originalString length] -1];
        
        [textView setAttributedText:[[NSAttributedString alloc] initWithString:croppedText]];
        NSString *last = [originalString substringFromIndex:[originalString length] - 1];
        
        [maskedDelegate textField:(UITextField*)textView
    shouldChangeCharactersInRange: (NSRange){[textView.attributedText.string length], 0}
                replacementString:last];
    }
}

@end

