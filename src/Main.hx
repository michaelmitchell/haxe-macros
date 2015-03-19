@:build(macros.Async.build())
@:build(macros.Await.build())

class Main {

	static function main() {
	}

	@async static function foo(value: Int) {
		var a = 0;

		a = 1;

		@await bar(1);

		if (value == 1) {
			trace('before');
			trace('after');
		}
	}

	@async static function bar(value: Int) {
		return 1;
	}

}
