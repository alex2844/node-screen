# node-screen

Take a screenshot of your desktop interactively.

Available in Linux and Windows.

``` javascript
var screen = require('node-screen');
screen.shot('screen.png', function(err, res) {
	console.log(err || res);
});
```

## Installation
```
npm install -g node-screen
```
