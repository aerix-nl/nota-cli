nomnom        = require('nomnom')
fs            = require('fs')
Path          = require('path')
_             = require('underscore')._
s             = require('underscore.string')
open          = require('open')
chalk         = require('chalk')
notifier      = require('node-notifier')

Nota          = require('nota')

class NotaCLI

  # Some strings that go before all logChannels (server origin and client origin respectively)
  logPrefix:    chalk.gray('nota ')
  clientPrefix: chalk.gray('nota-client ')

  constructor: ( logChannels ) ->
    # Allow redirecting of logging output to channels through dependency injection
    if logChannels? then { @log, @logEvent, @logError, @logWarning } = logChannels

    # Instantiate our thrusty helping hand in template and job tasks
    @helper = new Nota.TemplateHelper(@logWarning)

    nomnom.options
      template:
        position: 0
        help:     'The template directory path'
      data:
        position: 1
        help:    'The data file path'
      output:
        position: 2
        help:    'The output file'

      preview:
        abbr: 'p'
        flag: true
        help: 'Preview template in the browser'
      listen:
        abbr: 's'
        flag: true
        help: 'Listen for HTTP POST requests with data to render and respond with output PDF'
      list:
        abbr: 'l'
        flag: true
        help: 'List all templates'
        callback: => @listTemplatesIndex()
      verbove:
        abbr: 'b'
        flag: true
        help: 'More detailed console output on errors'
      version:
        abbr: 'v'
        flag: true
        help: 'Print version'
        callback: => @meta.version

      resources:
        flag: true
        help: 'Show the events of page resource loading in output'
      preserve:
        flag: true
        help: 'Prevent overwriting when output path is already occupied'

  start: ->
    try
      @options = @parseOptions nomnom.nom(), Nota.defaults
    catch e
      @logError e
      return

    # Sum the current (command line interface) logging channels
    logChannels = {
      log:              @log
      logEvent:         @logEvent
      logWarning:       @logWarning
      logError:         @logError
      logClient:        @logClient
      logClientError:   @logClientError
    }

    @server = new Nota @options, logChannels

    @server.start()
    # We'll need to wait till all of it's components have loaded and setup is done
    .then =>

      if @options.preview
        # If we want a template preview, open the web page
        open(@server.url())

      if @options.listen
        # Open the webrender page where renders can be requested
        open(@server.webrenderUrl())

      else
        # Else, perform a single render job and close the server
        @render(@options)

  # TODO: refactor this wrapper away. Right now it's an ugly extractor that
  # creates a single job and calls the server queue API, but this should
  # become more general with job arrays in the future.
  render: ( options )->
    job = {
      dataPath:   options.dataPath
      outputPath: options.outputPath
      preserve:   options.preserve
    }
    @server.queue job
    .then (meta) =>
      # We're done!

      if options.logging.notify
        # Would be nice if you could click on the notification
        notifier.on 'click', ->
          if meta.length is 1
            open meta[0].outputPath
          else if meta.length > 1
            open Path.dirname Path.resolve meta[0].outputPath
          else # meta = []

        # Send notification
        notifier.notify
          title:    "Nota: render jobs finished"
          message:  "#{meta.length} document(s) captured to .PDF"
          icon:     Path.join(__dirname, '../assets/images/icon.png')
          wait:     true

      @server.close()
      process.exit()

  # Settling options from parsed CLI arguments over defaults
  parseOptions: ( args, defaults ) ->
    options = _.extend {}, defaults

    # Extend with optional arguments
    options.template = {}                             if not options.template?
    options.template.path = args.template             if args.template?
    options.dataPath = args.data                      if args.data?
    options.outputPath = args.output                  if args.output?
    options.preview = args.preview                    if args.preview?
    options.listen = args.listen                      if args.listen?
    options.port = args.port                          if args.port?
    options.logging.notify = args.notify              if args.notify?
    options.logging.pageResources = args.resources    if args.resources?
    options.preserve = args.preserve                  if args.preserve?
    options.verbose = args.verbose                    if args.verbose?

    # Template definition
    template = @helper.findTemplatePath(options)

    try # to get the definition (we can do without it though)
      definition = @helper.getTemplateDefinition template
      _.extend options.template, definition
    catch e
      @logWarning e
      # Fill the definition in with what we do know
      options.template = {
        name: options.templatePath
        path: templatePath
      }
      # Delete all the old temporary data
      delete options.templatePath
      # And use the
    # Data
    options.dataPath =              @helper.findDataPath(options)

    return options


  listTemplatesIndex: ( ) =>
    templates = []
    index = @helper.getTemplatesIndex(Nota.defaults.templatesPath)

    if _.size(index) is 0
      @logError "No (valid) templates found in templates directory."
    else
      headerDir     = 'Directory'
      headerName    = 'Template name'

      fold = (memo, str)->
        Math.max(memo, str.length)
      lengths =
        dirName: _.reduce _.keys(index), fold, headerDir.length
        name:    _.reduce _(_(index).values()).pluck('name'), fold, headerName.length

      headerDir     = s.pad headerDir,  lengths.dirName, ' ', 'right'
      headerName    = s.pad headerName, lengths.name + 8, ' ', 'left'
      # List them all in a format of: templates/hello_world 'Hello World' v1.0

      @log chalk.gray(headerDir + headerName)
      templates = for dir, definition of index
        dir     = s.pad definition.dir,  lengths.dirName, ' ', 'right'
        name    = s.pad definition.name, lengths.name + 8, ' ', 'left'
        @log chalk.cyan(dir) + chalk.green(name)
    return '' # Somehow needed to make execution stop here with --list

  # Server origin logging channels
  log: ( msg )=>
    console.log   @logPrefix + msg

  logWarning: ( warningMsg )=>
    console.warn  @logPrefix + chalk.bgYellow.black('WARNG') + ' ' + warningMsg

  logError: ( errorMsg )=>
    console.error @logPrefix + chalk.bgRed.black('ERROR') + ' ' + errorMsg
    if @options?.verbose and errorMsg.toSource?
      console.error @logPrefix + errorMsg.toSource()

  logEvent: ( event )=>
    console.info  @logPrefix + chalk.bgBlue.black('EVENT') + ' ' + event

  # Client origin logging channels
  logClient: ( msg )=>
    console.log   @clientPrefix + msg

  logClientError: ( msg )=>
    console.error @clientPrefix + chalk.bgRed.black('ERROR') + ' ' + msg

notaCLI = new NotaCLI()
module.exports = notaCLI.start()
