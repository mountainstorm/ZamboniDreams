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
import com.haxepunk.Sfx;
import com.haxepunk.utils.Data;
import com.haxepunk.graphics.Image;
import com.haxepunk.utils.Input;
import com.haxepunk.utils.Key;
import com.haxepunk.graphics.Spritemap;
import com.haxepunk.graphics.Text;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.display.BitmapData;
import openfl.text.TextFormatAlign;
import openfl.geom.ColorTransform;
import openfl.Assets;

import msx.MSX;
import msx.ScoreSaveScene;
import msx.LevelIntroScene;
import msx.QuitScene;

import haxe.Json;


class GameScene extends Scene {
    public function new() {
        super();
        _levels = Json.parse(Assets.getText('levels.json'));
    }

    override public function begin() {
        if (_nextLevel < _levels.length) {
            HXP.engine.pushScene(
                new IntroScene(_nextLevel + 1, _levels[_nextLevel])
            );
            _nextLevel++;
        } else {
            // show score and save if required
            if (_levels[_nextLevel-1].progress < 100.0) {
                // they quit
                HXP.engine.popScene();
            } else {
                var duration = 0.0;
                for (i in 0..._levels.length) {
                    duration += _levels[i].duration;
                }
                // remove ourself before we transition to save the score
                // this means we go back to menu once its all done
                HXP.engine.popScene();
                HXP.engine.pushScene(new ScoreSaveScene(duration));
            }
        }
    }

    var _levels:Dynamic;
    var _nextLevel:Int;
}


class IntroScene extends LevelIntroScene {
    public function new(no:Int, level:Dynamic) {
        super(no, level, 'Begin Cleanup');
    }

    override public function playScene(level:Dynamic) {
        return new PlayScene(level);
    }
}


class PlayScene extends Scene {
    static var PROGRESS_UPDATE = 1.0;
    static var PROGRESS_ROUNDING = 1.0;

    public function new(level:Dynamic) {
        super();
        var userConfig = MSX.userConfig();
        _music = new Sfx('audio/playbg.ogg');
        _music.loop(userConfig.musicVolume);
        _music.stop();

        var location = 'locations/' + level.location + '/location.json';
        var loc = Json.parse(Assets.getText(location));
        _camera = new ISOCamera(
            new Vector3D(loc.camera.x, loc.camera.y, loc.camera.z),
            new Vector3D(loc.camera.rx, loc.camera.ry, loc.camera.rz),
            loc.camera.scale
        );
        _zamboni = new Zamboni();
        _rink = _zamboni.rink = new Rink(level, loc);

        // create the stack
        addGraphic(_rink.background);
        add(_zamboni.reflectionEntity);

        // setup the ice - we invert the alpha so we can do an inverse mask
        _rinkOrigin = new Point(_rink.bounds.x, _rink.bounds.y);
        // invert alpha
        _rink.ice.colorTransform(
            _rink.bounds,
            new ColorTransform(1, 1, 1, -1, 0, 0, 0, 255)
        );
        // create somewhere to write/display the output
        _iceComposite = HXP.createBitmap(HXP.width, HXP.height, true, 0x00000000);
        addGraphic(new Image(_iceComposite));

        add(_zamboni.spriteEntity);
        addGraphic(_rink.foreground);

        _progress = new Text('', 0, 10, HXP.width, 0, {
            align: TextFormatAlign.CENTER,
            font: MSX.FONT,
            size: MSX.FONT_SIZE_CTL
        });
        add(new Entity(_progress));

        // this is a reference to the object pased by GameState
        // we use it to return the score
        _level = level;
        _level.progress = 0;
        _level.duration = 0.0;
    }

    override public function begin() {
        _music.resume();
        _zamboni.added();
    }

    override public function end() {
        _music.stop();
        _zamboni.removed();
    }

    override public function update() {
        super.update();

        // handle quiting
        if (Input.pressed(Key.ESCAPE)) {
            HXP.engine.pushScene(new QuitScene(function(quit:Bool) {
                HXP.engine.popScene(); // back to game
                if (quit) {
                    HXP.engine.popScene(); // back to menu
                }
            }, _music));
        }

        // process control input and update the zamboni
        _zamboni.update(_camera, _rink.ice);

        // copy ice into the output and invert the alpha again
        _iceComposite.copyPixels(_rink.ice, _rink.bounds, _rinkOrigin);
        _iceComposite.colorTransform(
            _rink.bounds,
            new ColorTransform(1, 1, 1, -1, 0, 0, 0, 255)
        );

        // update progress
        updateProgress();

        // update the score
        _duration += HXP.elapsed;
        _progressUpdate -= HXP.elapsed;
        if (_progressUpdate <= 0.0) {
            _progressUpdate = PROGRESS_UPDATE;
            //trace(_cleaningState);
            var progress = Std.int( ( (_cleaningState) / _rink.area) * 100 + PROGRESS_ROUNDING);
            _progress.text = Utils.scoreFormat(_duration) + " - " + progress + "%";
            // update the overall score
            _level.progress = progress;
            _level.duration = _duration;
            if (progress >= 100) {
                HXP.engine.popScene(); // complete
            }
        }
    }

    function updateProgress() {
        // check the ice to calculate progress
        // remember the ice is inverted alpha
        if (_cleaningPixels == null || _cleaningPixels.bytesAvailable == 0) {
            // fetch updated data
            _cleaningState = _cleaningProgress;
            _cleaningPixels = _rink.ice.getPixels(_rink.bounds);    
            _cleaningPixels.position = 0;
            _cleaningProgress = _rink.area;
            //trace((_cleaningPixels.length / 4) / 120);
        }
        // check 1/120th each time -> thus acurate ~ every 2 seconds
        for (i in 0...Std.int((_cleaningPixels.length / 4) / 120)) {
            if (_cleaningPixels.readUnsignedInt() >> 24 > 0x00) {
                _cleaningProgress--;
            }
        }
    }
    
    var _music:Sfx;
    
    var _rinkOrigin:Point;
    var _ice:BitmapData;
    var _iceComposite:BitmapData;

    var _rink:Rink;
    var _zamboni:Zamboni;
    var _camera:ISOCamera;

    var _progress:Text;
    var _progressUpdate:Float;
    var _cleaningState:Int;
    var _cleaningProgress:Int;
    var _cleaningProgress1:Int;
    var _cleaningPixels:ByteArray;
    var _duration:Float;

    var _level:Dynamic;
}
