package com.sencha.extjs.panel;

import com.sencha.extjs.mixin.Observable;

@:native("Ext.panel.Panel")
extern class Panel implements Observable {

	public static function mixin(name: String, klass: Dynamic): Void;

	public function new(options: Dynamic): Void;

	//Start: Ext.mixin.Observable
	public function on(eventName: String, method: Dynamic): Void;

	public function un(eventName: String, method: Dynamic): Void;
	//End: Ext.mixin.Observable

}
