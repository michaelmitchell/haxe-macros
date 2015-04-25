import macros.Async;

@:build(macros.Async.build())
class Main {

	static function main() {}

	@async public static function foo(i: Int): Int {
		if (i == 3) {
			throw "error";
		}
		else if (i == 4) {
			throw Main;
		}

		return -1;
	}

	@async public static function bar(i: Int) {
		return 1;
	}

}