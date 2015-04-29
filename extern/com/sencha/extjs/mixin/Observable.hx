package com.sencha.extjs.mixin;

@:native("Ext.mixin.Observable")
extern interface Observable {

	//Start: Ext.mixin.Observable
	public function on(eventName: String, method: Dynamic): Void;

	public function un(eventName: String, method: Dynamic): Void;
	//End: Ext.mixin.Observable

}
