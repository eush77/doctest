// Variable accessible in declaration scope:
//
// > x
// "outer"
var x = 'outer';

(function() {
  // Variable remains accessible in inner scope:
  //
  // > x
  // "outer"
  (function(x) {
    // Shadowed variable:
    //
    // > x
    // "inner"
  }('inner'));
}());
