package ;

import com.sencha.extjs.Ext;
import com.sencha.extjs.ExtClass;

import extjs.ExtTest;
import macros.Async;


@:build(macros.Async.build())
class Main {

	static function main() {
		@await foo(1);

		Ext.onReady(function () {
			var panel = new ExtTest({
				renderTo: Ext.getBody(),
				width: 640,
				height: 480,
				bodyPadding: 5,
				html : 'Hello <b>World</b>...'
			});

			trace(panel);
		});
	}

	@async public static function foo(i: Int) {
		trace(1);

		@await bar(1);

		trace(2);

		var a = @await bar(2);

		trace(3);

		if (i == 3) {
			return 3;
		}

		var b;

		b = @await bar(3);

		trace(4);

		if (i == 1) {
			@await bar(5);

			trace(5);
		}
		else if(i == 2) {
			@await bar(6);

			trace(6);
		}
		else {
			@await bar(7);

			trace(7);
		}

		for (x in 0...2) {
			@await bar(8);

			trace(8);
		}

		var x = 2;

		while (--x >= 0) {
			@await bar(9);

			if (i == 1) {
				i++;
				continue;
			}

			trace(9);
		}

		var x = 2;

		do {
			@await bar(10);

			trace(10);

			if (i == 2) {
				break;
			}
		}
		while (--x >= 0);

		@fork for (x in 0...2) {
			@await bar(11);

			trace(11);
		}

		var x = 2;

		@fork while (--x >= 0) {
			@await bar(12);

			trace(12);
		}

		var x = 2;

		@fork do {
			@await bar(13);

			trace(13);
		}
		while (--x >= 0);

		function name() {
			return 1;
		}

		@async function name() {
			return 1;
		}

		var fn = function () {
			return 1;
		};

		try {
			trace(14);

			if (i == 1) {
				throw "error";
			}
		}
		catch (e: String) {
			trace(5);
		}

		switch (i) {
			case 0: {
				trace(0);
			}
			case 1: {
				trace(1);
			}
			default: {
				trace(2);
			}
		}

		switch (i) {
			case 0: {
				@await bar(0);

				trace(0);
			}
			case 1: {
				@await bar(1);

				trace(1);
			}
			default: {
				trace(2);
			}
		}

		return -1;
	}

	public static function bar(i: Int, __return) {
		untyped __js__('setImmediate')(function () {
			__return(null, i);
		});
	}

}