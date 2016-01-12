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
import com.haxepunk.Scene;
import com.haxepunk.Entity;
import com.haxepunk.Tween;
import com.haxepunk.tweens.misc.VarTween;
import com.haxepunk.utils.Data;
import com.haxepunk.graphics.Image;
import com.haxepunk.Sfx;
import com.haxepunk.utils.Input;
import com.haxepunk.utils.Key;

import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import openfl.text.TextFormatAlign;
import openfl.system.System;

import msx.MSX;
import msx.TitleScene;
import msx.ScoreScene;


class MenuScene extends TitleScene {
    static var L2R_Y = 526;
    static var R2L_Y = 776;
    static var DURATION = 2.0;
    static var OFF_CLEAN = 30;
    static var TRANSITION_DELAY = 5.0;

    public override function new() {
        super([new msx.ScoreScene(TRANSITION_DELAY)]);
        addGraphic(new Image('graphics/background.jpg'));

        _title = HXP.getBitmap('graphics/title.png');

        // we'll be copying the company/title bi by bit into overlay
        _overlay = HXP.createBitmap(HXP.width, HXP.height, true, 0x00000000);
        addGraphic(new Image(_overlay));

        // the zamboni
        _img = new Image('graphics/menu-zamboni.png');
        addGraphic(_img);
    }

    override public function begin() {
        super.begin();
        _overlay.fillRect(new Rectangle(0, 0, HXP.width, HXP.height), 0x00000000);

        attract(_img, _title, _overlay);
    }

    override public function end() {
        _swipe.cancel();
    }

    public function attract(img:Image, title:BitmapData, overlay:BitmapData) {
        var company = HXP.getBitmap('graphics/company.png');

        // setup for new attract
        _img.originX = _img.width - OFF_CLEAN;
        _img.flipped = true;
        _img.x = HXP.width + _img.width;
        _img.y = L2R_Y;

        // setup movement of zamboni
        swipe(img, company, overlay, -img.width, function(d:Dynamic) {
            // move a done
            img.originX = OFF_CLEAN;
            img.flipped = false;
            swipe(img, title, overlay, HXP.width + img.width, function(d:Dynamic) {
                // move b done
                img.originX = img.width - OFF_CLEAN;
                img.flipped = true;
                img.y = R2L_Y;
                swipe(img, title, overlay, -img.width, function(d:Dynamic) {
                    // move c done
                    ready(TRANSITION_DELAY);
                });
            });
        });
    }

    public function swipe(img:Image,
                          src:BitmapData,
                          dst:BitmapData,
                          dstx:Int,
                          complete:Dynamic) {
        _swipe = new VarTween(complete, TweenType.OneShot);
        _swipe.tween(img, 'x', dstx, DURATION, function(f:Float):Float {
            dst.copyPixels(
                src,
                new Rectangle(img.x - OFF_CLEAN, img.y, 2 * OFF_CLEAN, img.height),
                new Point(img.x, img.y)
            );
            return f;
        });
        addTween(_swipe, true);
    }

    override public function gameScene():Scene {
        return new GameScene();
    }

    var _swipe:VarTween;
    var _title:BitmapData;
    var _img:Image;
    var _overlay:BitmapData;
}
