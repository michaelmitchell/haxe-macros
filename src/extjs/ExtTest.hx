package extjs;

import com.sencha.extjs.panel.Panel;
import macros.async.AsyncMethods;
import macros.sencha.ExtClass;

class ExtTest extends Panel implements ExtClass implements AsyncMethods {

	var config = {
		name: null
	};

	var mixins = {
		mymixin: MyMixin
	};

	public function new(?options) {
		super(options);

		ExtTest.extend();

		trace(this.mixins);
	}

}

class MyMixin {

	public function doMixinStuff() {
		trace('I am a mixed in function');
	}

}