// Singleton
Martinelli = function(martinelli_uri) {
	// check to see if URI really points to a martinelli server
	// return nil or throw exception if not
	// else
	var server_uri = martinelli_uri;
	
	return {
		getDevices: function() {
			return; // server_uri/devices AS OBJECT
		},
		getDevice: function(device_name) {
			// check that it exists. if it doesn't: exception or nil
			return; // SerialDevice Object
		}
		createDevice: function(params) {
			// check that it exists. if it does: exception or nil
			return SerialDevice(params);
		},
		deleteDevice: function() {
			return;
		}
	};
};

// Power Constructor
function SerialDevice(params) {
	var self = new Object();

	self.read = function() {
		output = "";
		return output;
	};
	
	self.write = function(input) {};

	return self;
};

/*

Example usage:

my_server = Martinelli("http://some_uri:5000")

my_device = my_server.createDevice({
	"name": "blah",
	"baud_rate": 9600,
	"port": "COM1"
});

// infinite event-based loop
addEventListener("READ_EVENT", function() {
	my_device.write("13 A2", function() {
		alert(my_device.read(function() {
			dispatchEvent("READ_EVENT");
		}));
	};
}

// starts loop
dispatchEvent("READ_EVENT");

*/


Martinelli = {	
	initialize: function(device, uri) {
		var device_name = device;
		var serverLocation = "/";
		if (serverLocation !== undefined) {
			serverLocation = uri;
		}
	},
	create: function() { // PUT
		// TODO: is there a better way to do this?
		delimiter = $("#delimiter").val().toString()
		delimiter = delimiter.replace(/\\n/, "\n")
		delimiter = delimiter.replace(/\\r/, "\r")

		// TODO: validation
		put_data = {
			"port": $("#port").val().toString(),
			"baud_rate": parseInt($("#baud_rate").val()),
			"data_bits": parseInt($("#data_bits").val()),
			"stop_bits": parseInt($("#stop_bits").val()),
			"parity_bits": parseInt($("#parity_bits").val()),
			"delimiter": delimiter
		};
		data_string = $.toJSON(put_data);
		console.log("Request: PUT /device/" + device_name + "\r\n" + data_string);
	},
	read: function(jsonp) { // GET
		if(jsonp === true) {
			method = "GET";
			$.getJSON(serverLocation + "devices/" + device_name + "?method=" + method + "&callback=?",
				function(data) {
					console.log("Response: " + data.response);
					return data.reponse;
			});
		} else {
			$.ajax({
				type: "GET",
				url: serverLocation + "devices/" + device_name,
				contentType: "application/json; charset=UTF-8",
				data: data_string,
				complete: function (xhr, status) {
					if (xhr.status === 201) { // "Created"
						console.log("Response: " + xhr.responseText);
					} else if (xhr.status === 200) { // "OK"
						console.log("Response: " + xhr.responseText);
					} else {
						console.log("Error");
					}
				},
				success: function (data) {
					console.log("Response: " + data.response);
					return data.response;
				}
			});
		}
	},
	update: function(input) { // POST
		post_input = input;
		post_input = post_input.replace(/\\n/, "\n")
		post_input = post_input.replace(/\\r/, "\r")
		post_data = {
			input: post_input,
		};
		data_string = $.toJSON(post_data);
		
		if(jsonp === true) {
			method = "POST";
			encodeURIComponent(data_string);
			$.getJSON(serverLocation + "devices/" + device_name + "?method=" + method + "&body=" + data_string + "&callback=?",
				function(data) {
					consoleOutput("Response: " + $.toJSON(data));
			});
		}
	},
	delete: function() { // DELETE
		
	}
};
