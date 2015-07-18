(function() {
  var Nota, NotaCLI, Path, chalk, fs, nomnom, notaCLI, notifier, open, s, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  nomnom = require('nomnom');

  fs = require('fs');

  Path = require('path');

  _ = require('underscore')._;

  s = require('underscore.string');

  open = require('open');

  chalk = require('chalk');

  notifier = require('node-notifier');

  Nota = require('nota');

  NotaCLI = (function() {
    function NotaCLI() {
      this.listTemplatesIndex = __bind(this.listTemplatesIndex, this);
      this.logging = new Nota.LoggingChannels();
      this.helper = new Nota.TemplateHelper(this.logging.logWarning);
      nomnom.options({
        template: {
          position: 0,
          help: 'The template directory path'
        },
        data: {
          position: 1,
          help: 'The data file path'
        },
        output: {
          position: 2,
          help: 'The output file'
        },
        preview: {
          abbr: 'p',
          flag: true,
          help: 'Preview template in the browser'
        },
        listen: {
          abbr: 's',
          flag: true,
          help: 'Listen for HTTP POST requests with data to render and respond with output PDF'
        },
        list: {
          abbr: 'l',
          flag: true,
          help: 'List all templates',
          callback: (function(_this) {
            return function() {
              return _this.listTemplatesIndex();
            };
          })(this)
        },
        verbove: {
          abbr: 'b',
          flag: true,
          help: 'More detailed console output on errors'
        },
        version: {
          abbr: 'v',
          flag: true,
          help: 'Print version',
          callback: (function(_this) {
            return function() {
              return Nota.meta.version;
            };
          })(this)
        },
        resources: {
          flag: true,
          help: 'Show the events of page resource loading in output'
        },
        preserve: {
          flag: true,
          help: 'Prevent overwriting when output path is already occupied'
        }
      });
    }

    NotaCLI.prototype.start = function() {
      var e;
      try {
        this.options = this.parseOptions(nomnom.nom(), Nota.defaults);
      } catch (_error) {
        e = _error;
        this.logging.logError(e);
        return;
      }
      this.nota = new Nota(this.options, this.logging);
      if (this.options.preview) {
        open(this.nota.server.url());
      }
      if (this.options.listen) {
        return open(this.nota.webrender.url());
      } else {
        return this.render(this.options);
      }
    };

    NotaCLI.prototype.render = function(options) {
      var job;
      job = {
        dataPath: options.dataPath,
        outputPath: options.outputPath,
        preserve: options.preserve
      };
      return this.nota.queue(job, options.template).then((function(_this) {
        return function(meta) {
          if (options.logging.notify) {
            notifier.on('click', function() {
              if (meta.length === 1) {
                return open(meta[0].outputPath);
              } else if (meta.length > 1) {
                return open(Path.dirname(Path.resolve(meta[0].outputPath)));
              } else {

              }
            });
            return notifier.notify({
              title: "Nota: render jobs finished",
              message: "" + meta.length + " document(s) captured to .PDF",
              icon: Path.join(__dirname, '../node_modules/nota/assets/images/icon.png'),
              wait: true
            });
          }
        };
      })(this));
    };

    NotaCLI.prototype.parseOptions = function(args, defaults) {
      var definition, e, options, template;
      options = _.extend({}, defaults);
      if (args.template != null) {
        options.template.path = args.template;
      }
      if (args.data != null) {
        options.dataPath = args.data;
      }
      if (args.output != null) {
        options.outputPath = args.output;
      }
      if (args.preview != null) {
        options.preview = args.preview;
      }
      if (args.listen != null) {
        options.listen = args.listen;
      }
      if (args.port != null) {
        options.port = args.port;
      }
      if (args.notify != null) {
        options.logging.notify = args.notify;
      }
      if (args.resources != null) {
        options.logging.pageResources = args.resources;
      }
      if (args.verbose != null) {
        options.logging.verbose = args.verbose;
      }
      if (args.preserve != null) {
        options.preserve = args.preserve;
      }
      template = this.helper.findTemplatePath(options);
      try {
        definition = this.helper.getTemplateDefinition(template);
        _.extend(options.template, definition);
      } catch (_error) {
        e = _error;
        this.logging.logWarning(e);
        options.template.name = options.template.path;
      }
      options.dataPath = this.helper.findDataPath(options);
      return options;
    };

    NotaCLI.prototype.listTemplatesIndex = function() {
      var basepath, definition, fold, headerName, headerPath, index, lengths, name, path, templates;
      templates = [];
      basepath = Path.resolve(__dirname, '..', Nota.defaults.templatesPath);
      index = this.helper.getTemplatesIndex(basepath);
      if (_.size(index) === 0) {
        this.logging.logError("No (valid) templates found in templates directory.");
      } else {
        headerPath = 'Path';
        headerName = 'Template name';
        fold = function(memo, str) {
          return Math.max(memo, str.length);
        };
        lengths = {
          path: _.reduce(_.keys(index), fold, headerPath.length),
          name: _.reduce(_(_(index).values()).pluck('name'), fold, headerName.length)
        };
        headerName = s.pad(headerName, lengths.name, ' ', 'right');
        headerPath = s.pad(headerPath, lengths.path + 8, ' ', 'left');
        this.logging.log(chalk.gray(headerName + headerPath));
        templates = (function() {
          var _results;
          _results = [];
          for (path in index) {
            definition = index[path];
            name = s.pad(definition.name, lengths.name, ' ', 'right');
            path = s.pad(definition.path, lengths.path + 8, ' ', 'left');
            _results.push(this.logging.log(chalk.green(name) + chalk.cyan(path)));
          }
          return _results;
        }).call(this);
      }
      return '';
    };

    return NotaCLI;

  })();

  notaCLI = new NotaCLI();

  module.exports = notaCLI.start();

}).call(this);
