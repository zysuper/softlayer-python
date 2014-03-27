#
# * Gruntfile
# * Provides configuration for tasks and Grunt plugins
# *
# * Copyright (c) 2014 SoftLayer, an IBM Company
# * Released under the MIT license
#

module.exports = (grunt) ->

  grunt.initConfig {
    pkg: grunt.file.readJSON("package.json")
    site: grunt.file.readYAML("_config.yml")
    banner: "/*!\n" +
            " * \n" +
            " * <%= site.project.name %>\n" +
            " * Version <%= site.project.version %>, Built on <%= grunt.template.today(\"mm-dd-yyyy\") %>\n" +
            " * Copyright (c) <%= grunt.template.today(\"yyyy\") %> <%= site.company.name %>. All rights reserved.\n" +
            " * Code and documentation licensed under <%= site.license.type %>.\n" +
            " * \n" +
            " */\n\n"

    # Makes Bundler install the local Gemfile
    shell:
      bundler:
        command: [
          "gem update --system"
          "gem install bundler"
          "bundle install"
        ].join("&&")
        options:
          stdout: true

    clean:
      # Does some light cleaning before the party begins
      before: [
        "public/css/main*"
        "public/javascript/main*"
        "validation-*.json"
        "*.lock"
        "_www"
      ]
      # And cleans up once the party is over
      after: ["coffeescript/.jscache"]

    # Cooks CoffeeScript until it's a nice, golden JavaScript and drops it into a temp directory
    coffee:
      cache:
        expand: true
        cwd: "coffeescript/"
        src: ["*.coffee"]
        dest: "coffeescript/.jscache/"
        ext: ".js"

    # Pounds on Javascript until it becomes one file
    concat:
      build:
        options:
          banner: "<%= banner %>"
        src: [
          "<%= coffee.cache.dest %>suppress.js"
          "<%= coffee.cache.dest %>folio.js"
          "<%= coffee.cache.dest %>metrics.js"
          "<%= coffee.cache.dest %>tocify.js"
        ]
        dest: "public/javascript/main.js"

    # Now we're flattening Javascript
    uglify:
      options:
        banner: "<%= banner %>"
        report: "min"
      build:
        src: "<%= concat.build.dest %>"
        dest: "public/javascript/main.min.js"

    # Rounds up all the Less morsels to make one big CSS cookie
    recess:
      build:
        options:
          compile: true
          compress: false
          banner: "<%= banner %>"
        src: ["less/@import.less"]
        dest: "public/css/main.css"

      # And we're flattening CSS, as well
      minify:
        options:
          compile: true
          compress: true
          banner: "<%= banner %>"
        src: ["<%= recess.build.src %>"]
        dest: "public/css/main.min.css"

    # This makes Jekyll easier. Instead of typing "jekyll serve -w --baseurl('')" to start it locally, you can just type "grunt preview".
    jekyll:
      test: {}
      preview:
        options:
          watch: true
          serve: true
          baseurl: ["\"\""]

    # Here, the W3C tells us how much our HTML doesn't comply with their standard
    validation:
      options:
        charset: "UTF-8"
        doctype: "HTML5"
        failHard: true
        reset: true
        relaxerror: [
          "Bad value X-UA-Compatible for attribute http-equiv on element meta."
          "Element img is missing required attribute src."
        ]

      files:
        src: [
          "_www/*.html"
          "_www/**/*.html"
        ]
  }

  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-html-validation"
  grunt.loadNpmTasks "grunt-jekyll"
  grunt.loadNpmTasks "grunt-recess"
  grunt.loadNpmTasks "grunt-shell"

  grunt.registerTask "build", [
    "clean:before"
    "coffee"
    "concat"
    "uglify"
    "recess"
    "clean:after"
  ]

  grunt.registerTask "install", [
    "shell:bundler"
  ]

  grunt.registerTask "preview", [
    "jekyll:preview"
  ]

  grunt.registerTask "serve", [
    "build"
    "jekyll:preview"
  ]

  grunt.registerTask "test", [
    "jekyll:test"
    "validation"
  ]
