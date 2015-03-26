/**
import com.dongxiguo.continuation.Continuation;

@:build(com.dongxiguo.continuation.Continuation.cpsByMeta("async"))
/**/

/**/
@:build(macros.Async.build())
@:build(macros.Await.build())
/**/

class Main {

	static function main() {
	}

	@async public static function foo(i: Int) {
		if (i == 2) {
			trace('before');

			@await foo(2);

			trace('after');
		}
		else if(i ==3) {
			trace('here');

		}
		else {
			trace('there');

			return 3;
		}

		return i;
	}

	static function bar() {

	}

}

class Error {

	var message: String;
	
	public function new(m: String) {
		this.message = m;
	}

}
