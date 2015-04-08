/**
import com.dongxiguo.continuation.Continuation;

@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":async"))
/**/

/**/
import macros.Await;

@:build(macros.Async.build())
@:build(macros.Await.build())
/**/

class Main {

	static function main() {

	}

	public static function foo(i: Int) {
		trace('before all');

		do {
			trace('before');

			if (i == 1) {
				@await bar(1);

				trace(1);

				break;

				trace(2);
			}

			if (i == 2) {
				continue;
			}

			trace('after');
		}
		while (i < 0);
		
		trace('after all');
	}

	@async static function bar(i: Int) {
		return i;
	}

}

class Error {

	var message: String;
	
	public function new(m: String) {
		this.message = m;
	}

}
