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
		while(i == 1) {
			@await bar(1);

			trace('bar1');
		}

		do {
			@await bar(2);

			trace('bar2');
		}
		while(i == 2);

		/*for (i in 0...10) {
			trace(i);
		}*/
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
