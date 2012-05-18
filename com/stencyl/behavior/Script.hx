package com.stencyl.behavior;

#if !js
import nme.net.SharedObject;
import nme.net.SharedObjectFlushStatus;
#end

import nme.ui.Mouse;
import nme.events.Event;
import nme.net.URLLoader;
import nme.net.URLRequest;
import nme.net.URLRequestMethod;
import nme.net.URLVariables;
import nme.Lib;

import nme.display.Graphics;

import com.stencyl.models.Actor;
import com.stencyl.models.actor.Group;
import com.stencyl.models.Scene;
import com.stencyl.models.GameModel;
import com.stencyl.models.scene.Layer;
import com.stencyl.models.Region;
import com.stencyl.models.Terrain;
import com.stencyl.graphics.transitions.Transition;
import com.stencyl.models.actor.ActorType;
import com.stencyl.models.Font;

import com.stencyl.models.Sound;
import com.stencyl.models.SoundChannel;

import com.stencyl.utils.HashMap;

import com.eclecticdesignstudio.motion.Actuate;
import com.eclecticdesignstudio.motion.easing.Linear;

import box2D.dynamics.joints.B2Joint;
import box2D.common.math.B2Vec2;
import box2D.dynamics.B2World;

#if flash
import com.stencyl.utils.Kongregate;
#end

//Actual scripts extend from this
class Script 
{
	//*-----------------------------------------------
	//* Data
	//*-----------------------------------------------
	
	public var wrapper:Behavior;
	
	public var engine:Engine;
	public var scene:Engine; //for compatibility - we'll remove it later
	
	public var propertyChangeListeners:Hash<Dynamic>;
	public var equalityPairs:HashMap<Dynamic, Dynamic>;
		
		
	//*-----------------------------------------------
	//* Constants
	//*-----------------------------------------------
	
	public static var FRONT:Int = 0;
	public static var MIDDLE:Int = 1;
	public static var BACK:Int = 2;
	
	public static var CHANNELS:Int = 32;
	
	
	//*-----------------------------------------------
	//* Data
	//*-----------------------------------------------
	
	public static var lastCreatedActor:Actor = null;
	public static var lastCreatedJoint:B2Joint = null;
	public static var lastCreatedRegion:Region = null;
	public static var lastCreatedTerrainRegion:Terrain = null;
	
	public static var mpx:Float = 0;
	public static var mpy:Float = 0;
	public static var mrx:Float = 0;
	public static var mry:Float = 0;
		
		
	//*-----------------------------------------------
	//* Display Names
	//*-----------------------------------------------
	
	public var nameMap:Hash<Dynamic>;
		
		
	//*-----------------------------------------------
	//* Init
	//*-----------------------------------------------
	
	public function new(engine:Engine) 
	{
		this.engine = this.scene = engine;
		
		nameMap = new Hash<Dynamic>();	
		propertyChangeListeners = new Hash<Dynamic>();
		equalityPairs = new HashMap<Dynamic, Dynamic>();
	}		

	//*-----------------------------------------------
	//* Internals
	//*-----------------------------------------------
	
	public inline function asBoolean(o:Dynamic):Bool
	{
		return (o == true || o == "true");
	}
	
	public static inline function strCompare(one:String, two:String, whichWay:Int):Bool
	{
		if(whichWay < 0)
		{
			return strCompareBefore(one, two);
		}
		
		else
		{
			return strCompareAfter(one, two);
		}
	}
	
	public static inline function strCompareBefore(a:String, b:String):Bool
	{
		return(a < b);
	} 
	
	public static inline function strCompareAfter(a:String, b:String):Bool
	{
		return(a > b);
	} 
	
	public inline function asNumber(o:Dynamic):Float
	{
		if(Std.is(o, String))
		{
			return Std.parseFloat(o);
		}
		
		else if(Std.is(o, Float) || Std.is(o, Int))
		{
			return o;
		}
		
		//Can't do it - return junk
		else
		{
			trace(o + " is not a number!");
			return 0;
		}
	}
		
	public function toInternalName(displayName:String)
	{
		if(nameMap == null)
		{
			return displayName;
		}
		
		var newName:String = nameMap.get(displayName);
		
		if(newName == null)
		{
			// the name is already internal, so just return it.
			return displayName;
		}
		
		else
		{
			return newName;
		}
	}
	
	public function forwardMessage(msg:String)
	{
	}
	
	public function clearListeners()
	{
		propertyChangeListeners = new Hash<Dynamic>();
	}
	
	//*-----------------------------------------------
	//* Basics
	//*-----------------------------------------------

	public function init()
	{
	}
	
	public function update(elapsedTime:Float)
	{
	}
	
	public function draw(g:Graphics, x:Int, y:Int)
	{
	}
	
	//*-----------------------------------------------
	//* Event Registration
	//*-----------------------------------------------
	
	//Intended for auto code generation. Programmers should use init/update/draw instead.
	
	public function addWhenCreatedListener(a:Actor, func:Dynamic->Void)
	{			
		var isActorScript = Std.is(this, ActorScript);
		
		if(a == null)
		{
			trace("Error in " + wrapper.classname + ": Cannot add listener function to null actor.");
			return;
		}
		
		a.whenCreatedListeners.push(func);
		
		if(isActorScript)
		{
			cast(this, ActorScript).actor.registerListener(a.whenCreatedListeners, func);
		}
	}
	
	public function addWhenKilledListener(a:Actor, func:Dynamic->Void)
	{	
		var isActorScript = Std.is(this, ActorScript);
		
		if(a == null)
		{
			trace("Error in " + wrapper.classname + ": Cannot add listener function to null actor.");
			return;
		}
		
		a.whenKilledListeners.push(func);
		
		if(isActorScript)
		{
			cast(this, ActorScript).actor.registerListener(a.whenKilledListeners, func);
		}	
	}
					
	public function addWhenUpdatedListener(a:Actor, func:Float->Dynamic->Void)
	{
		var isActorScript = Std.is(this, ActorScript);
	
		if(a == null)
		{
			if(isActorScript)
			{
				a = cast(this, ActorScript).actor;
			}
		}
								
		var listeners:Array<Dynamic>;
		
		if(a != null)
		{
			listeners = a.whenUpdatedListeners;				
		}	
				
		else
		{
			listeners = engine.whenUpdatedListeners;
		}
		
		listeners.push(func);
						
		if(isActorScript)
		{
			cast(this, ActorScript).actor.registerListener(listeners, func);
		}
	}
	
	public function addWhenDrawingListener(a:Actor, func:Graphics->Int->Int->Dynamic->Void)
	{
		var isActorScript = Std.is(this, ActorScript);
	
		if(a == null)
		{
			if(isActorScript)
			{
				a = cast(this, ActorScript).actor;
			}
		}
								
		var listeners:Array<Dynamic>;
		
		if(a != null)
		{
			listeners = a.whenDrawingListeners;				
		}	
				
		else
		{
			listeners = engine.whenDrawingListeners;
		}
		
		listeners.push(func);
						
		if(isActorScript)
		{
			cast(this, ActorScript).actor.registerListener(listeners, func);
		}
	}
	
	//enters region
	//exits region
	
	public function addActorPositionListener(a:Actor, func:Dynamic->Dynamic->Dynamic->Dynamic->Array<Dynamic>->Void)
	{
		if(a == null)
		{
			trace("Error in " + wrapper.classname + ": Cannot add listener function to null actor.");
			return;
		}
		
		a.positionListeners.push(func);
								
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(a.positionListeners, func);
		}
	}
	
	public function addActorTypeGroupPositionListener(obj:Dynamic, func:Actor->Dynamic->Dynamic->Dynamic->Dynamic->Array<Dynamic>->Void)
	{
		if(!engine.typeGroupPositionListeners.exists(obj))
		{
			engine.typeGroupPositionListeners.set(obj, new Array<Dynamic>());
		}
		
		var listeners = cast(engine.typeGroupPositionListeners.get(obj), Array<Dynamic>);
		listeners.push(func);		
		
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(listeners, func);
		}
	}
	
	public function addKeyStateListener(key:String, func:Dynamic->Dynamic->Array<Dynamic>->Void)
	{			
		if(!engine.whenKeyPressedListeners.exists(key))
		{
			engine.whenKeyPressedListeners.set(key, new Array<Dynamic>());
		}
		
		var listeners = engine.whenKeyPressedListeners.get(key);
		listeners.push(func);
								
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(listeners, func);
		}
	}
	
	public function addMousePressedListener(func:Array<Dynamic>->Void)
	{
		engine.whenMousePressedListeners.push(func);
		
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(engine.whenMousePressedListeners, func);
		}
	}
	
	public function addMouseReleasedListener(func:Array<Dynamic>->Void)
	{
		engine.whenMouseReleasedListeners.push(func);
		
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(engine.whenMouseReleasedListeners, func);
		}
	}
	
	public function addMouseMovedListener(func:Array<Dynamic>->Void)
	{
		engine.whenMouseMovedListeners.push(func);
		
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(engine.whenMouseMovedListeners, func);
		}
	}
	
	public function addMouseDraggedListener(func:Array<Dynamic>->Void)
	{
		engine.whenMouseDraggedListeners.push(func);
		
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(engine.whenMouseDraggedListeners, func);
		}
	}
	
	public function addMouseOverActorListener(a:Actor, func:Int->Array<Dynamic>->Void)
	{	
		if(a == null)
		{
			trace("Error in " + wrapper.classname +": Cannot add listener function to null actor.");
			return;
		}
		
		a.mouseOverListeners.push(func);
		
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(a.mouseOverListeners, func);
		}
	}
	
	public function addPropertyChangeListener(propertyKey:String, propertyKey2:String, func:Dynamic->Array<Dynamic>->Void)
	{
		if(!propertyChangeListeners.exists(propertyKey))
		{
			propertyChangeListeners.set(propertyKey, new Array<Dynamic>());
		}
		
		//Equality block needs to be added to two listener lists
		if(propertyKey2 != null && !propertyChangeListeners.exists(propertyKey2))
		{
			propertyChangeListeners.set(propertyKey2, new Array<Dynamic>());
		}
		
		var listeners = propertyChangeListeners.get(propertyKey);
		var listeners2 = propertyChangeListeners.get(propertyKey2);
		
		listeners.push(func);			
		
		if(propertyKey2 != null)
		{
			listeners2.push(func);
			
			//If equality, keep note of other listener list
			var arr = new Array<Dynamic>();
			arr.push(listeners);
			arr.push(listeners2);
			equalityPairs.set(func, arr);
		}
		
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(listeners, func);
			
			if(propertyKey2 != null)
			{
				cast(this, ActorScript).actor.registerListener(listeners2, func);
			}
		}
	}
	
	public function propertyChanged(propertyKey:String, property:Dynamic)
	{
		var listeners = propertyChangeListeners.get(propertyKey);
		
		if(listeners != null)
		{
			var r = 0;
		
			while(r < listeners.length)
			{
				try
				{
					var f:Dynamic->Array<Dynamic>->Void = listeners[r];			
					f(property, listeners);
					
					if(com.stencyl.utils.Utils.indexOf(listeners, f) == -1)
					{
						r--;
						
						//If equality, remove from other list as well
						if(equalityPairs.get(f) != null)
						{
							for(list in cast(equalityPairs.get(f), Array<Dynamic>))
							{
								if(list != listeners)
								{
									list.splice(com.stencyl.utils.Utils.indexOf(list, f), 1);
								}
							}
							
							equalityPairs.delete(f);
						}
					}
				}
				
				catch(e:String)
				{
					trace(e);
				}
				
				r++;
			}
		}
	}
	
	//collision
	//scene collision
	
	public function addWhenTypeGroupCreatedListener(obj:Dynamic, func:Actor->Array<Dynamic>->Void)
	{
		if(!engine.whenTypeGroupCreatedListeners.exists(obj))
		{
			engine.whenTypeGroupCreatedListeners.set(obj, new Array<Dynamic>());
		}
		
		var listeners = engine.whenTypeGroupCreatedListeners.get(obj);
		listeners.push(func);		
		
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(listeners, func);
		}
	}
	
	public function addWhenTypeGroupKilledListener(obj:Dynamic, func:Actor->Array<Dynamic>->Void)
	{
		if(!engine.whenTypeGroupDiesListeners.exists(obj))
		{
			engine.whenTypeGroupDiesListeners.set(obj, new Array<Dynamic>());
		}
		
		var listeners = engine.whenTypeGroupDiesListeners.get(obj);
		listeners.push(func);		
		
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(listeners, func);
		}
	}
	
	public function addSoundListener(obj:Dynamic, func:Array<Dynamic>->Void)
	{
		if(!engine.soundListeners.exists(obj))
		{
			engine.soundListeners.set(obj, new Array<Dynamic>());
		}
		
		var listeners:Array<Dynamic> = engine.soundListeners.get(obj);
		listeners.push(func);
		
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(listeners, func);
		}
	}
	
	public function addFocusChangeListener(func:Bool->Array<Dynamic>->Void)
	{						
		engine.whenFocusChangedListeners.push(func);
		
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(engine.whenFocusChangedListeners, func);
		}
	}
	
	public function addPauseListener(func:Bool->Array<Dynamic>->Void)
	{						
		engine.whenPausedListeners.push(func);
		
		if(Std.is(this, ActorScript))
		{
			cast(this, ActorScript).actor.registerListener(engine.whenPausedListeners, func);
		}
	}
	
	//*-----------------------------------------------
	//* Regions
	//*-----------------------------------------------
	
	//wait for Box2D
	
	//*-----------------------------------------------
	//* Terrain
	//*-----------------------------------------------
	
	//wait for Box2D
	
	//*-----------------------------------------------
	//* Behavior Status
	//*-----------------------------------------------
	
	/**
	 * Check if the current scene contains the given Behavior (by name)
	 *
	 * @param	behaviorName	The display name of the <code>Behavior</code>
	 * 
	 * @return	True if the scene contains the Behavior
	 */
	public function sceneHasBehavior(behaviorName:String):Bool
	{
		return engine.behaviors.hasBehavior(behaviorName);
	}
	
	/**
	 * Enable the given Behavior (by name) for the current scene
	 *
	 * @param	behaviorName	The display name of the <code>Behavior</code>
	 */
	public function enableBehaviorForScene(behaviorName:String)
	{
		engine.behaviors.enableBehavior(behaviorName);
	}
	
	/**
	 * Disable the given Behavior (by name) for the current scene
	 *
	 * @param	behaviorName	The display name of the <code>Behavior</code>
	 */
	public function disableBehaviorForScene(behaviorName:String)
	{
		engine.behaviors.disableBehavior(behaviorName);
	}
	
	/**
	 * Check if the current scene contains the given Behavior (by name) and if said behavior is enabled.
	 *
	 * @param	behaviorName	The display name of the <code>Behavior</code>
	 * 
	 * @return	True if the scene contains the Behavior AND said behavior is enabled
	 */
	public function isBehaviorEnabledForScene(behaviorName:String):Bool
	{
		return engine.behaviors.isBehaviorEnabled(behaviorName);
	}
	
	/**
	 * Disable the current Behavior. The rest of this script will continue running, and cessation
	 * happens for any future run.
	 */
	public function disableThisBehavior()
	{
		engine.behaviors.disableBehavior(wrapper.name);
	}
	
			
	//*-----------------------------------------------
	//* Messaging
	//*-----------------------------------------------
	
	/**
	 * Get the attribute value for a behavior attached to the scene.
	 */
	public function getValueForScene(behaviorName:String, attributeName:String):Dynamic
	{
		return engine.getValue(behaviorName, attributeName);
	}
	
	/**
	 * Set the value for an attribute of a behavior in the scene.
	 */
	public function setValueForScene(behaviorName:String, attributeName:String, value:Dynamic)
	{
		engine.setValue(behaviorName, attributeName, value);
	}
	
	/**
	 * Send a messege to this scene with optional arguments.
	 */
	public function shoutToScene(msg:String, args:Array<Dynamic> = null):Dynamic
	{
		return engine.shout(msg, args);
	}
	
	/**
	 * Send a messege to a behavior in this scene with optional arguments.
	 */		
	public function sayToScene(behaviorName:String, msg:String, args:Array<Dynamic> = null):Dynamic
	{
		return engine.say(behaviorName, msg, args);
	}
	
	//*-----------------------------------------------
	//* Game Attributes
	//*-----------------------------------------------
	
	/**
	 * Set a game attribute (pass a Number/Text/Boolean/List)
	 */		
	public function setGameAttribute(name:String, value:Dynamic)
	{
		engine.setGameAttribute(name, value);
	}
	
	/**
	 * Get a game attribute (Returns a Number/Text/Boolean/List)
	 */	
	public function getGameAttribute(name:String):Dynamic
	{
		return engine.getGameAttribute(name);
	}
		
	//*-----------------------------------------------
	//* Timing
	//*-----------------------------------------------
		
	/**
	 * Runs the given function after a delay.
	 *
	 * @param	delay		Delay in execution (in milliseconds)
	 * @param	toExecute	The function to execute after the delay
	 */
	public function runLater(delay:Float, toExecute:TimedTask->Void, actor:Actor = null):TimedTask
	{
		var t:TimedTask = new TimedTask(toExecute, Std.int(delay), false, actor);
		engine.addTask(t);

		return t;
	}
	
	/**
	 * Runs the given function periodically (every n seconds).
	 *
	 * @param	interval	How frequently to execute (in milliseconds)
	 * @param	toExecute	The function to execute after the delay
	 */
	public function runPeriodically(interval:Float, toExecute:TimedTask->Void, actor:Actor = null):TimedTask
	{
		var t:TimedTask = new TimedTask(toExecute, Std.int(interval), true, actor);
		engine.addTask(t);
		
		return t;
	}
	
	public function getStepSize():Int
	{
		return Engine.STEP_SIZE;
	}
	
	//*-----------------------------------------------
	//* Scene
	//*-----------------------------------------------
	
	/**
	 * Get the current scene.
	 *
	 * @return The current scene
	 */
	public function getScene():Scene
	{
		return engine.scene;
	}
	
	/**
	 * Get the ID of the current scene.
	 *
	 * @return The ID current scene
	 */
	public function getCurrentScene():Int
	{
		return getScene().ID;
	}
	
	/**
	 * Get the ID of a scene by name.
	 *
	 * @return The ID current scene or 0 if it doesn't exist.
	 */
	public function getIDForScene(sceneName:String):Int
	{
		for(s in GameModel.get().scenes)
		{
			if(sceneName == s.name)
			{
				return s.ID;	
			}
		}
		
		return 0;
	}
	
	/**
	 * Get the name of the current scene.
	 *
	 * @return The name of the current scene
	 */
	public function getCurrentSceneName():String
	{
		return getScene().name;
	}
	
	/**
	 * Get the width (in pixels) of the current scene.
	 *
	 * @return width (in pixels) of the current scene
	 */
	public function getSceneWidth():Int
	{
		return getScene().sceneWidth;
	}
	
	/**
	 * Get the height (in pixels) of the current scene.
	 *
	 * @return height (in pixels) of the current scene
	 */
	public function getSceneHeight():Int
	{
		return getScene().sceneHeight;
	}
	
	/**
	 * Get the width (in tiles) of the current scene.
	 *
	 * @return width (in tiles) of the current scene
	 */
	public function getTileWidth():Int
	{
		return getScene().tileWidth;
	}
	
	/**
	 * Get the height (in tiles) of the current scene.
	 *
	 * @return height (in tiles) of the current scene
	 */
	public function getTileHeight():Int
	{
		return getScene().tileHeight;
	}
	
	//*-----------------------------------------------
	//* Scene Switching
	//*-----------------------------------------------
	
	/**
	 * Reload the current scene, using an exit transition and then an enter transition.
	 *
	 * @param	leave	exit transition
	 * @param	enter	enter transition
	 */
	public function reloadCurrentScene(leave:Transition=null, enter:Transition=null)
	{
		engine.switchScene(getCurrentScene(), leave, enter);
	}
	
	/**
	 * Switch to the given scene, using an exit transition and then an enter transition.
	 *
	 * @param	sceneID		IT of the scene to switch to
	 * @param	leave		exit transition
	 * @param	enter		enter transition
	 */
	public function switchScene(sceneID:Int, leave:Transition=null, enter:Transition=null)
	{
		engine.switchScene(sceneID, leave, enter);
	}
	
	public function createFadeOut(duration:Float, color:Int=0xff000000):Transition
	{
		return new com.stencyl.graphics.transitions.FadeOutTransition(duration, color);
	}
	
	public function createFadeIn(duration:Float, color:Int=0xff000000):Transition
	{
		return new com.stencyl.graphics.transitions.FadeInTransition(duration, color);
	}
	
	public function createCircleOut(duration:Int, color:Int=0xff000000):Transition
	{
		return new com.stencyl.graphics.transitions.CircleTransition(Transition.OUT, duration, color);
	}
		
	public function createCircleIn(duration:Int, color:Int=0xff000000):Transition
	{
		return new com.stencyl.graphics.transitions.CircleTransition(Transition.IN, duration, color);
	}
	
	//*-----------------------------------------------
	//* Tile Layers
	//*-----------------------------------------------
	
	/**
     * Force the given layer to show.
     *
     * @param   layerID     ID of the layer
     */
    public function getLayer(layerID:Int):Layer
    {
    	return engine.layers.get(layerID);
    }
	
	/**
	 * Force the given layer to show.
	 *
	 * @param	layerID		ID of the layer
	 */
	public function showTileLayer(layerID:Int)
	{
		engine.layers.get(layerID).alpha = 255;
		engine.actorsPerLayer.get(layerID).alpha = 255;
	}
	
	/**
	 * Force the given layer to become invisible.
	 *
	 * @param	layerID		ID of the layer
	 */
	public function hideTileLayer(layerID:Int)
	{
		engine.layers.get(layerID).alpha = 0;
		engine.actorsPerLayer.get(layerID).alpha = 0;
	}
	
	/**
	 * Force the given layer to fade to the given opacity over time, applying the easing function.
	 *
	 * @param	layerID		ID of the layer
	 * @param	alphaPct	the opacity (0-255) to fade to
	 * @param	duration	the duration of the fading (in milliseconds)
	 * @param	easing		easing function to apply. Linear (no smoothing) is the default.
	 */
	public function fadeTileLayerTo(layerID:Int, alphaPct:Float, duration:Float, easing:Dynamic = null)
	{
		if(easing == null)
		{
			easing = Linear.easeNone;
		}
	
		Actuate.tween(engine.layers.get(layerID), duration, {alpha:alphaPct}).ease(easing);
		Actuate.tween(engine.actorsPerLayer.get(layerID), duration, {alpha:alphaPct}).ease(easing);
	}
	
	//*-----------------------------------------------
	//* Camera
	//*-----------------------------------------------
	
	/**
	 * x-position of the camera
	 *
	 * @return The x-position of the camera
	 */
	public function getScreenX():Float
	{
		return Math.abs(Engine.cameraX);
	}
	
	/**
	 * y-position of the camera
	 *
	 * @return The y-position of the camera
	 */
	public function getScreenY():Float
	{
		return Math.abs(Engine.cameraY);
	}
	
	/**
	 * Returns the actor that represents the camera
	 *
	 * @return The actor representing the camera
	 */
	public function getCamera():Actor
	{
		return engine.camera;
	}
	
	//*-----------------------------------------------
	//* Input
	//*-----------------------------------------------
	
	//Programmers: Use the Input class directly. It's much nicer.
	//We're keeping this API around for compatibility for now.
	
	public function isCtrlDown():Bool
	{
		return Input.check(Engine.INTERNAL_CTRL);
	}
	
	public function isShiftDown():Bool
	{
		return Input.check(Engine.INTERNAL_SHIFT);
	}
	
	public function simulateKeyPress(abstractKey:String)
	{
		Input.simulateKeyPress(abstractKey);
	}
	
	public function simulateKeyRelease(abstractKey:String)
	{
		Input.simulateKeyRelease(abstractKey);
	}

	public function isKeyDown(abstractKey:String):Bool
	{
		return Input.check(abstractKey);
	}

	public function isKeyPressed(abstractKey:String):Bool
	{
		return Input.pressed(abstractKey);
	}
	
	public function isKeyReleased(abstractKey:String):Bool
	{
		return Input.released(abstractKey);
	}
	
	public function isMouseDown():Bool
	{
		return Input.mouseDown;
	}
	
	public function isMousePressed():Bool
	{
		return Input.mousePressed;
	}

	public function isMouseReleased():Bool
	{
		return Input.mouseReleased;
	}
	
	public function getMouseX():Float
	{
		return Engine.stage.mouseX;
	}

	public function getMouseY():Float
	{
		return Engine.stage.mouseY;
	}
	
	public function getMouseWorldX():Float
	{
		return Engine.stage.mouseX + Engine.cameraY;
	}
	
	public function getMouseWorldY():Float
	{
		return Engine.stage.mouseY + Engine.cameraX;
	}
	
	public function getMousePressedX():Float
	{
		return mpx;
	}
	
	public function getMousePressedY():Float
	{
		return mpy;
	}

	public function getMouseReleasedX():Float
	{
		return mrx;
	}
	
	public function getMouseReleasedY():Float
	{
		return mry;
	}
	
	/*public function setCursor(graphic:Class=null, xOffset:int=0, yOffset:int=0);
	{
		FlxG.mouse.show(graphic, xOffset, yOffset);
	}*/

	public function showCursor()
	{
		Mouse.show();
	}

	public function hideCursor()
	{
		Mouse.hide();
	}
	
	//*-----------------------------------------------
	//* Actor Creation
	//*-----------------------------------------------
	
	public function getLastCreatedActor():Actor
	{
		return lastCreatedActor;
	}
	
	public function createActor(type:ActorType, x:Float, y:Float, layerConst:Int):Actor
	{
		var a:Actor = engine.createActorOfType(type, x, y, layerConst);
		Script.lastCreatedActor = a;
		return a;
	}	
		
	public function createRecycledActor(type:ActorType, x:Float, y:Float, layerConst:Int):Actor
	{
		var a:Actor = engine.getRecycledActorOfType(type, x, y, layerConst);		
		Script.lastCreatedActor = a;	
		return a;
	}
	
	public function recycleActor(a:Actor)
	{
		engine.recycleActor(a);
	}
		
	public function createActorInNextScene(type:ActorType, x:Float, y:Float, layerConst:Int)
	{
		engine.createActorInNextScene(type, x, y, layerConst);
	}
	
	//*-----------------------------------------------
	//* Actor-Related Getters
	//*-----------------------------------------------
	
	/**
	 * Returns an ActorType by name
	 */
	public function getActorTypeByName(typeName:String):ActorType
	{
		var types = getAllActorTypes();
		
		for(type in types)
		{
			if(type.name == typeName)
			{
				return type;
			}
		}
		
		return null;
	}
	
	/**
	* Returns an ActorType by ID
	*/
	public function getActorType(actorTypeID:Int):ActorType
	{
		return cast(Data.get().resources.get(actorTypeID), ActorType);
	}
	
	/**
	* Returns an array of all ActorTypes in the game
	*/
	public function getAllActorTypes():Array<ActorType>
	{
		return Data.get().getAllActorTypes();
	}
	
	/**
	* Returns an array of all Actors of the given type in the scene
	*/
	public function getActorsOfType(type:ActorType):Array<Actor>
	{
		return engine.getActorsOfType(type);
	}
	
	/**
	* Returns an actor in the scene by ID
	*/
	public function getActor(actorID:Int):Actor
	{
		return engine.getActor(actorID);
	}
	
	/**
	* Returns an ActorGroup by ID
	*/
	public function getActorGroup(groupID:Int):Group
	{
		return engine.getGroup(groupID);
	}
	
	//*-----------------------------------------------
	//* Joints
	//*-----------------------------------------------
	
	//wait for Box2D
	
	//*-----------------------------------------------
	//* Physics
	//*-----------------------------------------------
	
	//wait for Box2D
	
	public function setGravity(x:Float, y:Float)
	{
		engine.world.setGravity(new B2Vec2(x, y));
	}

	public function getGravity():B2Vec2
	{
		return engine.world.getGravity();
	}

	public function enableContinuousCollisions()
	{
		B2World.m_continuousPhysics = true;
	}
		
	public function toPhysicalUnits(value:Float):Float
	{
		return Engine.toPhysicalUnits(value);
	}

	public function toPixelUnits(value:Float):Float
	{
		return Engine.toPixelUnits(value);
	}
	
	public function makeActorNotPassThroughTerrain(actor:Actor)
	{
		B2World.m_continuousPhysics = true;
		
		if(actor != null && !actor.isLightweight)
		{
			actor.body.setBullet(true);
		}
	}
	
	//*-----------------------------------------------
	//* Sounds
	//*-----------------------------------------------
	
	public function mute()
	{
		//FlxG.mute = true;
	}
	
	public function unmute()
	{
		//FlxG.mute = false;
	}
	
	/**
	* Returns a SoundClip resource by ID
	*/
	public function getSound(soundID:Int):Sound
	{
		return cast(Data.get().resources.get(soundID), Sound);
	}
	
	/**
	* Play a specific SoundClip resource once (use loopSound() to play a looped version)
	*/
	public function playSound(clip:Sound)
	{
		if(clip != null)
		{				
			for(i in 0...CHANNELS)
			{
				var sc = engine.channels[i];
				
				if(sc.currentSound == null)
				{
					sc.playSound(clip);
					return;
				}
			}
		}			
	}
	
	/**
	* Loop a specific SoundClip resource (use playSound() to play only once)
	*/
	public function loopSound(clip:Sound)
	{
		if(clip != null)
		{				
			for(i in 0...CHANNELS)
			{
				var sc = engine.channels[i];
				
				if(sc.currentSound == null)
				{
					sc.loopSound(clip);
					return;
				}
			}
		}			
	}
	
	/**
	* Play a specific SoundClip resource once on a specific channel (use loopSoundOnChannel() to play a looped version)
	*/
	public function playSoundOnChannel(clip:Sound, channelNum:Int)
	{
		var sc:SoundChannel = engine.channels[channelNum];		
		sc.playSound(clip);			
	}
	
	/**
	* Play a specific SoundClip resource looped on a specific channel (use playSoundOnChannel() to play once)
	*/
	public function loopSoundOnChannel(clip:Sound, channelNum:Int)
	{		
		var sc:SoundChannel = engine.channels[channelNum];	
		sc.loopSound(clip);			
	}
	
	/**
	* Stop all sound on a specific channel (use pauseSoundOnChannel() to just pause)
	*/
	public function stopSoundOnChannel(channelNum:Int)
	{					
		var sc:SoundChannel = engine.channels[channelNum];
		sc.stopSound();
	}
	
	/**
	* Pause all sound on a specific channel (use stopSoundOnChannel() to stop it)
	*/
	public function pauseSoundOnChannel(channelNum:Int)
	{					
		var sc:SoundChannel = engine.channels[channelNum];	
		sc.setPause(true);			
	}
	
	/**
	* Resume all sound on a specific channel (must have been paused with pauseSoundOnChannel())
	*/
	public function resumeSoundOnChannel(channelNum:Int)
	{					
		var sc:SoundChannel = engine.channels[channelNum];		
		sc.setPause(false);			
	}
	
	/**
	* Set the volume of all sound on a specific channel (use decimal volume such as .5)
	*/
	public function setVolumeForChannel(volume:Float, channelNum:Int)
	{			
		var sc:SoundChannel = engine.channels[channelNum];		
		sc.setVolume(volume);
	}
	
	/**
	* Stop all the sounds currently playing (use mute() to mute the game).
	*/
	public function stopAllSounds()
	{			
		for(i in 0...CHANNELS)
		{
			var sc:SoundChannel = engine.channels[i];		
			sc.stopSound();
		}
	}
	
	/**
	* Set the volume for the game
	*/
	public function setVolumeForAllSounds(volume:Float)
	{
		SoundChannel.masterVolume = volume;
		
		for(i in 0...CHANNELS)
		{
			var sc:SoundChannel = engine.channels[i];
			sc.setVolume(volume);
		}
	}
	
	/**
	* Fade a specific channel's audio in over time (milliseconds)
	*/
	public function fadeInSoundOnChannel(channelNum:Int, time:Float)
	{						
		var sc:SoundChannel = engine.channels[channelNum];
		sc.fadeInSound(time);			
	}
	
	/**
	* Fade a specific channel's audio out over time (milliseconds)
	*/
	public function fadeOutSoundOnChannel(channelNum:Int, time:Float)
	{						
		var sc:SoundChannel = engine.channels[channelNum];
		sc.fadeOutSound(time);			
	}
	
	/**
	* Fade all audio in over time (milliseconds)
	*/
	public function fadeInForAllSounds(time:Float)
	{
		for(i in 0...CHANNELS)
		{
			var sc:SoundChannel = engine.channels[i];
			sc.fadeInSound(time);
		}
	}
	
	/**
	* Fade all audio out over time (milliseconds)
	*/
	public function fadeOutForAllSounds(time:Float)
	{
		for(i in 0...CHANNELS)
		{
			var sc:SoundChannel = engine.channels[i];	
			sc.fadeOutSound(time);
		}
	}
	
	
	//*-----------------------------------------------
	//* Background Manipulation (?)
	//*-----------------------------------------------
	
	//*-----------------------------------------------
	//* Eye Candy
	//*-----------------------------------------------
	
	/**
	* Begin screen shake
	*/
	public function startShakingScreen(intensity:Float=0.05, duration:Float=0.5)
	{
		engine.shakeScreen(intensity, duration);
	}
	
	/**
	* End screen shake
	*/
	public function stopShakingScreen()
	{
		engine.stopShakingScreen();
	}
	
	//*-----------------------------------------------
	//* Terrain Changer (Tile API)
	//*-----------------------------------------------
	
	/**
	* Get the top terrain layer
	*/
	public function getTopLayer():Int
	{
		return engine.getTopLayer();
	}
	
	/**
	* Get the bottom terrain layer
	*/
	public function getBottomLayer():Int
	{
		return engine.getBottomLayer();
	}
	
	/**
	* Get the middle terrain layer
	*/
	public function getMiddleLayer():Int
	{
		return engine.getMiddleLayer();
	}
	
	//*-----------------------------------------------
	//* Fonts
	//*-----------------------------------------------
	
	public function getFont(fontID:Int):Font
	{
		return cast(Data.get().resources.get(fontID), Font);
	}
	
	//*-----------------------------------------------
	//* Global
	//*-----------------------------------------------
	
	public function pause()
	{
		engine.pause();
	}
	
	public function unpause()
	{
		engine.unpause();
	}
	
	public function enableFullScreen()
	{
		Engine.stage.displayState = nme.display.StageDisplayState.FULL_SCREEN;
	}
	
	public function disableFullScreen()
	{
		Engine.stage.displayState = nme.display.StageDisplayState.NORMAL;
	}
		
	/**
	* Pause the game
	*/
	public function pauseAll()
	{
		Engine.paused = true;
	}
	
	/**
	* Unpause the game
	*/
	public function unpauseAll()
	{
		Engine.paused = false;
	}
	
	/**
	* Get the screen width in pixels
	*/
	public function getScreenWidth()
	{
		return Engine.screenWidth;
	}
	
	/**
	* Get the screen height in pixels
	*/
	public function getScreenHeight()
	{
		return Engine.screenHeight;
	}
	
	/**
	* Sets the distance an actor can travel offscreen before being deleted.
	*/
	public function setOffscreenTolerance(top:Int, left:Int, bottom:Int, right:Int)
	{
		Engine.paddingTop = top;
		Engine.paddingLeft = left;
		Engine.paddingRight = right;
		Engine.paddingBottom = bottom;
	}
	
	/**
	* Returns true if the scene is transitioning
	*/
	public function isTransitioning():Bool
	{
		return engine.isTransitioning();
	}
	
	/**
	* Adjust how fast or slow time should pass in the game; default is 1.0. 
	*/
	public function setTimeScale(scale:Float)
	{
		Engine.timeScale = scale;
	}
	
	/**
	 * Generates a random number. Deterministic, meaning safe to use if you want to record replays in random environments
	 */
	public function randomFloat():Float
	{
		return Math.random();
	}
	
	/**
	 * Generates a random number. Set the lowest and highest values.
	 */
	public function randomInt(low:Int, high:Int):Int
	{
		return low + Math.floor(randomFloat() * (high - low + 1));
	}
	
	/**
	* Change a Number to another specific Number over time  
	*/
	public function tweenNumber(attributeName:String, toValue:Float, duration:Float, easing:Dynamic) 
	{
		/*var params:Object = { time: duration / 1000, transition: easing };
		attributeName = toInternalName(attributeName);
		params[attributeName] = toValue;
		
		return Tweener.addTween(this, params);*/
		
		//TODO
	}
	
	/**
	* Stops a tween 
	*/
	public static function abortTween(target:Dynamic)
	{
		
	}
	
	//*-----------------------------------------------
	//* Saving
	//*-----------------------------------------------
	
	/**
	 * Saves a game to the "StencylSaves/[GameName]/[FileName]" location with an in-game displayTitle
	 *
	 * Callback = function(success:Boolean):void
	 */
	public function saveGame(fileName:String, fn:Bool->Void=null)
	{
		#if !js
		var so = SharedObject.getLocal(fileName);
		so.data.message = "<somexml></somexml>";
		#end
		
		//Prepare to save.. with some checks
		#if ( cpp || neko )
		        // Android didn't wanted SharedObjectFlushStatus not to be a String
		        var flushStatus:SharedObjectFlushStatus = null;
		#else
		        // Flash wanted it very much to be a String
		        var flushStatus:String = null;
		#end
		
		#if !js
		try 
		{
		    flushStatus = so.flush();
		} 
		
		catch(e:Dynamic) 
		{
			trace("Error: Failed to save");
		}
		
		if(flushStatus != null) 
		{
		    switch(flushStatus) 
		    {
		        case SharedObjectFlushStatus.PENDING:
		            //trace('requesting permission to save');
		        case SharedObjectFlushStatus.FLUSHED:
		            //trace('value saved');
		    }
		}
		#end
	}
	
	/**
  	 * Load a saved game
	 *
	 * Callback = function(success:Boolean):void
	 */
	public function loadGame(fileName:String, fn:Bool->Void=null)
	{
		#if !js
		var data = SharedObject.getLocal(fileName);
		trace('Loaded Save: ' + data.data.message);
		#end
	}
	
	/*
	 * Callback: function(success:Boolean, saveFile:String, isLast:Boolean):void
	 */
	public function retrieveSaves(fn:Bool->String->Bool->Void=null)
	{
		#if !js
		#end
	}
	
	//*-----------------------------------------------
	//* Web Services
	//*-----------------------------------------------
	
	private function defaultURLHandler(event:Event)
	{
		var loader:URLLoader = new URLLoader(event.target);
		trace("Visited URL: " + loader.data);
	}
	
	public function openURLInBrowser(URL:String)
	{
		Lib.getURL(new URLRequest(URL));
	}
		
	/**
	* Attempts to connect to a URL
	*/
	public function visitURL(URL:String, fn:Event->Void = null)
	{
		if(fn == null)
		{
			fn = defaultURLHandler;
		}
		
		var loader:URLLoader = new URLLoader();
		loader.addEventListener(Event.COMPLETE, fn);
		
		var request:URLRequest = new URLRequest(URL);
		
		try 
		{
			loader.load(request);
		} 
		
		catch(error:String) 
		{
			trace("Cannot open URL.");
		}
	}
	
	/**
	* Attempts to POST data to a URL
	*/
	public function postToURL(URL:String, data:String = null, fn:Event->Void = null)
	{
		#if !js
		if(fn == null)
		{
			fn = defaultURLHandler;
		}
		
		var loader:URLLoader = new URLLoader();
		loader.addEventListener(Event.COMPLETE, fn);
		
		var request:URLRequest = new URLRequest(URL);
		request.method = URLRequestMethod.POST;
		
		if(data != null) 
		{
			request.data = new URLVariables(data);
		}
		
		try 
		{
			loader.load(request);
		} 
		
		catch(error:String) 
		{
			trace("Cannot open URL.");
		}
		#end
	}
	
	//*-----------------------------------------------
	//* Social Media
	//*-----------------------------------------------
	
	/**
	* Send a Tweet (GameURL is the twitter account that it will be posted to)
	*/
	public function simpleTweet(message:String, gameURL:String)
	{
		openURLInBrowser("http://twitter.com/home?status=" + StringTools.urlEncode(message + " " + gameURL));
	}
	
	//*-----------------------------------------------
	//* Newgrounds
	//*-----------------------------------------------
	
	//*-----------------------------------------------
	//* Kongregate
	//*-----------------------------------------------
	
	#if flash
	public function initKongregateAPI()
	{
		Kongregate.initAPI();
	}
	
	public function submitScore(score:Float, mode:String) 
	{
		Kongregate.submitScore(score, mode);
	}
	
	public function submitStat(name:String, stat:Float) 
	{
		Kongregate.submitStat(name, stat);
	}
	#end
	
	//*-----------------------------------------------
	//* Mochi
	//*-----------------------------------------------
	
	//*-----------------------------------------------
	//* Debug
	//*-----------------------------------------------
	
	public function enableDebugDrawing()
	{
		Engine.debugDraw = true;
		Engine.debugDrawer.m_sprite.graphics.clear();
	}

	public function disableDebugDrawing()
	{
		Engine.debugDraw = false;
		Engine.debugDrawer.m_sprite.graphics.clear();
	}
	
	//*-----------------------------------------------
	//* Utilities
	//*-----------------------------------------------
	
}
