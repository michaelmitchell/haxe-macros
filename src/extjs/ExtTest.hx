package extjs;

import com.sencha.extjs.panel.Panel;

class ExtTest extends Panel
	implements macros.sencha.Class
	implements macros.async.Methods {

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