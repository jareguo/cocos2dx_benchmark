var Game = cc.Class({
    extends: cc.Component,

    properties: {
        // foo: {
        //    default: null,
        //    url: cc.Texture2D,  // optional, default is typeof default
        //    serializable: true, // optional, default is true
        //    visible: true,      // optional, default is true
        //    displayName: 'Foo', // optional
        //    readonly: false,    // optional, default is false
        // },
        // ...
        starsLayer: {
            default: null,
            type: cc.Node
        },
        starsLabel: {
            default: null,
            type: cc.Label
        },
        starPrefab: {
            default: null,
            type: cc.Prefab
        },
        maxStars: 6000,
        starsCountOffset: 40,   // 每批增减的个数
        stepsCount: 50,         // 数量增减速度
        steps: 250,             // 初始数量
    },

    statics: {
        instance: null
    },

    // use this for initialization
    onLoad: function () {
        Game.instance = this;

        this.offsetCount = 60;
        this.offsets = [];
        for (var i = 0; i < this.offsetCount; i++) {
            this.offsets[i] = {
                x: Math.sin(i * 6 * Math.PI / 180) * 4,
                y: Math.cos(i * 6 * Math.PI / 180) * 4
            };
        }

        this.stars = [];
        
        cc.director.setDisplayStats(true);
    },

    addStars:function (count) {
        var size = cc.winSize;
        var Star = require('Star');
        var spriteFrame = this.starPrefab.data.getComponent(cc.Sprite).spriteFrame;
        for (var i = 0; i < count; i++) {
            var starNode = new cc.Node();
            starNode.setContentSize(32, 32);
            var sprite = starNode.addComponent(cc.Sprite);
            sprite.spriteFrame = spriteFrame;
            starNode.addComponent(Star);

            var star = starNode.star = {
                node: starNode
            };
            star.x = (Math.random() - 0.5) * size.width;
            star.y = (Math.random() - 0.5) * size.height;
            star.i = (Math.random() * this.offsetCount) | 0;
            star.o = (Math.random() * 256) | 0;     // 透明度
            star.oi = 1;

            starNode.parent = this.starsLayer;

            this.stars.push(star);
        }
        if (this.stars.length >= this.maxStars) {
            this.starsCountOffset = -this.starsCountOffset;
        }
    },

    removeStars:function (count) {
        while (count > 0 && this.stars.length > 0) {
            var star = this.stars.pop();
            star.node.parent = null;
            count--;
        }

        if (this.stars.length <= 0) {
            this.starsCountOffset = -this.starsCountOffset;
        }
    },

    updateStar: function (star) {
        var pos = star;
        var offset = this.offsets[pos.i];
        var offsetCount = this.offsetCount;

        pos.i++;
        pos.i %= offsetCount;
        pos.o += pos.oi;
        if (pos.o > 255) {
            pos.o = 255;
            pos.oi = -pos.oi;
        } else if (pos.o < 0) {
            pos.o = 0;
            pos.oi = -pos.oi;
        }

        var node = star.node._sgNode;
        node.setPosition(pos.x + offset.x, pos.y + offset.y);
        node.setOpacity(pos.o);
    },

    // called every frame, uncomment this function to activate update callback
    update: function (dt) {
        ++this.steps;
        if (this.steps >= this.stepsCount) {
            if (this.starsCountOffset > 0) {
                this.addStars(this.starsCountOffset);
            } else {
                this.removeStars(-this.starsCountOffset);
            }
            this.steps -= this.stepsCount;
            if (this.starsLabel) {
                this.starsLabel.string = this.stars.length.toString() + " stars";
            }
            else {
                cc.log(this.stars.length);
            }
        }
        for (var i = 0; i < this.stars.length; ++i) {
            this.updateStar(this.stars[i]);
        }
    }
});
