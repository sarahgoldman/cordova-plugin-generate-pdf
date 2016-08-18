PDF Generator plugin for Cordova / PhoneGap
======================================================

This plugin brings up a dialog to share a PDF document generated from the current page. **iOS only**

##Example usage:
```
window.plugins.PDFGenerator.generate({
	filename: 'example', // used for pdf file name
	orientation: 'portrait', // 'portrait' or 'landscape', if none is specified 'portrait' will be used
	success: function(result){
		// result will include an application id if it was shared to another app
		// if it was shared via email or messages this value will be false
		data = JSON.parse(data);
		if (result.application) {
			console.log('shared to application: '+result.application);
		} else {
			console.log('sent');
		}
	},
	error: function(data){
		data = JSON.parse(data);
		console.log('failed: ' + data.error);
	}
});
```
