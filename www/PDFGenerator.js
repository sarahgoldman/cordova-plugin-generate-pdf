//
//  PDFGenerator.js
//  PDF Generator
//

// Private functions

// recursive function to clone an object. If a non object parameter
// is passed in, that parameter is returned and no recursion occurs.
function _cloneObject(obj) {
    if (obj === null || typeof obj !== 'object') {
        return obj;
    }

    var temp = obj.constructor(); // give temp the original obj's constructor
    for (var key in obj) {
        temp[key] = cloneObject(obj[key]);
    }

    return temp;
}

// helper function to convert original document to print-friendly format
function _getFormattedHtml(wrapperClass) {

    // Pull the document's css into a style tag, this will
    // need to be passed to the print formatter as well

    // open the tag
    var styleTag = "<style>";

    // for each stylesheet...
    for (var i = 0; i < document.styleSheets.length; i++) {
        // grab the rules array
        var rules = document.styleSheets[i].cssRules;
        // for each rule...
        for (var j = 0; j < rules.length; j++) {
          // add the rule text to the style tag
          styleTag += rules[j].cssText;
        }
    }

    // close the style tag
    styleTag += "</style>";

    var body = document.getElementsByTagName("body")[0];

    // Make a copy of the page content so when we format it,
    // it doesn't effect the actual page
    var content = body.cloneNode(true);

    // For each input in the content, record its current value into its value attribute
    var inputs = content.getElementsByTagName("input");
    for (var i = 0; i < inputs.length; i++) {
        inputs[i].setAttribute("value",inputs[i].value);
    }

    // We need to convert every canvas in the content
    // to an img for the printer.

    // For each canvas (we have to refer to the original dom for these)...
    var canvases = body.getElementsByTagName("canvas");

    for (var i = 0; i < canvases.length; i++) {
        // create a new image we are going to use to swap in
        var image = document.createElement('img');

        // check to see if there is a data-canvas-data-url attribute,
        // which is compatible with the ChartNew.js plugin, and use
        // that by default, otherwise just get snapshot of the live canvas
        if (canvases[i].getAttribute("data-canvas-data-url")) {
            image.src = canvases[i].getAttribute("data-canvas-data-url");
        } else {
            image.src = canvases[i].toDataURL("image/png");
        }

        // set the other image attributes based on the canvas
        image.id = canvases[i].id;
        image.width = canvases[i].width;
        image.height = canvases[i].height;
        // get the clone canvas from our content copy, and its parent
        var cloneCanvas = content.querySelector("#"+canvases[i].id),
            cloneCanvasParent = cloneCanvas.parentNode;
        // replace the clone canvas in the content with the new image
        cloneCanvasParent.replaceChild(image, cloneCanvas);
    }

    // return the styles and the content wrapped in a new body tag with the given css class
    return styleTag+'<body class="'+wrapperClass+'">'+content.innerHTML+'</body>';
}

// Plugin Class

/**
* @constructor
*/
var PDFGenerator = function () {
    // the class and method on the iOS side
    this.METHOD = 'generatePDF';
    this.CLASS = 'PDFGenerator';
};

PDFGenerator.prototype.generate = function(options) {

   console.log("PDF GENERATE JS");

   options = options || {};

   // get the options or use defaults
   var wrapperClass = options.wrapperClass || 'generatedPDF'; // default 'generatedPDF'

   var filename = options.filename || 'generated_pdf';

   var orientation = (options.orientation === 'landscape') ? options.orientation : 'portrait'; // default 'portrait'

   // make sure callbacks are functions or reset to null
   var successCallback = (options.success && typeof(options.success) === 'function') ? options.success : this.defaultCallback;

   var errorCallback = (options.error && typeof(options.error) === 'function') ? options.error : this.defaultCallback;

   // get a formatted html string of the page using our helper function
   var htmlString = _getFormattedHtml(wrapperClass);

   // set the arguments to be passed to the iOS method
   var args = [filename,htmlString,orientation];

   // make the call
   cordova.exec(successCallback, errorCallback, this.CLASS, this.METHOD, args);

};

PDFGenerator.prototype.defaultCallback = null;

// Plug in to Cordova
cordova.addConstructor(function () {
   if (!window.Cordova) {
	   window.Cordova = cordova;
   };

   if (!window.plugins) window.plugins = {};
   window.plugins.PDFGenerator = new PDFGenerator();
});
