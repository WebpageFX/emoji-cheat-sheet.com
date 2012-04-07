$(function() {
  if (FlashDetect.installed) {
    clip_flash_block_detect = new ZeroClipboard.Client();
    clip_flash_block_detect.glue(document.getElementById('flash-test'));

    clip = new ZeroClipboard.Client();
    clip.reposition(document.getElementById('flash-test'));
    clip.receiveEvent('mouseover', null);

    $.jnotify.setup({ 'delay': 1000, 'fadeSpeed': 500 });

    clip.setHandCursor(true);
    clip.addEventListener('complete', function(client, text) {
      $.jnotify('Copied <code>' + text + '</code>');
      _gaq.push(['_trackEvent', 'Emojis', 'Copy', text]);
    });

    $('ul.buttons').on('mouseover', 'div', function() {
      try {
        if (clip_flash_block_detect.movie.PercentLoaded()){
          clip.setText($(this).text().trim());
          if (clip.div && !reglue) {
            clip.receiveEvent('mouseout', null);
            clip.reposition(this);
          } else {
            clip.glue(this);
            reglue = false;
          }
          clip.receiveEvent('mouseover', null);
        }
      } catch(e) { }
    });
  }
});

var accessibility = {

  init: function() {
    this.setupAttributes();
  },

  setupAttributes: function() {
    this.addAttributes('header','role','banner');
    this.addAttributes('content','role','main');
    this.addAttributes('footer','role','contentinfo');

    this.addAttributes('people','tabindex','1','prev');
    this.addAttributes('nature','tabindex','2','prev');
    this.addAttributes('objects','tabindex','3','prev');
    this.addAttributes('places','tabindex','4','prev');
    this.addAttributes('symbols','tabindex','5','prev');
    this.addAttributes('campfire_sounds','tabindex','6','prev');
  },

  addAttributes: function(id,att,val,cb) {
    el = document.getElementById(id);
    if (cb) {
      this.setTarget(cb);
    }
    el.setAttribute(att,val);
  },

  setTarget: function(cb) {
    this.getTarget(cb);
    while (el) {
      if (el.nodeType == 1) {
        tag = el;
        break;
      }
      this.getTarget(cb);
    }
  },

  getTarget: function(cb) {
    if (cb == 'prev') {
      el = el.previousSibling;
    }
    // if (cb == 'next') {
    //   el = el.nextSibling;
    // }
  }

}

$(document).ready(function() {
  accessibility.init();
});
