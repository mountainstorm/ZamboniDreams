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

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.geom.Point;


class Ray {
    public var origin:Vector3D;
    public var direction:Vector3D;

    public function new(origin:Vector3D, direction:Vector3D) {
        this.origin = origin;
        this.direction = direction;
    }
}


class Plane {
    public var point:Vector3D;
    public var normal:Vector3D;

    public function new(point:Vector3D, normal:Vector3D) {
        this.point = point;
        this.normal = normal;
    }
}


class ISOCamera {
    public var origin:Vector3D;
    public var rotation:Vector3D;
    public var orthographicScale:Float;
    
    public function new(ori:Vector3D, rot:Vector3D, scale:Float) {
        origin = ori;
        rotation = rot;
        orthographicScale = scale;
        // pre-calculate key values

        // forshorten factor = world dist (hypotenuse) * cos(rot.x)
        // rot.x = 0 if looking straight down, +60 is typical iso view
        _forshorten = Math.cos(rotation.x * HXP.RAD);

        // orthographic scale is the # of world units in the longest dimension of the screen
        var dim = HXP.width > HXP.height ? HXP.width: HXP.height;
        _pixelsPerWorldUnit = dim / orthographicScale;

        // to covert we also need to adjust for rotation around z
        // envisage this as a top down view (looking straight down) => rot.x = 0
        // and with rot.z > 0.  Hypotenuse is the actual distance in world units
        // adjacent/oposite of the two formed trinagles are the screen x and y
        _rx = Math.cos(rotation.z * HXP.RAD);
        _ry = Math.sin(rotation.z * HXP.RAD);

        // we also need the offset between the two origins - we're going to figure out the 
        // world location (on the ground plane) of the top left of the screen 

        // create a vertex (in camera coordinates) for the top left corner
        var lge = orthographicScale / 2;
        var sml = (HXP.height / HXP.width) * orthographicScale / 2;
        var ox = HXP.width > HXP.height ? lge: sml;
        var oy = HXP.width <= HXP.height ? lge: sml;
        var topLeft = new Vector3D(-ox, oy, 0);

        // rotate topLeft by rotation, then transform by origin
        var worldOrigin = new Vector3D(0, 0, 0);
        var m = new Matrix3D();
        m.appendRotation(rot.x, Vector3D.X_AXIS, worldOrigin);
        m.appendRotation(rot.y, Vector3D.Y_AXIS, worldOrigin);
        m.appendRotation(rot.z, Vector3D.Z_AXIS, worldOrigin);

        var cameraNormal = m.transformVector(new Vector3D(0, 0, -1));
        m.appendTranslation(ori.x, ori.y, ori.z);
        var cameraLocation = m.transformVector(topLeft);

        // find the topLeft ray intersection with the ground plane
        var ray = new Ray(cameraLocation, cameraNormal);
        var distance = rayPlaneIntersection(ray, new Plane(worldOrigin, Vector3D.Z_AXIS));
        ray.direction.scaleBy(distance);
        var point = ray.origin.add(ray.direction);  

        // point is the world location (on ground plane) of the viewport origin
        var sx = point.x * _rx * _pixelsPerWorldUnit;
        var sy = -1 * point.y * _ry * _pixelsPerWorldUnit;
        _sx = sy + sx;
        _sy = (sy - sx) * _forshorten;
        //trace("_rx: " + _rx + ", _ry: " + _ry + ", _sx: " + _sx + ", _sy: " + _sy);
    }

    public function rayPlaneIntersection(ray:Ray, plane:Plane) {
        var denom = plane.normal.dotProduct(ray.direction);
        if (Math.abs(denom) > 0.0001) {
            var t = plane.normal.dotProduct(plane.point.subtract(ray.origin)) / denom;
            return t;
        }
        return 0.0;
    }

    public function toScreen(world:Vector3D):Point {
        // XXX: this should be the opposite of the above 'find point in camera plane'
        // then if its in bounds convert to pixels

        // do projection matrix to get screen position

        // covert to screen units, and adjust for rotation around z
        var sx = (world.x * _rx * _pixelsPerWorldUnit);
        var sy = (world.y * _ry * _pixelsPerWorldUnit);
        //trace("sx: " + sx + ", sy: " + sy);
        // add components - consider top down view with rot.z = 45
        //   * as world X increases, screen x goes up and screen y goes up
        //   * as world Y increases, screen x goes up and screen y goes down
        // then adjust for position of camera and round to ints 
        var x = (-sy + sx) - _sx;
        var y = ((-sx - sy) * _forshorten) - _sy - (world.z * _pixelsPerWorldUnit);
        // trace("x: " + x + ", y: " + y);
        return new Point(x, y);
    }

    var _forshorten:Float;
    var _pixelsPerWorldUnit:Float;
    var _rx:Float;
    var _ry:Float;
    var _sx:Float;
    var _sy:Float;
}
