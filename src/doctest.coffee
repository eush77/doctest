###
          >>>
          >>>                        >>>                         >>>
     >>>>>>>>   >>>>>>>    >>>>>>>   >>>>>   >>>>>>>    >>>>>>   >>>>>
    >>>   >>>  >>>   >>>  >>>   >>>  >>>    >>>   >>>  >>>       >>>
    >>>   >>>  >>>   >>>  >>>        >>>    >>>>>>>>>  >>>>>>>>  >>>
    >>>   >>>  >>>   >>>  >>>   >>>  >>>    >>>             >>>  >>>
     >>>>>>>>   >>>>>>>    >>>>>>>    >>>>   >>>>>>>    >>>>>>    >>>>
    .....................x.......xx.x.................................

###

doctest = (path, options = {}, callback = noop) ->
  _.each _.keys(validators).sort(), (key) ->
    unless validators[key] options[key]
      throw new Error "Invalid #{key} `#{options[key]}'"

  type = options.type or do ->
    match = /[.](coffee|js)$/.exec path
    if match is null
      throw new Error 'Cannot infer type from extension'
    match[1]

  fetch path, options, (text) ->
    source = rewrite[type] text.replace(/^#!.*/, '')
    results = switch options.module
      when 'amd'
        functionEval "#{source};\n#{defineFunctionString}"
      when 'commonjs'
        commonjsEval source, path
      else
        functionEval source
    log results unless options.silent
    callback results
    results

doctest.version = '0.6.0'


if typeof window isnt 'undefined'
  {_, CoffeeScript, escodegen, esprima} = window
  window.doctest = doctest
else
  fs = require 'fs'
  pathlib = require 'path'
  _ = require 'underscore'
  CoffeeScript = require 'coffee-script'
  escodegen = require 'escodegen'
  esprima = require 'esprima'
  module.exports = doctest


validators =
  module: _.partial _.contains, [undefined, 'amd', 'commonjs']
  silent: _.constant yes
  type:   _.partial _.contains, [undefined, 'coffee', 'js']


fetch = (path, options, callback) ->
  wrapper = (text) ->
    name = _.last path.split('/')
    console.log "running doctests in #{name}..." unless options.silent
    callback text

  console.log "retrieving #{path}..." unless options.silent
  if typeof window isnt 'undefined'
    jQuery.ajax path, dataType: 'text', success: wrapper
  else
    wrapper fs.readFileSync path, 'utf8'


rewrite = (input, type) ->
  rewrite[type] input.replace /\r\n?/g, '\n'


rewrite.js = (input) ->
  f = (expr) -> "function() {\n  return #{expr}\n}"

  processComment = do (expr = '') -> (comment) ->
    lines = []
    for line in comment.value.split('\n')
      if match = /^[ \t]*>(.*)/.exec line
        lines.push "__doctest.input(#{f expr})" if expr
        expr = match[1]
      else if match = /^[ \t]*[.]+(.*)/.exec line
        expr += "\n#{match[1]}"
      else if expr
        lines.push "__doctest.input(#{f expr})"
        lines.push "__doctest.output(#{comment.loc.start.line}, #{f line})"
        expr = ''
    escodegen.generate esprima.parse(lines.join('\n')), indent: '  '

  options = comment: yes, loc: yes
  {comments} = esprima.parse input, options
  LINES = input.split '\n'
  [xxx] = _.reduce comments, ([chunks, position], comment) ->
    lineNumber = position.line
    if comment.loc.start.line is lineNumber
      [[chunks..., LINES[lineNumber - 1].substr(position.column, comment.loc.start.column)], comment.loc.end]
    else
      lines__ = [LINES[lineNumber - 1].substr(position.column)]
      lineNumber += 1
      while lineNumber < comment.loc.start.line
        lines__.push LINES[lineNumber - 1]
        lineNumber += 1
      lines__.push LINES[lineNumber - 1].substr(0, comment.loc.start.column)
      [[chunks..., lines__.join('\n')], comment.loc.end]
  , [[], line: 1, column: 0]
  xxx.push [LINES[_.last(comments).loc.end.line - 1].substr(_.last(comments).loc.end.column)].concat(LINES.slice(_.last(comments).loc.end.line))
  _.initial(_.flatten(_.zip(xxx, _.map(comments, processComment)))).join('')


rewrite.coffee = (input) ->
  f = (indent, expr) -> "->\n#{indent}  #{expr}\n#{indent}"

  lines = []; expr = ''
  for line, idx in input.split('\n')
    if match = /^([ \t]*)#(?!##)[ \t]*(.+)/.exec line
      [..., indent, comment] = match
      if match = /^>(.*)/.exec comment
        lines.push "#{indent}__doctest.input #{f indent, expr}" if expr
        expr = match[1]
      else if match = /^[.]+(.*)/.exec comment
        expr += "\n#{indent}  #{match[1]}"
      else if expr
        lines.push "#{indent}__doctest.input #{f indent, expr}"
        lines.push "#{indent}__doctest.output #{idx + 1}, #{f indent, comment}"
        expr = ''
    else
      lines.push line
  CoffeeScript.compile lines.join('\n')


defineFunctionString = '''
  function define() {
    var arg, idx;
    for (idx = 0; idx < arguments.length; idx += 1) {
      arg = arguments[idx];
      if (typeof arg === 'function') {
        arg();
        break;
      }
    }
  }
'''


functionEval = (source) ->
  # Functions created via the Function function are always run in the
  # global context, which ensures that doctests can't access variables
  # in _this_ context.
  #
  # The `evaluate` function takes one argument, named `__doctest`.
  evaluate = Function '__doctest', source
  queue = []
  evaluate
    input: (fn) -> queue.push [fn]
    output: (num, fn) -> queue.push [fn, num]
  run queue


commonjsEval = (source, path) ->
  abspath = pathlib.resolve(path).replace(/[.][^.]+$/, "-#{_.now()}.js")
  fs.writeFileSync abspath, """
    var __doctest = {
      queue: [],
      input: function(fn) {
        __doctest.queue.push([fn]);
      },
      output: function(num, fn) {
        __doctest.queue.push([fn, num]);
      }
    };
    #{source}
    (module.exports || exports).__doctest = __doctest;
  """
  try
    {queue} = require(abspath).__doctest
  finally
    fs.unlinkSync abspath
  run queue


run = (queue) ->
  results = []; input = noop
  for arr in queue
    switch arr.length
      when 1
        input()
        input = arr[0]
      when 2
        actual = try input() catch error then error.constructor
        expected = arr[0]()
        results.push [
          _.isEqual actual, expected
          repr expected
          repr actual
          arr[1]
        ]
        input = noop
  results


log = (results) ->
  console.log ((if pass then '.' else 'x') for [pass] in results).join('')
  for [pass, expected, actual, num] in results when not pass
    console.log "FAIL: expected #{expected} on line #{num} (got #{actual})"
  return


noop = ->


# > repr 'foo \\ bar \\ baz'
# '"foo \\\\ bar \\\\ baz"'
# > repr 'foo "bar" baz'
# '"foo \\"bar\\" baz"'
# > repr TypeError
# 'TypeError'
# > repr 42
# 42
repr = (val) -> switch Object::toString.call val
  when '[object String]'
    '"' + val.replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '"'
  when '[object Function]'
    val.name
  else
    val
