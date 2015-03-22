@:build(macros.Async.build())
@:build(macros.Await.build())

class Main {

	static function main() {
		trace(0);

		return 1;

		trace(1);

		var b = 1;

	}

	@async function foo(i: Int) {
		if (i == 1) {
			throw new Error('This is an error');
		}
		else {
			throw new AnotherError('another error');
		}

		return i;
	}

}

class Error {

	var message: String;
	
	public function new(m: String) {
		this.message = m;
	}

}

class AnotherError extends Error {}
