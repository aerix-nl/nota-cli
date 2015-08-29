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

  constructor: ( ) ->
    # Direct logging output to channels with custom formatting and handling
    @logging = new Nota.LoggingChannels()

    # Instantiate our thrusty helping hand in template and job tasks
    @helper = new Nota.TemplateHelper(@logging.logWarning)

    nomnom.options
      template:
        position: 0
        help:     'The template directory path (only directory name needed if
        in templates directory)'
      data:
        position: 1
        help:    'The data file path'
      output:
        position: 2
        help:    'The output filename and path (optionally)'

      preview:
        abbr: 'p'
        flag: true
        help: 'Preview template in the browser'
      listen:
        abbr: 's'
        flag: true
        help: 'Listen for HTTP POST requests with data to render and respond
        with output PDF'
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
        callback: => Nota.meta.version

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
      @logging.logError e
      return

    @nota = new Nota @options, @logging

    @nota.start webrender: @options.listen 

    @nota.setTemplate @options.template
    @nota.setData     @options.dataPath if @options.dataPath?

    if @options.preview and @options.listen
      # Listen+preview means preview the webrender page. Open the 
      # webrender page where renders can be requested.
      open @nota.webrender.url()

    else if @options.preview
      # Preview here means open the template with optional example data
      open @nota.server.url()

    else if @options.listen
      # Just log the address and all. No action needed.
      @nota.webrender.logStart()

      @logging.log chalk.grey 'Add ' +
        chalk.cyan '--preview' +
        chalk.grey ' to open the webrender interface in your browser'

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
    @nota.queue(job, options.template).then (meta) =>
      # We're done!

      # If needed we'll create a system notification with default OS behaviour
      if options.logging.notify

        # Would be nice if you could click on the notification to open the rendered file or folder
        # wth job output.
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
          icon:     Path.resolve(__dirname, '..', 'node_modules/nota/assets/images/icon.png')
          wait:     true
    .finally ->
      process.exit()

  # Settling options from parsed CLI arguments over defaults
  parseOptions: ( args, defaults ) ->
    options = _.extend {}, defaults

    # Resolve template basepath
    options.templatesPath = Path.resolve __dirname, '..', Nota.defaults.templatesPath

    # Extend with optional arguments
    options.template.path = args.template             if args.template?
    options.dataPath = args.data                      if args.data?
    options.outputPath = args.output                  if args.output?
    options.preview = args.preview                    if args.preview?
    options.listen = args.listen                      if args.listen?
    options.port = args.port                          if args.port?
    options.logging.notify = args.notify              if args.notify?
    options.logging.pageResources = args.resources    if args.resources?
    options.logging.verbose = args.verbose            if args.verbose?
    options.preserve = args.preserve                  if args.preserve?

    # Template definition
    template = @helper.findTemplatePath(options)

    try # Try to bootstrap the template definition/config (we can do without)
      definition = @helper.getTemplateDefinition template
      _.extend options.template, definition
    catch e
      @logging.logWarning e
      # Fill the definition in with what we do know
      options.template.name = options.template.path

    # Resolve data path
    options.dataPath = @helper.findDataPath(options)

    return options


  listTemplatesIndex: ( ) =>
    templates = []

    # When running with --list flag the options won't be initialized because
    # the process exits after nomnom.nom, just before it's results would
    # otherwise enter parseOptions as it's arguments.
    basepath  = @options?.templatesPath or Path.resolve __dirname, '..', Nota.defaults.templatesPath
    index     = @helper.getTemplatesIndex basepath

    if _.size(index) is 0
      @logging.logError "No (valid) templates found in templates directory."
    else
      headerPath    = 'Path'
      headerName    = 'Template name'

      fold = (memo, str)->
        Math.max(memo, str.length)
      lengths =
        path: _.reduce _.keys(index), fold, headerPath.length
        name: _.reduce _(_(index).values()).pluck('name'), fold, headerName.length

      headerName    = s.pad headerName, lengths.name, ' ', 'right'
      headerPath    = s.pad headerPath, lengths.path + 8, ' ', 'left'
      # List them all in a format of: templates/hello_world 'Hello World' v1.0

      @logging.log chalk.gray(headerName + headerPath)
      templates = for path, definition of index
        name    = s.pad definition.name, lengths.name, ' ', 'right'
        path    = s.pad definition.path, lengths.path + 8, ' ', 'left'
        @logging.log chalk.green(name) + chalk.cyan(path)
    return '' # Somehow needed to make execution stop here with --list


notaCLI = new NotaCLI()

module.exports = notaCLI.start()