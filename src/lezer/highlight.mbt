///| Syntax Highlighting support for Lezer-style trees

///|

///| Provides highlight token generation from parsed syntax trees.

// =============================================================================
// Highlight Tags (inspired by Lezer's @lezer/highlight)
// =============================================================================

///|
/// Standard highlight tags for syntax highlighting
pub(all) enum HighlightTag {
  // Keywords & Operators
  Keyword
  Operator
  Punctuation
  // Literals
  String
  Number
  Bool
  Null
  // Names
  PropertyName
  VariableName
  FunctionName
  TypeName
  // Structure
  Bracket
  Brace
  Paren
  // Comments & Documentation
  Comment
  DocComment
  // Errors
  Invalid
  // No highlighting
  None
} derive(Eq, Show)

///|
/// Convert HighlightTag to CSS class name
pub fn HighlightTag::to_class(self : HighlightTag) -> String {
  match self {
    Keyword => "hl-keyword"
    Operator => "hl-operator"
    Punctuation => "hl-punctuation"
    String => "hl-string"
    Number => "hl-number"
    Bool => "hl-bool"
    Null => "hl-null"
    PropertyName => "hl-property"
    VariableName => "hl-variable"
    FunctionName => "hl-function"
    TypeName => "hl-type"
    Bracket => "hl-bracket"
    Brace => "hl-brace"
    Paren => "hl-paren"
    Comment => "hl-comment"
    DocComment => "hl-doc-comment"
    Invalid => "hl-invalid"
    None => ""
  }
}

// =============================================================================
// Highlight Token
// =============================================================================

///|
/// A highlighted span of text
pub(all) struct HighlightToken {
  from : Int
  to : Int
  tag : HighlightTag
} derive(Eq, Show)

///|
/// Create a highlight token
pub fn HighlightToken::new(
  from : Int,
  to : Int,
  tag : HighlightTag,
) -> HighlightToken {
  { from, to, tag }
}

// =============================================================================
// Highlighter
// =============================================================================

///|
/// Highlighter configuration - maps node types to highlight tags
pub(all) struct Highlighter {
  /// Map from node type name to highlight tag
  rules : Map[String, HighlightTag]
}

///|
/// Create a new highlighter
pub fn Highlighter::new() -> Highlighter {
  { rules: {} }
}

///|
/// Add a highlighting rule
pub fn Highlighter::add_rule(
  self : Highlighter,
  node_name : String,
  tag : HighlightTag,
) -> Unit {
  self.rules[node_name] = tag
}

///|
/// Get highlight tag for a node type
pub fn Highlighter::get_tag(
  self : Highlighter,
  node_name : String,
) -> HighlightTag {
  match self.rules.get(node_name) {
    Some(tag) => tag
    _ => HighlightTag::None
  }
}

///|
/// Generate highlight tokens from a tree
pub fn Highlighter::highlight(
  self : Highlighter,
  tree : Tree,
) -> Array[HighlightToken] {
  let tokens : Array[HighlightToken] = []
  for node in tree.iter() {
    match node.node_type() {
      Some(nt) => {
        let tag = self.get_tag(nt.name)
        // Only add tokens for leaf nodes with a highlight tag
        match (tag, node) {
          (HighlightTag::None, _) => ()
          (_, Leaf(..)) =>
            tokens.push(HighlightToken::new(node.from(), node.to(), tag))
          (_, _) => ()
        }
      }
      _ => ()
    }
  }
  tokens
}

// =============================================================================
// JSON Highlighter
// =============================================================================

///|
/// Create a highlighter configured for JSON
pub fn json_highlighter() -> Highlighter {
  let h = Highlighter::new()

  // Structural tokens
  h.add_rule("BraceOpen", Brace)
  h.add_rule("BraceClose", Brace)
  h.add_rule("BracketOpen", Bracket)
  h.add_rule("BracketClose", Bracket)
  h.add_rule("Colon", Punctuation)
  h.add_rule("Comma", Punctuation)

  // Values
  h.add_rule("String", String)
  h.add_rule("Number", Number)
  h.add_rule("True", Bool)
  h.add_rule("False", Bool)
  h.add_rule("Null", Null)

  // Property names (different from regular strings)
  h.add_rule("PropertyName", PropertyName)
  h
}

///|
/// Highlight JSON source code
pub fn highlight_json(source : String) -> Array[HighlightToken] {
  match parse_json(source) {
    Some(tree) => {
      let highlighter = json_highlighter()
      highlighter.highlight(tree)
    }
    None => []
  }
}

// =============================================================================
// HTML Generation
// =============================================================================

///|
/// Escape HTML special characters
fn escape_html(s : String) -> String {
  let result = StringBuilder::new()
  for c in s {
    match c {
      '<' => result.write_string("&lt;")
      '>' => result.write_string("&gt;")
      '&' => result.write_string("&amp;")
      '"' => result.write_string("&quot;")
      _ => result.write_char(c)
    }
  }
  result.to_string()
}

///|
/// Generate highlighted HTML from source and tokens
pub fn tokens_to_html(
  source : String,
  tokens : Array[HighlightToken],
) -> String {
  let result = StringBuilder::new()
  let chars = source.to_array()
  let mut pos = 0

  // Sort tokens by position (should already be sorted, but ensure)
  let sorted_tokens = tokens.copy()
  sorted_tokens.sort_by(fn(a, b) { a.from - b.from })
  for token in sorted_tokens {
    // Add unhighlighted text before this token
    if token.from > pos {
      let text = chars[pos:token.from].iter().collect()
      result.write_string(escape_html(String::from_array(text)))
    }

    // Add highlighted token
    let text = chars[token.from:token.to].iter().collect()
    let class_name = token.tag.to_class()
    if class_name != "" {
      result.write_string("<span class=\"")
      result.write_string(class_name)
      result.write_string("\">")
      result.write_string(escape_html(String::from_array(text)))
      result.write_string("</span>")
    } else {
      result.write_string(escape_html(String::from_array(text)))
    }
    pos = token.to
  }

  // Add remaining text
  if pos < chars.length() {
    let text = chars[pos:].iter().collect()
    result.write_string(escape_html(String::from_array(text)))
  }
  result.to_string()
}

///|
/// Convenience: highlight JSON and generate HTML
pub fn highlight_json_to_html(source : String) -> String {
  let tokens = highlight_json(source)
  tokens_to_html(source, tokens)
}
