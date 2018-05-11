var exec = require('child_process').exec,
	os = require('os'),
	fs = require('fs'),
	path = require('path');

module.exports = {
	pkg: [],
	cmd: {
		shot: function(output, width) {
			switch (os.platform()) {
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
			switch (os.platform()) {
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
			switch (os.platform()) {
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
	init: function(bin, callback) {
		if ((module.exports.pkg.indexOf(bin) > -1) || (os.platform() !== 'win32'))
			callback();
		else{
			module.exports.pkg.push(bin);
			fs.createReadStream(path.resolve(__dirname, 'bin/'+bin+'.exe')).pipe(fs.createWriteStream(process.env['TEMP']+'\\'+bin+'.exe').on('finish', callback));
		}
	},
	shot: function(output, width, callback) {
		if (!callback && width) {
			callback = width;
			width = null;
		}
		module.exports.init('shot', function() {
			exec(module.exports.cmd.shot(output, width), function(err, res) {
				if (typeof(callback) == 'function') {
					if (err && (os.platform() !== 'win32'))
						return callback(err.message, null, err);
					fs.exists(output, function(exists) {
						if (!exists)
							return callback('Screenshot failed', null, new Error('Screenshot failed'));
						callback(null, output);
					});
				}
			});
		});
	},
	mousemove: function(coords, callback) {
		module.exports.init('mouse', function() {
			exec(module.exports.cmd.mousemove(Math.round(coords.x), Math.round(coords.y)), function(err, res) {
				if (typeof(callback) == 'function')
					callback(err, res, err);
			});
		});
	},
	mouseclick: function(key, callback) {
		var code = ['left', 'middle', 'right'].indexOf(key) + 1;
		if (code > 0)
			module.exports.init('mouse', function() {
				exec(module.exports.cmd.mouseclick(code), function(err, res) {
					if (typeof(callback) == 'function')
						callback(err, res, err);
				});
			});
		else
			return callback('Detect key failed', null, new Error('Detect key failed'));
	}
}
