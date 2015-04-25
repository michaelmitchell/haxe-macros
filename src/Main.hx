import macros.Async;

@:build(macros.Async.build())
class Main {

	static function main() {}

	public static function foo(i: Int) {
		i = @await bar(i);

		if (i == 2) {
			throw "error";
		}

		if (i == 3) {
			throw "error";
		}

		return -1;
	}

	@async public static function bar(i: Int) {
		return 1;
	}

}