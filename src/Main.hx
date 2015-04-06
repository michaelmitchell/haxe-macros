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
		@await bar(0);

		if (i == 0) {
			trace(1);
		}
		else if (i == 1) {
			trace('before');
			
			if (i == 2) {
				@await bar(0);
			}

			trace('after');
		}
		else {
			@await bar(1);

			trace(3);
		}

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
