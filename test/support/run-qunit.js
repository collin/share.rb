(function() {
  var fs, page, system, waitFor;

  system = require('system');

  fs = require('fs');

  waitFor = function(testFx, onReady, timeOutMillis) {
    var condition, f, interval, start;
    if (timeOutMillis == null) timeOutMillis = 3000;
    start = new Date().getTime();
    condition = false;
    f = function() {
      if ((new Date().getTime() - start < timeOutMillis) && !condition) {
        return condition = (typeof testFx === 'string' ? eval(testFx) : testFx());
      } else {
        if (!condition) {
          console.log("'waitFor()' timeout");
          return phantom.exit(1);
        } else {
          console.log("'waitFor()' finished in " + (new Date().getTime() - start) + "ms.");
          if (typeof onReady === 'string') {
            eval(onReady);
          } else {
            onReady();
          }
          return clearInterval(interval);
        }
      }
    };
    return interval = setInterval(f, 100);
  };

  page = require('webpage').create();

  page.onConsoleMessage = function(msg) {
    return console.log(msg);
  };

  page.open("./test/support/page.html", function(status) {
    if (status !== 'success') {
      console.log('Unable to access network');
      return phantom.exit(1);
    } else {
      return waitFor(function() {
        return page.evaluate(function() {
          var el;
          el = document.getElementById('qunit-testresult');
          if (el && el.innerText.match('completed')) return true;
          return false;
        });
      }, function() {
        var failedNum;
        failedNum = page.evaluate(function() {
          var el;
          el = document.getElementById('qunit-testresult');
          console.log(el.innerText);
          try {
            return el.getElementsByClassName('failed')[0].innerHTML;
          } catch (e) {

          }
          return 10000;
        });
        return phantom.exit(parseInt(failedNum, 10) > 0 ? 1 : 0);
      });
    }
  });

}).call(this);
