//
//  CDVPDFGenerator.h
//  PDF Generator
//

#import <Foundation/Foundation.h>


#import <Cordova/CDVPlugin.h>


@interface CDVPDFGenerator : CDVPlugin <UIDocumentInteractionControllerDelegate> {
	NSString *successCallback;
	NSString *failCallback;
}

@property (nonatomic, copy) NSString *successCallback;
@property (nonatomic, copy) NSString *failCallback;
@property(nonatomic, strong) UIDocumentInteractionController *docController;
@property(nonatomic, strong) CDVInvokedUrlCommand *command;
@property(nonatomic, strong) NSString *filepath;
@property(nonatomic, strong) NSString *application;
@property (nonatomic, assign) BOOL isSending;

- (void)generatePDF:(CDVInvokedUrlCommand*)command;

@end
