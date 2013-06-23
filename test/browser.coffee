stdout = stderr = ''

{log} = console
console.log = (args...) ->
  log.apply console, args
  stdout += "#{args}\n"

{warn} = console
console.warn = (args...) ->
  warn.apply console, args
  stderr += "#{args}\n"

resume = null
{complete} = doctest
doctest.complete = (args...) ->
  complete.apply doctest, args
  resume()

asyncTest 'JavaScript doctests', ->
  doctest './test.js'
  resume = ->
    equal stdout, '''
      retrieving ./test.js...
      running doctests in test.js...
      ......x.x...........x.x\n
    '''
    equal stderr, '''
      expected 5 on line 31 (got 4)
      expected TypeError on line 38 (got 0)
      expected 9.5 on line 97 (got 5)
      expected "on automatic semicolon insertion" on line 109 (got "the rewriter should not rely")\n
    '''
    stdout = stderr = ''
    start()

asyncTest 'CoffeeScript doctests', ->
  doctest './test.coffee'
  resume = ->
    equal stdout, '''
      retrieving ./test.coffee...
      running doctests in test.coffee...
      ......x.x...........x.x\n
    '''
    equal stderr, '''
      expected 5 on line 31 (got 4)
      expected TypeError on line 38 (got 0)
      expected 9.5 on line 97 (got 5)
      expected "on automatic semicolon insertion" on line 109 (got "the rewriter should not rely")\n
    '''
    stdout = stderr = ''
    start()
