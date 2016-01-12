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

import com.haxepunk.Engine;
import com.haxepunk.Scene;
import com.haxepunk.HXP;
import com.haxepunk.utils.Data;

import openfl.Assets;

import haxe.Json;

import msx.MSX;


class Main extends Engine {
    override public function init() {
#if debug
        HXP.console.enable();
#end
		MSX.init({
			FONT: 'font/Megrim.ttf',
            SCORE_FORMATER: Utils.scoreFormat,
            SCORE_COMPARE: Utils.scoreCompare

        }, function(p:Int):Dynamic {
        	// generate some random default scores
        	return (10.34 + ((p - 1) * 0.7)) * 60;
        });
        HXP.scene = new MenuScene();
    }

    public static function main() { new Main(); }
}