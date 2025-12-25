///| JSON Parser - A simple JSON parser built on Lezer-style tree structures

///|

///| This serves as a reference implementation and test case for the Lezer port.

// =============================================================================
// JSON Node Types
// =============================================================================

///|
/// JSON node type IDs
pub(all) enum JsonNodeId {
  // Structural
  JsonDocument // Root
  Object // { ... }
  Array // [ ... ]
  Property // "key": value
  // Values
  String // "..."
  Number // 123, -1.5, 1e10
  True // true
  False // false
  Null // null
  // Tokens (for detailed highlighting)
  BraceOpen // {
  BraceClose // }
  BracketOpen // [
  BracketClose // ]
  Colon // :
  Comma // ,
  PropertyName // "key" in "key": value
  // Error
  Error
} derive(Eq, Show)

///|
/// Convert JsonNodeId to Int
pub fn JsonNodeId::to_int(self : JsonNodeId) -> Int {
  match self {
    JsonDocument => 0
    Object => 1
    Array => 2
    Property => 3
    String => 4
    Number => 5
    True => 6
    False => 7
    Null => 8
    BraceOpen => 9
    BraceClose => 10
    BracketOpen => 11
    BracketClose => 12
    Colon => 13
    Comma => 14
    PropertyName => 15
    Error => 16
  }
}

///|
/// Convert Int to JsonNodeId
pub fn JsonNodeId::from_int(id : Int) -> JsonNodeId {
  match id {
    0 => JsonDocument
    1 => Object
    2 => Array
    3 => Property
    4 => String
    5 => Number
    6 => True
    7 => False
    8 => Null
    9 => BraceOpen
    10 => BraceClose
    11 => BracketOpen
    12 => BracketClose
    13 => Colon
    14 => Comma
    15 => PropertyName
    _ => Error
  }
}

///|
/// Create NodeType for JSON
pub fn json_node_type(id : JsonNodeId) -> NodeType {
  let name = match id {
    JsonDocument => "JsonDocument"
    Object => "Object"
    Array => "Array"
    Property => "Property"
    String => "String"
    Number => "Number"
    True => "True"
    False => "False"
    Null => "Null"
    BraceOpen => "BraceOpen"
    BraceClose => "BraceClose"
    BracketOpen => "BracketOpen"
    BracketClose => "BracketClose"
    Colon => "Colon"
    Comma => "Comma"
    PropertyName => "PropertyName"
    Error => "Error"
  }
  NodeType::new(id.to_int(), name)
}

// =============================================================================
// JSON Tokenizer
// =============================================================================

///|
/// Token produced by the tokenizer
pub(all) struct JsonToken {
  node_type : JsonNodeId
  from : Int
  to : Int
} derive(Eq, Show)

///|
/// JSON Tokenizer state
pub(all) struct JsonTokenizer {
  input : String
  priv chars : Array[Char]
  priv mut pos : Int
}

///|
/// Create a new tokenizer
pub fn JsonTokenizer::new(input : String) -> JsonTokenizer {
  { input, chars: input.to_array(), pos: 0 }
}

///|
/// Check if at end of input
pub fn JsonTokenizer::at_end(self : JsonTokenizer) -> Bool {
  self.pos >= self.chars.length()
}

///|
/// Peek current character
pub fn JsonTokenizer::peek(self : JsonTokenizer) -> Char? {
  if self.pos < self.chars.length() {
    Some(self.chars[self.pos])
  } else {
    None
  }
}

///|
/// Peek character at offset
pub fn JsonTokenizer::peek_at(self : JsonTokenizer, offset : Int) -> Char? {
  let idx = self.pos + offset
  if idx >= 0 && idx < self.chars.length() {
    Some(self.chars[idx])
  } else {
    None
  }
}

///|
/// Advance position
pub fn JsonTokenizer::advance(self : JsonTokenizer) -> Unit {
  self.pos += 1
}

///|
/// Skip whitespace
pub fn JsonTokenizer::skip_whitespace(self : JsonTokenizer) -> Unit {
  while not(self.at_end()) {
    match self.peek() {
      Some(' ') | Some('\t') | Some('\n') | Some('\r') => self.advance()
      _ => break
    }
  }
}

///|
/// Check if character is a digit
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
/// Read a string token (assumes pos is at opening quote)
pub fn JsonTokenizer::read_string(self : JsonTokenizer) -> JsonToken {
  let start = self.pos
  self.advance() // skip opening quote
  while not(self.at_end()) {
    match self.peek() {
      Some('"') => {
        self.advance()
        break
      }
      Some('\\') => {
        self.advance() // skip backslash
        if not(self.at_end()) {
          self.advance() // skip escaped char
        }
      }
      _ => self.advance()
    }
  }
  { node_type: String, from: start, to: self.pos }
}

///|
/// Read a number token
pub fn JsonTokenizer::read_number(self : JsonTokenizer) -> JsonToken {
  let start = self.pos

  // Optional minus
  if self.peek() == Some('-') {
    self.advance()
  }

  // Integer part
  while not(self.at_end()) {
    match self.peek() {
      Some(c) if is_digit(c) => self.advance()
      _ => break
    }
  }

  // Fractional part
  if self.peek() == Some('.') {
    self.advance()
    while not(self.at_end()) {
      match self.peek() {
        Some(c) if is_digit(c) => self.advance()
        _ => break
      }
    }
  }

  // Exponent part
  match self.peek() {
    Some('e') | Some('E') => {
      self.advance()
      match self.peek() {
        Some('+') | Some('-') => self.advance()
        _ => ()
      }
      while not(self.at_end()) {
        match self.peek() {
          Some(c) if is_digit(c) => self.advance()
          _ => break
        }
      }
    }
    _ => ()
  }
  { node_type: Number, from: start, to: self.pos }
}

///|
/// Read a keyword (true, false, null)
pub fn JsonTokenizer::read_keyword(self : JsonTokenizer) -> JsonToken {
  let start = self.pos

  // Read word
  while not(self.at_end()) {
    match self.peek() {
      Some(c) if c >= 'a' && c <= 'z' => self.advance()
      _ => break
    }
  }
  let word = self.input.substring(start~, end=self.pos)
  let node_type = match word {
    "true" => True
    "false" => False
    "null" => Null
    _ => Error
  }
  { node_type, from: start, to: self.pos }
}

///|
/// Get next token
pub fn JsonTokenizer::next_token(self : JsonTokenizer) -> JsonToken? {
  self.skip_whitespace()
  if self.at_end() {
    return None
  }
  let start = self.pos
  match self.peek() {
    Some('{') => {
      self.advance()
      Some({ node_type: BraceOpen, from: start, to: self.pos })
    }
    Some('}') => {
      self.advance()
      Some({ node_type: BraceClose, from: start, to: self.pos })
    }
    Some('[') => {
      self.advance()
      Some({ node_type: BracketOpen, from: start, to: self.pos })
    }
    Some(']') => {
      self.advance()
      Some({ node_type: BracketClose, from: start, to: self.pos })
    }
    Some(':') => {
      self.advance()
      Some({ node_type: Colon, from: start, to: self.pos })
    }
    Some(',') => {
      self.advance()
      Some({ node_type: Comma, from: start, to: self.pos })
    }
    Some('"') => Some(self.read_string())
    Some('-') => Some(self.read_number())
    Some(c) if is_digit(c) => Some(self.read_number())
    Some('t') | Some('f') | Some('n') => Some(self.read_keyword())
    _ => {
      self.advance()
      Some({ node_type: Error, from: start, to: self.pos })
    }
  }
}

///|
/// Tokenize entire input
pub fn JsonTokenizer::tokenize_all(self : JsonTokenizer) -> Array[JsonToken] {
  let tokens : Array[JsonToken] = []
  while true {
    match self.next_token() {
      Some(token) => tokens.push(token)
      None => break
    }
  }
  tokens
}

// =============================================================================
// JSON Parser
// =============================================================================

///|
/// JSON Parser - builds a Tree from tokens
pub(all) struct JsonParser {
  input : String
  priv tokens : Array[JsonToken]
  priv mut pos : Int
}

///|
/// Create a new parser
pub fn JsonParser::new(input : String) -> JsonParser {
  let tokenizer = JsonTokenizer::new(input)
  let tokens = tokenizer.tokenize_all()
  { input, tokens, pos: 0 }
}

///|
/// Check if at end of tokens
pub fn JsonParser::at_end(self : JsonParser) -> Bool {
  self.pos >= self.tokens.length()
}

///|
/// Peek current token
pub fn JsonParser::peek(self : JsonParser) -> JsonToken? {
  if self.pos < self.tokens.length() {
    Some(self.tokens[self.pos])
  } else {
    None
  }
}

///|
/// Advance to next token
pub fn JsonParser::advance(self : JsonParser) -> JsonToken? {
  if self.pos < self.tokens.length() {
    let token = self.tokens[self.pos]
    self.pos += 1
    Some(token)
  } else {
    None
  }
}

///|
/// Expect a specific token type
pub fn JsonParser::expect(
  self : JsonParser,
  expected : JsonNodeId,
) -> JsonToken? {
  match self.peek() {
    Some(token) if token.node_type == expected => self.advance()
    _ => None
  }
}

///|
/// Parse a JSON value
pub fn JsonParser::parse_value(self : JsonParser) -> Tree? {
  match self.peek() {
    Some(token) =>
      match token.node_type {
        BraceOpen => self.parse_object()
        BracketOpen => self.parse_array()
        String => {
          let _ = self.advance()
          Some(Tree::leaf(json_node_type(String), token.from, token.to))
        }
        Number => {
          let _ = self.advance()
          Some(Tree::leaf(json_node_type(Number), token.from, token.to))
        }
        True => {
          let _ = self.advance()
          Some(Tree::leaf(json_node_type(True), token.from, token.to))
        }
        False => {
          let _ = self.advance()
          Some(Tree::leaf(json_node_type(False), token.from, token.to))
        }
        Null => {
          let _ = self.advance()
          Some(Tree::leaf(json_node_type(Null), token.from, token.to))
        }
        _ => None
      }
    None => None
  }
}

///|
/// Parse a JSON object
pub fn JsonParser::parse_object(self : JsonParser) -> Tree? {
  let open_brace = self.expect(BraceOpen)
  guard open_brace is Some(open_token) else { return None }
  let children : Array[Tree] = []
  let start = open_token.from

  // Add opening brace as child
  children.push(
    Tree::leaf(json_node_type(BraceOpen), open_token.from, open_token.to),
  )

  // Parse properties
  while not(self.at_end()) {
    match self.peek() {
      Some(token) if token.node_type == BraceClose => break
      Some(token) if token.node_type == String => {
        // Parse property
        match self.parse_property() {
          Some(prop) => children.push(prop)
          None => break
        }

        // Handle comma
        match self.peek() {
          Some(comma_token) if comma_token.node_type == Comma => {
            let _ = self.advance()
            children.push(
              Tree::leaf(
                json_node_type(Comma),
                comma_token.from,
                comma_token.to,
              ),
            )
          }
          _ => ()
        }
      }
      _ => break
    }
  }

  // Closing brace
  let close_brace = self.expect(BraceClose)
  let end = match close_brace {
    Some(token) => {
      children.push(
        Tree::leaf(json_node_type(BraceClose), token.from, token.to),
      )
      token.to
    }
    None =>
      // Error recovery: use last known position
      if children.length() > 0 {
        children[children.length() - 1].to()
      } else {
        start + 1
      }
  }
  Some(Tree::node(json_node_type(Object), start, end, children))
}

///|
/// Parse a property (key: value)
pub fn JsonParser::parse_property(self : JsonParser) -> Tree? {
  let key = self.expect(String)
  guard key is Some(key_token) else { return None }
  let start = key_token.from
  let children : Array[Tree] = []

  // Property name (different from regular string for highlighting)
  children.push(
    Tree::leaf(json_node_type(PropertyName), key_token.from, key_token.to),
  )

  // Colon
  let colon = self.expect(Colon)
  match colon {
    Some(colon_token) =>
      children.push(
        Tree::leaf(json_node_type(Colon), colon_token.from, colon_token.to),
      )
    None => ()
  }

  // Value
  match self.parse_value() {
    Some(value) => children.push(value)
    None => ()
  }
  let end = if children.length() > 0 {
    children[children.length() - 1].to()
  } else {
    key_token.to
  }
  Some(Tree::node(json_node_type(Property), start, end, children))
}

///|
/// Parse a JSON array
pub fn JsonParser::parse_array(self : JsonParser) -> Tree? {
  let open_bracket = self.expect(BracketOpen)
  guard open_bracket is Some(open_token) else { return None }
  let children : Array[Tree] = []
  let start = open_token.from

  // Add opening bracket as child
  children.push(
    Tree::leaf(json_node_type(BracketOpen), open_token.from, open_token.to),
  )

  // Parse elements
  while not(self.at_end()) {
    match self.peek() {
      Some(token) if token.node_type == BracketClose => break
      _ => {
        match self.parse_value() {
          Some(value) => children.push(value)
          None => break
        }

        // Handle comma
        match self.peek() {
          Some(comma_token) if comma_token.node_type == Comma => {
            let _ = self.advance()
            children.push(
              Tree::leaf(
                json_node_type(Comma),
                comma_token.from,
                comma_token.to,
              ),
            )
          }
          _ => ()
        }
      }
    }
  }

  // Closing bracket
  let close_bracket = self.expect(BracketClose)
  let end = match close_bracket {
    Some(token) => {
      children.push(
        Tree::leaf(json_node_type(BracketClose), token.from, token.to),
      )
      token.to
    }
    None =>
      if children.length() > 0 {
        children[children.length() - 1].to()
      } else {
        start + 1
      }
  }
  Some(Tree::node(json_node_type(Array), start, end, children))
}

///|
/// Parse a complete JSON document
pub fn JsonParser::parse(self : JsonParser) -> Tree? {
  let value = self.parse_value()
  match value {
    Some(v) =>
      Some(Tree::node(json_node_type(JsonDocument), v.from(), v.to(), [v]))
    None => None
  }
}

// =============================================================================
// Convenience function
// =============================================================================

///|
/// Parse JSON string and return tree
pub fn parse_json(input : String) -> Tree? {
  let parser = JsonParser::new(input)
  parser.parse()
}
