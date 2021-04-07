// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import "controllers"
import CodeMirror from 'codemirror/lib/codemirror';
import 'codemirror/mode/javascript/javascript'
import 'codemirror/addon/lint/lint';
import 'codemirror/addon/lint/javascript-lint';
import { JSHINT } from 'jshint';
import 'styles/application.css'

document.addEventListener('turbolinks:load', () => {
  (document.querySelectorAll('.flash .delete') || []).forEach(($delete) => {
    var $notification = $delete.parentNode;

    $delete.addEventListener('click', () => {
      $notification.parentNode.removeChild($notification);
    });
  });

  if (document.getElementById('batch_config_entry')) {
    window.JSHINT = JSHINT;
    new CodeMirror.fromTextArea(document.getElementById('batch_config_entry'), {
      gutters: ['CodeMirror-lint-markers'],
      lineNumbers: true,
      lineWrapping: true,
      lint: true,
      matchBrackets: true,
      mode: 'application/json',
      smartIndent: false,
      tabSize: 2,
      theme: 'monokai'
    });
  }
});

import LocalTime from "local-time"
LocalTime.start()
