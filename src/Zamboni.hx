/*
 * Copyright (c) 2016 Mountainstorm
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to 
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
*/

import com.haxepunk.HXP;
import com.haxepunk.Entity;
import com.haxepunk.Sfx;
import com.haxepunk.utils.Data;
import com.haxepunk.graphics.Image;
import com.haxepunk.utils.Input;
import com.haxepunk.utils.Key;
import com.haxepunk.graphics.Spritemap;

import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.display.BlendMode;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

import msx.MSX;


class Zamboni {
    public static var FRAME_WIDTH = 192;
    public static var FRAME_HEIGHT = 108;
    public static var RADIANS_PER_FRAME = 0.0;

    public static var MAX_FORWARD_SPEED = 10.0;
    public static var MAX_REVERSE_SPEED = 7.0;

    public static var ACCELERATION_FORWARD = 3.5;
    public static var ACCELERATION_REVERSE = 3.0;
    public static var DECELERATION = 5.0;

    public static var ROTATION_PER_SECOND = 0.9; // radians

    public static var BOUNCE_SPEED = 3.0;
    public static var SCAPE_FADE = 0.25;
    public static var SCRAPE_VOLUME = 0.2;

    public var position(default, null):Vector3D;
    public var sprite(default, null):Spritemap;
    public var reflection(default, null):Spritemap;

    public var spriteEntity(default, null):Entity;
    public var reflectionEntity(default, null):Entity;

    public var direction(default, set):Float;
    public var speed:Float;

    public var rink:Rink;

    public function new() {
        _userConfig = MSX.userConfig();
        _soundBump = new Sfx('audio/bump.ogg');
        _soundScrape = new Sfx('audio/scrape.ogg');

        position = new Vector3D(0, 0, 0.5);
        // above ground sprite        
        sprite = new Spritemap('graphics/zamboni.png', FRAME_WIDTH, FRAME_HEIGHT);
        sprite.originX = FRAME_WIDTH / 2;
        sprite.originY = FRAME_HEIGHT / 2;
        spriteEntity = new Entity(0, 0, sprite);
        RADIANS_PER_FRAME = (2 * Math.PI) / (sprite.frameCount - 1);

        // below ice reflection
        reflection = new Spritemap('graphics/zamboni-reflection.png', FRAME_WIDTH, FRAME_HEIGHT);
        reflection.originX = FRAME_WIDTH / 2;
        reflection.originY = FRAME_HEIGHT / 2;
        reflectionEntity = new Entity(0, 0, reflection);

        direction = 0.5;

        _polishA = new Vector3D(-3.9, 1.7, -0.45);
        _polishB = new Vector3D(-3.9, -1.7, -0.45);
    }

    public function added() {
    }

    public function removed() {
        _soundScrape.stop();
        _soundBump.stop();
    }

    public function update(camera:ISOCamera, ice:BitmapData) {
        if (camera != null) {
            locationUpdate();
            render(camera, ice);
        }
    }

    function locationUpdate() {
        // forward/backward/acceleration etc
        if (Input.check(Key.UP)) {
            speed += ACCELERATION_FORWARD * HXP.elapsed;
            if (speed > MAX_FORWARD_SPEED) {
                speed = MAX_FORWARD_SPEED;
            }
        } else if (Input.check(Key.DOWN)) {
            speed -= ACCELERATION_REVERSE * HXP.elapsed;
            if (speed > 0.0) {
                speed -= DECELERATION * HXP.elapsed;
                if (speed < 0.0) {
                    speed = 0.0;
                }
            }
            if (speed < -MAX_REVERSE_SPEED) {
                speed = -MAX_REVERSE_SPEED;
            }
        } else {
            var delta = DECELERATION * HXP.elapsed;
            if (Math.abs(speed) < delta) {
                delta = speed;
            }
            if (speed > 0.0) {
                speed -= delta;
            } else {
                speed += delta;
            }
        }

        // turning left/right
        var turning = false;
        if (speed != 0.0) {
            if (Input.check(Key.LEFT)) {
                direction += ROTATION_PER_SECOND * HXP.elapsed;
                turning = true;
            } else {
                if (Input.check(Key.RIGHT)) {
                    direction -= ROTATION_PER_SECOND * HXP.elapsed;
                    turning = true;                    
                }
            }
        }

        var dv = SCAPE_FADE * SCRAPE_VOLUME * HXP.elapsed;
        if (turning) {
            if (!_soundScrape.playing) {
                _soundScrape.play(SCRAPE_VOLUME * _userConfig.soundVolume, 0, true);
            } else {
                if (_soundScrape.volume + dv < SCRAPE_VOLUME * _userConfig.soundVolume) {
                    _soundScrape.volume += dv;
                } else {
                    _soundScrape.volume = SCRAPE_VOLUME * _userConfig.soundVolume;
                }
            }
        } else {
            if (_soundScrape.playing) {
                _soundScrape.volume -= dv;
                if (_soundScrape.volume < 0.0001) {
                    _soundScrape.stop();
                }
            }
        }
    } 

    function render(camera:ISOCamera, iceMask:BitmapData) {
        // move zamboni in world coordinates
        var dx = Math.cos(direction) * speed * HXP.elapsed;
        var dy = Math.sin(direction) * speed * HXP.elapsed;
        var px = position.x + dx;
        var py = position.y + dy;

        if (rink.collide(new Vector3D(px, py, position.z)) == false) {
            position.x = px;
            position.y = py;
        } else {
            _soundBump.play(_userConfig.soundVolume);
            position.x -= dx;
            position.y -= dy;
            if (speed > 0.0) {
                speed = -BOUNCE_SPEED;
            } else {
                speed = BOUNCE_SPEED;
            }
        }
        // position the sprites
        var sp = camera.toScreen(position);
        spriteEntity.x = sp.x;
        spriteEntity.y = sp.y;
        var rp = camera.toScreen(new Vector3D(position.x, position.y, -position.z));
        reflectionEntity.x = rp.x;
        reflectionEntity.y = rp.y;

        // choose the right frame
        var f = Std.int((direction / RADIANS_PER_FRAME) + 0.5);
        sprite.frame = reflection.frame = f;

        // polishing device is offset from zamboni origin
        var m = new Matrix3D();
        m.appendRotation(-direction * HXP.DEG, Vector3D.Z_AXIS, new Vector3D());
        m.appendTranslation(position.x, position.y, position.z);
        var a = camera.toScreen(m.transformVector(_polishA));
        var b = camera.toScreen(m.transformVector(_polishB));
        
        // update the iceMask
        var sh = new Shape();
        sh.graphics.lineStyle(5, 0xFFFFFF, 1.0);
        sh.graphics.moveTo(a.x, a.y);
        sh.graphics.lineTo(b.x, b.y);
        iceMask.draw(sh);
    }

    function set_direction(rads:Float):Float {
        // ensure angle stays in 0.0 - 2*pi; needed for frame calculation
        if (rads >= 2 * Math.PI) {
            rads -= 2 * Math.PI;
        } else if (rads < 0.0) {
            rads += 2 * Math.PI;
        }
        direction = rads;
        return rads;
    }

    var _polishA:Vector3D;
    var _polishB:Vector3D;

    var _userConfig:Dynamic;
    var _soundBump:Sfx;
    var _soundScrape:Sfx;
}
