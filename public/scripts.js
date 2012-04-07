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
