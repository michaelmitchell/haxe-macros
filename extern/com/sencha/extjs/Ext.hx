package com.sencha.extjs;

@:native("Ext")
extern class Ext {

	public static function create(name : Dynamic, options : Dynamic) :  Dynamic;

	public static function getBody() : String;

	public static function onReady(fn : Dynamic) : Void;

}