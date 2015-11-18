/*
 * Emoji cheat sheet
 */
$(document).ready(function() {
  try {
    if(document.flashtest && document.flashtest.PercentLoaded()>=0){
      // Flash was able to load the test swf and is working
      initZeroClipboard();
    } else {
      initJsClipboard();
    }
  } catch (e) {
    initJsClipboard();
  }

  function initZeroClipboard(){
    ZeroClipboard.config({
      forceHandCursor: true,
      hoverClass: "hover"
    });
    var clipboardclient = new ZeroClipboard();

    clipboardclient.on('ready', function( readyEvent ) {
      $('ul').on('mouseover', 'div', function() {
        try {
          clipboardclient.clip(this);
        } catch(e) { }
      });

      clipboardclient.on('copy', function(evt) {
        var clipboard = evt.clipboardData;
        clipboard.setData("text/plain", $(evt.target).text().trim());
      });

      clipboardclient.on('aftercopy', function(evt) {
        var highlightedElement = evt.target;
        $(highlightedElement).addClass('copied');
        setTimeout(function(){
          $(highlightedElement).removeClass('copied');
        },800);

        _gaq.push(['_trackEvent', 'Emojis', 'Copy', text]);
      });
    });

    clipboardclient.on( 'error', function(event) {
      ZeroClipboard.destroy();
      initJsClipboard();
    });
  }

  var jsClipboardSupported = true; // we can't check if this is true unless the user tries once
  function initJsClipboard() {
    $('ul').on('click', 'div', function() {
      try {
        if(jsClipboardSupported) {
          var selection = getSelection();
          selection.removeAllRanges();

          var range = document.createRange();
          range.selectNodeContents(this);
          selection.addRange(range);

          var highlightedElement = $(this);
          if(document.execCommand('copy')==true) { // this will silently fail on IE11 when access is denied
            $(highlightedElement).addClass('copied');
            _gaq.push(['_trackEvent', 'Emojis', 'Copy', $(this).text().trim()]);
            setTimeout(function(){
              $(highlightedElement).removeClass('copied');
            },800);
          } else {
            // copying was not successfull or denied by the user or browser preferences
            // see Firefox about:config "dom.allow_cut_copy"
            $(highlightedElement).addClass('clipboardError');
            setTimeout(function(){
              $(highlightedElement).removeClass('clipboardError');
            },6000);

            jsClipboardSupported = false;
          }
          selection.removeAllRanges();
        }
      } catch(e) { }
    });
  }

  function isElementMatching(element, needle) {
    var alternative = element.attr("data-alternative-name");
    return ($(element).text().toLowerCase().indexOf(needle) >= 0) ||
      (alternative != null && alternative.toLowerCase().indexOf(needle) >= 0);
  }

  function highlightElements(needle) {
    if (needle.length == 0) {
      highlightAll();
      return;
    }
    needle = needle.toLowerCase();
    $(".emojis li").each(function (index, el) {
      if (isElementMatching($('.name', el), needle)) {
        $(el).show();
      } else {
        $(el).hide();
      }
    });
  }

  function highlightAll() {
    $(".emojis li").show();
  }

  $("#header .search").keyup(function(e) {
    if (e.keyCode == 27) { // ESC
      $(this).val('').blur();
      highlightAll();
    }
  });
  $("#header .search").on("change paste keyup", function() {
    highlightElements($("#header .search").val());
  });
  $("#header .search").focus();

  var po = document.createElement('script');
  po.type = 'text/javascript';
  po.async = true;
  po.src = 'https://apis.google.com/js/plusone.js';
  var s = document.getElementsByTagName('script')[0];
  s.parentNode.insertBefore(po, s);

  var curAudio;
  var curAudioContainer;

  function play(e) {
    e.preventDefault();

    if (curAudio) {
      curAudio.pause();
      playStopped();
    }

    if ($(curAudioContainer).is(this)) {
      curAudioContainer = null;
    } else {
      curAudioContainer = this;
      soundContainer = $(curAudioContainer).find("~ div").first();
      soundName = $(soundContainer).data("sound");

      $(curAudioContainer).html('&#x275A;&#x275A; ');

      curAudio = new Audio("https://emoji-cheat-sheet.campfirenow.com/sounds/" + soundName + ".mp3");
      $(curAudio).on('ended', playStopped);
      curAudio.play();
    }
  }

  function playStopped() {
    $(curAudioContainer).html('&#9658; ');
  }

  function canPlayMp3() {
    var audio = new Audio(),
      result = audio.canPlayType("audio/mpeg");

    if(result != "") {
      return true;
    }
  }

  if (canPlayMp3() == true) {
    $("#campfire-sounds li").prepend('<a href="#" class="play">&#9658; </a>');
    $("#campfire-sounds .play").on("click", play);
  }

  $("#description a").on("click", function() {
    _gaq.push(["_trackEvent", "Services", "Click", $(this).text()]);
  });
});
