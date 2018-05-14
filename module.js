var exec = require('child_process').exec,
	os = require('os'),
	fs = require('fs'),
	path = require('path');

(module.exports = {
	cmd: {
		shot: function(output, width) {
			switch (process.platform) {
				case 'win32': {
					return process.env['TEMP']+'\\shot.exe '+output+(width ? ' '+width : '');
				}
				case 'freebsd': {
					return 'scrot -s';
				}
				case 'darwin': {
					return 'screencapture -i';
				}
				case 'linux': {
					return 'import -window root '+(width ? ' -resize '+width+' -quality '+parseInt(width/20) : '')+' '+output;
				}
				default: {
					throw new Error('unsupported platform');
				}
			}
		},
		mousemove: function(x, y) {
			switch (process.platform) {
				case 'win32': {
					return process.env['TEMP']+'\\mouse.exe mousemove '+x+' '+y;
				}
				case 'linux': {
					return 'xte "mousemove '+x+' '+y+'"';
				}
				default: {
					throw new Error('unsupported platform');
				}
			}
		},
		mouseclick: function(code) {
			switch (process.platform) {
				case 'win32': {
					return process.env['TEMP']+'\\mouse.exe mouseclick '+code;
				}
				case 'linux': {
					return 'xte "mouseclick '+code+'"';
				}
				default: {
					throw new Error('unsupported platform');
				}
			}
		}
	},
	shot: function(output, width, callback) {
		if (!callback && width) {
			callback = width;
			width = null;
		}
		exec(module.exports.cmd.shot(output, width), function(err, res) {
			if (typeof(callback) == 'function') {
				if (err && (process.platform != 'win32'))
					return callback(err.message, null, err);
				fs.exists(output, function(exists) {
					if (!exists)
						return callback('Screenshot failed', null, new Error('Screenshot failed'));
					callback(null, output);
				});
			}
		});
	},
	mousemove: function(coords, callback) {
		exec(module.exports.cmd.mousemove(Math.round(coords.x), Math.round(coords.y)), function(err, res) {
			if (typeof(callback) == 'function')
				callback(err, res, err);
		});
	},
	mouseclick: function(key, callback) {
		var code = ['left', 'middle', 'right'].indexOf(key) + 1;
		if (code > 0)
			exec(module.exports.cmd.mouseclick(code), function(err, res) {
				if (typeof(callback) == 'function')
					callback(err, res, err);
			});
		else
			return callback('Detect key failed', null, new Error('Detect key failed'));
	},
	main: function() {
		console.log('Node-screen main');
		if (process.platform == 'win32')
			['shot', 'mouse'].map(function(bin) {
				fs.createReadStream(path.resolve(__dirname, 'bin/'+bin+'.exe')).pipe(fs.createWriteStream(process.env['TEMP']+'\\'+bin+'.exe').on('finish', function() {
					console.log('extract bin: '+bin);
				}));
			});
	}
}).main();
