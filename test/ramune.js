function trace(msg) {
	//if (frescolita.use_trace)
		//$.jGrowl(msg);
}

function cameraCommand(str) {
	subcommand = null;
	switch (str) {
		case "MOVE_UP":
			subcommand = VISCA.subcommand.panTiltDriveUp("05", "05")
			break;
		case "MOVE_DOWN":
			subcommand = VISCA.subcommand.panTiltDriveDown("05", "05");
			break;
		case "MOVE_LEFT":
			subcommand = VISCA.subcommand.panTiltDriveLeft("05", "05");
			break;
		case "MOVE_RIGHT":
			subcommand = VISCA.subcommand.panTiltDriveRight("05", "05");
			break;
		case "MOVE_HOME":
			subcommand = VISCA.subcommand.panTiltDriveHome();
			break;
		case "MOVE_STOP":
			subcommand = VISCA.subcommand.panTiltDriveStop("05", "05");
			break;
		case "ZOOM_IN":
			subcommand = VISCA.subcommand.camZoomTeleStandard();
			break;
		case "ZOOM_OUT":
			subcommand = VISCA.subcommand.camZoomWideStandard();
			break;
		case "ZOOM_STOP":
			subcommand = VISCA.subcommand.camZoomStop();
			break;
		default:
			// TODO: Throw error
			break;
		
	}
	WENDICall("/resources/devices/ptzcamera", VISCA.command(1, subcommand));
}

/**
 * Sends command to WENDI Server to switch S-Video Input
 *
 * @param string one-digit hexadecimal number
 */
function videoswitchCommand(str) {
	// TODO: Error checking. [1-F]
	WENDICall("/resources/devices/videoswitch", "01 8" + str + "81 81");
}

function WENDICall(resource, body) {
	$.ajax({
		type: "POST",
		url: "http://localhost:5000" + resource, // HACK: For non-served html testing
		//processData: false,
		data: body,
		dataType: "text",
		success: function(data, status) {
			//alert(data);
		}
	});
}