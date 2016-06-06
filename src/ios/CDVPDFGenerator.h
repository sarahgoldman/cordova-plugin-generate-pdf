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

- (void)generatePDF:(CDVInvokedUrlCommand*)command;

@end
