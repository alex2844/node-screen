var exec = require('child_process').exec,
	os = require('os'),
	fs = require('fs'),
	path = require('path');

module.exports = {
	cmd: {
		shot: function(path) {
			switch (os.platform()) {
				case 'win32': {
					// http://www.nirsoft.net/utils/nircmd.html
					return process.env['TEMP']+'\\nircmdc.exe savescreenshot '+path;
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
		(function(cb) {
			if (os.platform() !== 'win32')
				cb();
			else
				fs.createReadStream(path.resolve(__dirname, 'bin/nircmdc.exe')).pipe(fs.createWriteStream(process.env['TEMP']+'\\nircmdc.exe').on('finish', cb));
		})(function() {
			exec(module.exports.cmd.shot(filePath), function(err, res, stderr) {
				if (err && os.platform() !== 'win32')
					return callback(err.message, null, err);
				else
					fs.unlink(process.env['TEMP']+'\\nircmdc.exe', function() {});
				fs.exists(filePath, function(exists) {
					if (!exists)
						return callback('Screenshot failed', null, new Error('Screenshot failed'));
					callback(null, filePath);
				});
			});
		});
	}
}
