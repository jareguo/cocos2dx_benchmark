var Game = require('Game');

cc.Class({
    extends: cc.Component,

    properties: {
        i: {
            default: 0,
            serializable: false
        },
        o: {
            default: 0,
            serializable: false
        },
        oi: {
            default: 0,
            serializable: false
        },
        x: {
            default: 0,
            serializable: false
        },
        y: {
            default: 0,
            serializable: false
        }
    },

    // called every frame, uncomment this function to activate update callback
    update: function (dt) {
        var pos = this;
        var offset = Game.instance.offsets[pos.i];
        var offsetCount = Game.instance.offsetCount;
        
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

        var node = this.node;
        node.setPosition(pos.x + offset.x, pos.y + offset.y);
        node.setOpacity(pos.o);
    }
});
