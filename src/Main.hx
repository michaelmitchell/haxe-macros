import q.*;

@:build(macros.Async.build())
@:build(macros.Await.build())

class Main {

	static function main() {
		var result1 = @await foo('1');

		trace(result1);

		bar('2').then(function (result2) {
			trace(result2);
		});

		var result3 = @pwait bar('3');

		trace(result3);
	}
	
	@async static function foo(value: String): Int {
		var banana = 1;

		var boat = @await foo2(1);

		var pie = banana + boat;

		var more = @await foo3(2);

		var pie = pie + more + boat;

		return pie;
	}

	@async static function foo2(value: Int) {
		@await foo4();

		return value;
	}

	@async static function foo3(value: Int) {
		return value;
	}

	@async static function foo4() {
	}

	static function bar(value: String): Promise {
		var deferred = Q.defer();

		deferred.resolve('hello world');

		return deferred.promise;
	}

}
