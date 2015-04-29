package extjs;

import com.sencha.extjs.panel.Panel;

class ExtTest extends Panel
	implements macros.sencha.Class
	implements macros.sencha.Events
	implements macros.async.Methods {

	@on('afterrender') function onAfterRender() {

	}

	@on('beforerender') @async function foo(i) {
		return i;
	}

}