var exec = require('child_process').exec,
	os = require('os'),
	fs = require('fs'),
	path = require('path'),
	util = require('util'),
	nircmdc = path.resolve(__dirname, '../bin/nircmdc.exe'); // http://www.nirsoft.net/utils/nircmd.html

module.exports = {
	cmd: {
		shot: function(path) {
			if (process.env.CAPTURE_COMMAND)
				return util.format(process.env.CAPTURE_COMMAND, path)
			else
				switch (os.platform()) {
					case 'win32': {
						return '"'+nircmdc+'" savescreenshot '+path;
					}
					case 'freebsd': {
						return 'scrot -s '+path;
					}
					case 'darwin': {
						return 'screencapture -i '+path;
					}
					case 'linux': {
						return 'import -window root '+path;
					}
					default: {
						throw new Error('unsupported platform');
					}
				}
		}
	},
	shot: function(filePath, callback) {
		exec(module.exports.cmd.shot(filePath), function(err) {
			if (err && os.platform() !== 'win32')
				callback(err);
			fs.exists(filePath, function(exists) {
				if (!exists)
					return callback(new Error('Screenshot failed'));
				callback(null, filePath);
			});
		});
	}
}
