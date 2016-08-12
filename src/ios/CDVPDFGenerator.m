//
//  CDVPDFGenerator.m
//  PDF Generator
//

#import "CDVPDFGenerator.h"
#import <UIKit/UIKit.h>

@implementation CDVPDFGenerator

@synthesize successCallback, failCallback;

// Plugin Functions

- (void)generatePDF:(CDVInvokedUrlCommand *)command
{

    // get parameters from cordova command
    NSString *filename = [NSString stringWithFormat:@"%@.pdf", [command.arguments objectAtIndex:0]];
    NSString *htmlString = [command.arguments objectAtIndex:1];
    NSString *orientation = [command.arguments objectAtIndex:2];

    self.command = command;

    dispatch_async(dispatch_get_main_queue(), ^{

        // setup a print formatter with the given html
        UIMarkupTextPrintFormatter *formatter = [[UIMarkupTextPrintFormatter alloc] initWithMarkupText:htmlString];

        // setup renderer
        UIPrintPageRenderer *renderer = [[UIPrintPageRenderer alloc] init];

        // setup page bounds
        CGRect page;
        page.origin.x=0;
        page.origin.y=0;

        // 612 x 792 is equal to 8.5" x 11" paper in portrait mode,
        // set page width and height based on given orientation
        if ([orientation isEqualToString:@"landscape"]) {
            page.size.width=792;
            page.size.height=612;
        } else {
            page.size.height=792;
            page.size.width=612;
        }

        // since we are just making a PDF and not actually printing,
        // we can leave the margins at 0 to get the printable area.
        // if you want to add margins, this would be the place...
        CGRect printable = CGRectInset(page,0,0);

        // set the properties on the renderer...
        //
        // note: these are technically readonly properties (no setter
        // methods) since they normally are pulled from the printInfo
        // of the print controller (I think), but we are only using
        // the renderer so we must manually set these.
        [renderer setValue:[NSValue valueWithCGRect:page] forKey:@"paperRect"];
        [renderer setValue:[NSValue valueWithCGRect:printable] forKey:@"printableRect"];

        // add the formatter to the renderer for all pages
        [renderer addPrintFormatter:formatter startingAtPageAtIndex:0];

        // create an empty data object for the pdf
        NSMutableData * pdfData = [NSMutableData data];

        // create a graphics context the size of the print page
        UIGraphicsBeginPDFContextToData(pdfData,page,nil);

        // for each page in the print renderer...
        for (NSInteger i=0; i < [renderer numberOfPages]; i++)
        {
            // draw that page to a new pdf page
            UIGraphicsBeginPDFPage();
            CGRect bounds = UIGraphicsGetPDFContextBounds();
            [renderer drawPageAtIndex:i inRect:bounds];
        }

        // we're done drawing
        UIGraphicsEndPDFContext();

        // get the app documents directory as a string
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];

        // append the given filename to the path
        self.filepath = [documentsDirectory stringByAppendingPathComponent:filename];

        // save the pdf data to the file and return the result in a boolean
        BOOL fileSuccess = [pdfData writeToFile:self.filepath atomically:YES];

        // open the file if successful save, else send error result
        if (fileSuccess) {
            NSLog(@"SAVED");
            [self openFile];
        } else {
            NSLog(@"ERROR");
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"{\"error\" : \"file not created\"}"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
        }

    });
}

- (void)openFile
{
    // get url for file
    NSURL *fileURL = [self getFileURL:self.filepath];

    dispatch_async(dispatch_get_main_queue(), ^{

        // setup the document interaction controller with the file
        self.docController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        self.docController.delegate = self;
        self.docController.UTI = @"application/pdf";

        // popover location
        CGRect rect = CGRectMake(0, 0, 1000.0f, 150.0f);

        // open the file and return the result to a boolean
        BOOL wasOpened = [self.docController presentOptionsMenuFromRect:rect inView:self.viewController.view animated:NO];

        // proceed to delete the file if opened, or send error
        if (wasOpened) {
            NSLog(@"OPENED");
        } else {
            NSLog(@"ERROR");
            [self deleteFile];
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"{\"error\" : \"file not opened\"}"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
        }

    });
}

- (void)deleteFile
{

    // get url for file
    NSURL *fileURL = [self getFileURL:self.filepath];

    dispatch_async(dispatch_get_main_queue(), ^{

        // delete the file and save result in boolean
        BOOL wasDeleted = [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];

        // if deleted, this whole thing was successful
        if (wasDeleted) {
            NSLog(@"DELETED");
        } else {
            NSLog(@"ERROR");
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"{\"error\" : \"file not deleted\"}"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
        }

    });
}

- (NSURL *)getFileURL:(NSString *)filepath
{
    // format the file path to be converted to url
    NSString *path = [NSString stringWithFormat:@"file://%@", filepath];

    // get url for file
    NSURL *fileURL = [NSURL URLWithString:path];

    return fileURL;
}

- (void)cleanupAndSendSuccess
{
    [self deleteFile];
    NSString *message;
    if (self.application) {
        message = [NSString stringWithFormat:@"{\"success\" : true, \"application\": \"%@\"}", self.application];
    } else {
        message = @"{\"success\" : true, \"application\": false}";
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
}

# pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
        willBeginSendingToApplication:(NSString *)application
{
    NSLog(@"WILL SEND WITH: %@", application);

    // store that we are sending with an application
    self.isSending = YES;
    self.application = application;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
           didEndSendingToApplication:(NSString *)application
{
    NSLog(@"END SENDING WITH APPLICATION: %@", self.application);
    
    [self cleanupAndSendSuccess];
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    NSLog(@"DISMISSED MENU");

    // only complete process here if we're not in the middle of sending to another app,
    // otherwise it will occur when the document is finished sending to that app
    if (!self.isSending) {
        [self cleanupAndSendSuccess];
    }
}

@end
