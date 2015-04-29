package com.sencha.extjs.panel;

@:native("Ext.panel.Panel")
extern class Panel {

	public static function mixin(name: String, klass: Dynamic): Void;

	public function new(options: Dynamic): Void;

	public function on(eventName: String, method: Dynamic): Void;

}
