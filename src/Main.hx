import q.*;

@:build(macros.Async.build())
class Main {

	static function main() {
		var result1 = @await foo('1');

		trace(result1);

		var result2 = @pwait bar('2');

		trace(result2);
	}
	
	@async static function foo(value: String) {
		return value;
	}

	static function bar(value: String): Promise {
		var deferred = Q.defer();

		deferred.resolve('hello world');

		return deferred.promise;
	}

}
