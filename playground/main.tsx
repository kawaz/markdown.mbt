// 
import { md_parse, md_render_to_string, md_free } from "../target/js/release/build/markdown.js";

const handle = md_parse("# Hello\n\nWorld");
const output = md_render_to_string(handle);

const textArea = document.querySelector("textarea")!
textArea.value = output;

const outputElement = document.querySelector("#output")!
outputElement.textContent = output;

// textArea.style.width = "100%";
// textArea.style.height = "100vh";
textArea.addEventListener("input", (e) => {
  const value = (e.target as HTMLTextAreaElement).value;
  const handle = md_parse(value);
  console.log(handle);

  const output = md_render_to_string(handle);
  outputElement.textContent = output;
  md_free(handle);
});

