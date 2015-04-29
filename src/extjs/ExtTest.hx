package extjs;

import com.sencha.extjs.ExtClass;
import com.sencha.extjs.panel.Panel;

import macros.ExtJS;

@:build(macros.ExtJS.build())
class ExtTest extends Panel {

	var config = {
		name: null
	};

	var mixins = {
		mymixin: MyMixin
	};

	public function new(options) {
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