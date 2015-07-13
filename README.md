# Nota CLI

A command line interface to [Nota](https://github.com/aerix-nl/nota-cli). 

Nota eats your HTML based static or scripted template, allows you to mix in
your data and excretes pretty PDF documents. Perfect for automating things
like invoice or ticket generation, but also a convenient tool rendering a
simple static document to PDF.


## Usage

Nota has lot of handy CLI options. Try running in the root:
```bash
nota --list
```
You'll see Nota comes with a few example templates out of the box. Try:
```bash
nota --template=example-invoice
```

When finished Nota has rendered a simple PDF page, consisting of some custom
rendering of preview data as declared in the template `bower.json`. Change the
company logo image and try modifing the example data to see how easy it is to
customise it and create your own invoice. If you have a template that needs data and you'd like to render save with a specific filename to a certain location, try this:
```bash
nota --template=example-invoice --data=<path> --output=<path>
```


#### Web interface
Run Nota as a webservice, and create your PDF's though a friendly UI where you can upload a JSON file and get a PDF in return. Or use the REST API to expose Nota over your the interwebs or LAN (or VPN). Send a POST request with JSON, and get a PDF download in return. Try in your shell:
```bash
nota --template=example-invoice --listen
```

#### Development previewing
Develop and debug while feeling right at home in your favorite browser, with a
1:1 preview of what Nota turns into a PDF for you. Nota makes designing and
programming your documents a breeze with some ready examples that
automagically compile CoffeeScript and SASS. Try in your shell:
```bash
nota --template=example-invoice --preview
cd templates/examples-invoice && npm install && bower install && grunt
```
And you're ready to start customizing!

## Prerequisites

You will need the following things properly installed on your computer.

* [Git](http://git-scm.com/)
* [Node.js](http://nodejs.org/) (with NPM)
* [Bower](http://bower.io/)
* [PhantomJS v1.9.8](http://phantomjs.org/)

## Setup
Due to some shortcomings (see [Known problems](https://github.com/FelixAkk/nota#known-problems))
in the depencencies that are still being worked out, Nota is a bit
picky on it's environment and dependencies. We recommend running Nota under
Linux, and we've made a provisioning script that sets up all dependencies for
Linux (and unverified support for Mac and Windows under cywin).
```bash
chmod +x provision.sh
./provision.sh
```