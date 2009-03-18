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
	WENDICall("blah", VISCA.command(1, subcommand));
}

function WENDICall(resource, body) {
	$.ajax({
		type: "POST",
		url: "http://localhost:5000/resources/devices",
		//processData: false,
		data: body,
		dataType: "text",
		success: function(data, status) {
			//alert(data);
		}
	});
}