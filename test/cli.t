doctest provides a --help flag:

  $ $doctest --help
  
  Usage: doctest file [file ...]
  
  `file` must be a JavaScript or CoffeeScript file with the appropriate
  extension.
  
  

If no arguments are provided, the help text is printed:

  $ $doctest
  
  Usage: doctest file [file ...]
  
  `file` must be a JavaScript or CoffeeScript file with the appropriate
  extension.
  
  

doctest can operate on JavaScript files:

  $ $doctest test/test.js
  retrieving test/test.js...
  running doctests in test.js...
  ......x.x...........x.x
  expected 5 on line 31 (got 4)
  expected TypeError on line 38 (got 0)
  expected 9.5 on line 97 (got 5)
  expected "on automatic semicolon insertion" on line 109 (got "the rewriter should not rely")

doctest can also operate on CoffeeScript files:

  $ $doctest test/test.coffee
  retrieving test/test.coffee...
  running doctests in test.coffee...
  ......x.x...........x.x
  expected 5 on line 31 (got 4)
  expected TypeError on line 38 (got 0)
  expected 9.5 on line 97 (got 5)
  expected "on automatic semicolon insertion" on line 109 (got "the rewriter should not rely")

An error is thrown unless the file has a .js or .coffee extension:

  $ $doctest package.json 2>&1 | sed '/^Error:/!d'
  Error: Unsupported extension: .json

doctest accepts multiple paths:

  $ $doctest test/test.js test/test.coffee
  retrieving test/test.js...
  retrieving test/test.coffee...
  running doctests in test.js...
  ......x.x...........x.x
  expected 5 on line 31 (got 4)
  expected TypeError on line 38 (got 0)
  expected 9.5 on line 97 (got 5)
  expected "on automatic semicolon insertion" on line 109 (got "the rewriter should not rely")
  running doctests in test.coffee...
  ......x.x...........x.x
  expected 5 on line 31 (got 4)
  expected TypeError on line 38 (got 0)
  expected 9.5 on line 97 (got 5)
  expected "on automatic semicolon insertion" on line 109 (got "the rewriter should not rely")

Scope tests:

  $ $doctest test/scope.js
  retrieving test/scope.js...
  running doctests in scope.js...
  ...

  $ $doctest test/scope.coffee
  retrieving test/scope.coffee...
  running doctests in scope.coffee...
  ...
