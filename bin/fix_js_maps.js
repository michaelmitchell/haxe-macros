#!/usr/bin/node
var async = require('async'),
	fs = require('fs'),
	path = require('path');

function find(dir, callback) {
	var me = this,
		results = [];

	fs.readdir(dir, function (error, files) {
		if (error) {
			return callback(error, results);
		}

		async.each(files, function (file, complete) {
			var filePath;

			filePath = path.resolve(dir, file);

			fs.stat(filePath, function (error, stats) {
				if (error) {
					return callback(error);
				}

				if (stats.isDirectory()) {
					read(filePath, function (error, files) {
						results = results.concat(files);

						complete();
					});
				}
				else if (stats.isFile() && file.match(/\.map$/)) {
					results.push(filePath);

					complete();
				}
				else {
					complete();
				}
			});
		}, function (error, result) {
			callback(null, results);
		});
	});
};

console.log('Fixing javascript maps');

var cwd = process.cwd();

cwd = cwd.replace('\\', '/') + '/';

find(cwd + '/build', function (error, results) {
	async.each(results, function (file, complete) {
		fs.readFile(file, 'utf8', function (error, data) {
			data = data.replace('"sourceRoot":"file://",', '"sourceRoot":"/",');
			data = data.replace(cwd, '');

			fs.writeFile(file, data, function(error) {
				console.log(file);

				complete();
			});
		});
	}, function (error, result) {
		console.log('complete');
	});
});