package com.stencyl.graphics.transitions;

import nme.display.BitmapData;
import nme.geom.ColorTransform;
import nme.display.Shape;

import com.stencyl.Engine;

import com.eclecticdesignstudio.motion.Actuate;
import com.eclecticdesignstudio.motion.easing.Linear;

class FadeOutTransition extends Transition
{
	public var color:Int;
	public var rect:Shape;
	
	public function new(duration:Float, color:Int=0xff000000)
	{
		super(duration);
		
		this.color = color;
		this.direction = Transition.IN;
	}
	
	override public function start()
	{
		rect = new Shape();
		rect.alpha = 0;
		var g = rect.graphics;
		g.beginFill(color);
		g.drawRect(0, 0, Engine.screenWidth, Engine.screenHeight);
		g.endFill();
		Engine.engine.transitionLayer.addChild(rect);
		
		Actuate.tween(rect, duration, {alpha:1}).ease(Linear.easeNone).onComplete(stop);
	}
	
	override public function stop()
	{
		if(rect != null)
		{
			Engine.engine.transitionLayer.removeChild(rect);
			rect = null;
		}
	}
}