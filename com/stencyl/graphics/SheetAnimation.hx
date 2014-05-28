package com.stencyl.graphics;

import com.stencyl.models.actor.Animation;
import nme.display.Sprite;
import nme.display.BitmapData;

#if !js
import nme.display.Tilesheet;
#end

import com.stencyl.Engine;

class SheetAnimation extends Sprite implements AbstractAnimation
{
	public var tint:Bool = false;
	public var redValue:Float;
	public var greenValue:Float;
	public var blueValue:Float;
	public var blendName:String = "NORMAL";

	private var frameIndex:Int;
	private var looping:Bool;
	private var timer:Float;
	private var finished:Bool;
	private var needsUpdate:Bool;
	
	public var framesAcross:Int;
	public var frameWidth:Int;
	public var frameHeight:Int;
	
	#if !js
	public var tilesheet:Tilesheet;
	#end
	
	private var durations:Array<Int>;
	public var numFrames:Int;
	
	private var data:Array<Float>;
	
	private var model:Animation;
	
	#if !js
	public function new(tilesheet:Tilesheet, durations:Array<Int>, width:Int, height:Int, looping:Bool, model:Animation) 
	#end
	#if js
	public function new(tilesheet:Dynamic, durations:Array<Int>, width:Int, height:Int, looping:Bool, model:Animation) 
	#end
	{
		super();
		
		this.model = model;
		
		this.x = -width/2 * Engine.SCALE;
		this.y = -height/2 * Engine.SCALE;
		
		this.timer = 0;
		this.frameIndex = 0;
		this.frameWidth = width;
		this.frameHeight = height;
		this.looping = looping;
		#if !js
		this.tilesheet = tilesheet;
		#end
		this.durations = durations;
		
		numFrames = durations.length;

		data = [0.0, 0.0, 0];
		
		updateBitmap();
	}		

	public inline function update(elapsedTime:Float)
	{
		//Non-synced animations
		if(model == null || !looping)
		{
			timer += elapsedTime;
		
			if(numFrames > 0 && timer > durations[frameIndex])
			{
				var old = frameIndex;
			
				timer -= durations[frameIndex];
				
				frameIndex++;
				
				if(frameIndex >= numFrames)
				{
					if(looping)
					{
						frameIndex = 0;
					}
					
					else
					{	
						finished = true;
						frameIndex--;
					}
				}
				
				if(old != frameIndex)
				{
					needsUpdate = true;
				}
			}
		
			return;
		}
	
		var old = frameIndex;
	
		timer = model.sharedTimer;
		frameIndex = model.sharedFrameIndex;
		
		if(old != frameIndex)
		{
			needsUpdate = true;
		}
	}
	
	public function getCurrentFrame():Int
	{
		return frameIndex;
	}
	
	public function getNumFrames():Int
	{
		return numFrames;
	}
	
	public function setFrame(frame:Int):Void
	{
		if(frame < 0 || frame >= numFrames)
		{
			frame = 0;
		}
		
		frameIndex = frame;
		needsUpdate = true;
		finished = false;
		
		//Q: should we be altering the shared instance?
		if(model != null)
		{
			model.sharedFrameIndex = frame;
		}
	}
	
	public function isFinished():Bool
	{
		return finished;
	}
	
	public function needsBitmapUpdate():Bool
	{
		return needsUpdate;
	}
	
	public inline function reset()
	{
		timer = 0;
		frameIndex = 0;
		finished = false;
		needsUpdate = true;
	}
	
	public inline function updateBitmap()
	{
		#if !js
		data[0] = 0;
		data[1] = 0;
		data[2] = frameIndex;
		
		if (tint)
		{
			data[3] = redValue;
			data[4] = greenValue;
			data[5] = blueValue;
			
			graphics.clear();
			tilesheet.drawTiles(graphics, data, scripts.MyAssets.antialias, Tilesheet.TILE_RGB);
		}
		else
		{
			data[3] = 1;
			data[4] = 1;
			data[5] = 1;
			
			graphics.clear();
			
			#if flash
			tilesheet.drawTiles(graphics, data, scripts.MyAssets.antialias);
			#else
			if (blendName == "ADD")
			{
				tilesheet.drawTiles(graphics, data, scripts.MyAssets.antialias, Tilesheet.TILE_RGB | Tilesheet.TILE_BLEND_ADD);
			}
			else if (blendName == "MULTIPLY")
			{
				tilesheet.drawTiles(graphics, data, scripts.MyAssets.antialias, Tilesheet.TILE_RGB | Tilesheet.TILE_BLEND_MULTIPLY);
			}
			else if (blendName == "SCREEN")
			{
				tilesheet.drawTiles(graphics, data, scripts.MyAssets.antialias, Tilesheet.TILE_RGB | Tilesheet.TILE_BLEND_SCREEN);
			}
			else
			{
				tilesheet.drawTiles(graphics, data, scripts.MyAssets.antialias, Tilesheet.TILE_RGB | Tilesheet.TILE_BLEND_NORMAL);
			}
			#end
		}
		
		needsUpdate = false;
  		#end
	}
	
	public inline function draw(g:G, x:Float, y:Float, angle:Float, alpha:Float)
	{
		#if !js
		data[0] = x;
		data[1] = y;
		data[2] = frameIndex;
		data[3] = angle;
		data[4] = alpha;
		
  		tilesheet.drawTiles(g.graphics, data, scripts.MyAssets.antialias, Tilesheet.TILE_ROTATION | Tilesheet.TILE_ALPHA);
  		#end
	}
	
	public function getFrameDurations():Array<Int>
	{
		return durations;
	}
	
	public function setFrameDurations(time:Int)
	{	
		if(durations != null)
		{
			var newDurations:Array<Int> = new Array<Int>();
		
			for(i in 0...durations.length)
			{
				newDurations.push(time);
			}
			
			durations = newDurations;
		}
	}
	
	public function getCurrentImage():BitmapData
	{
		#if flash
		return null;
		#else
		var img = new BitmapData(Std.int(width) , Std.int(height), true, 0x00ffffff);
		img.copyPixels(tilesheet.__bitmap, new nme.geom.Rectangle((frameIndex % framesAcross) * width, Math.floor(frameIndex / framesAcross) * height, Std.int(width), Std.int(height)), new nme.geom.Point(0, 0), null, null, false);
		return img;
		#end
		
	}
}
