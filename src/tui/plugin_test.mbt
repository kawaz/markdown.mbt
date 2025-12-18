///| Plugin system tests

test "plugin: default options" {
  let options = TuiOptions::default()
  let output = md_to_tui_with_options("# Hello\n", options)
  inspect(output.contains("Hello"), content="true")
}

test "plugin: custom code highlighter" {
  // Custom highlighter that wraps code in custom markers
  fn custom_highlighter(lang : String, code : String) -> String {
    let buf = StringBuilder::new()
    buf.write_string("<<< ")
    buf.write_string(lang)
    buf.write_string(" >>>\n")
    buf.write_string(code)
    buf.write_string("\n<<< END >>>")
    buf.to_string()
  }

  let options = TuiOptions::with_highlighter(custom_highlighter)
  let output = md_to_tui_with_options("```js\ncode\n```\n", options)
  inspect(output.contains("<<< js >>>"), content="true")
  inspect(output.contains("<<< END >>>"), content="true")
}

test "plugin: highlighter receives language" {
  let mut received_lang = ""
  fn lang_checker(lang : String, _code : String) -> String {
    received_lang = lang
    "output"
  }

  let options = TuiOptions::with_highlighter(lang_checker)
  let _ = md_to_tui_with_options("```python\nprint('hi')\n```\n", options)
  inspect(received_lang, content="python")
}

test "plugin: highlighter receives code" {
  let mut received_code = ""
  fn code_checker(_lang : String, code : String) -> String {
    received_code = code
    "output"
  }

  let options = TuiOptions::with_highlighter(code_checker)
  let _ = md_to_tui_with_options("```js\nlet x = 1;\n```\n", options)
  inspect(received_code.contains("let x = 1;"), content="true")
}

test "plugin: syntax highlight simulation" {
  // Simulate syntax highlighting by colorizing keywords
  fn syntax_highlighter(lang : String, code : String) -> String {
    let buf = StringBuilder::new()
    buf.write_string(bold)
    buf.write_string("[")
    buf.write_string(lang)
    buf.write_string("]\n")
    buf.write_string(reset)

    // Simple keyword highlighting
    let highlighted = code
      .replace(old="fn", new="\u001b[35mfn\u001b[0m")
      .replace(old="let", new="\u001b[35mlet\u001b[0m")
      .replace(old="const", new="\u001b[35mconst\u001b[0m")
    buf.write_string(highlighted)
    buf.to_string()
  }

  let options = TuiOptions::with_highlighter(syntax_highlighter)
  let output = md_to_tui_with_options("```rust\nfn main() {\n    let x = 1;\n}\n```\n", options)
  inspect(output.contains("[rust]"), content="true")
  inspect(output.contains("\u001b[35mfn\u001b[0m"), content="true")
  inspect(output.contains("\u001b[35mlet\u001b[0m"), content="true")
}

test "plugin: non-code blocks unaffected" {
  fn custom_highlighter(_lang : String, _code : String) -> String {
    "HIGHLIGHTED"
  }

  let options = TuiOptions::with_highlighter(custom_highlighter)
  let output = md_to_tui_with_options("# Heading\n\nParagraph\n\n```js\ncode\n```\n", options)

  // Heading and paragraph should be normal
  inspect(output.contains("Heading"), content="true")
  inspect(output.contains("Paragraph"), content="true")
  // Code block should use custom highlighter
  inspect(output.contains("HIGHLIGHTED"), content="true")
}
