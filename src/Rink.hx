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
import com.haxepunk.utils.Data;
import com.haxepunk.graphics.Image;

import openfl.display.BitmapData;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.geom.Rectangle;
import openfl.Assets;

import haxe.Json;


class Rink {
    public var background(default, null):Image;
    public var ice(default, null):BitmapData;
    public var foreground(default, null):Image;
    public var area(default, null):Int;
    public var bounds(default, null):Rectangle;

    public function new(level:Dynamic, loc:Dynamic) {
        var activity = 'locations/' + level.location + '/ice-' + level.activity + '.png';
        var thisDir = 'locations/' + level.location + '/';
        _polygon = [];
        for (i in 0...loc.bounds.length) {
            var vec = loc.bounds[i];
            _polygon.push(new Vector3D(vec.x, vec.y, vec.z));
        }
        background = new Image(thisDir + loc.background);
        ice = HXP.getBitmap(activity);
        foreground = new Image(thisDir + loc.foreground);
        bounds = new Rectangle(0, 0, HXP.width, HXP.height);
        // calculate this in photoshop by selecting the area and 
        // looking in the advanced histogram MAKE sure you have 
        // clicked [to remove] ANY warning triangles
        area = loc.area;
    }

    public function collide(point:Vector3D) {
        // point in polygon algoritm
        var c = false;
        var i = 0;
        var j = _polygon.length - 1;
        while (i < _polygon.length) {
            if (((_polygon[i].y >= point.y ) != (_polygon[j].y >= point.y) ) &&
                (point.x <= (_polygon[j].x - _polygon[i].x) * (point.y - _polygon[i].y) / (_polygon[j].y - _polygon[i].y) + _polygon[i].x)
            ) {
                c = !c;
            }
            j = i++;
        }
        return !c;
    }

    var _polygon:Array<Vector3D>;
}
