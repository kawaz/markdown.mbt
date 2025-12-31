///| Moonlight SVG Editor wrapper component
///| Provides bidirectional editing of SVG in markdown code blocks

import { createSignal, createEffect, onMount, onCleanup } from "@luna_ui/luna";
import { sanitizeSvg } from "./ast-renderer";

// Type for the actual MoonlightEditor API (when loaded)
interface MoonlightEditorAPI {
  importSvg(svg: string): void;
  exportSvg(): string;
  onChange(callback: () => void): () => void;
  destroy(): void;
  setReadonly(readonly: boolean): void;
}

// Declare global MoonlightEditor constructor
declare global {
  interface Window {
    MoonlightEditor?: {
      create(
        container: HTMLElement,
        options: {
          width?: number;
          height?: number;
          docWidth?: number;
          docHeight?: number;
          zoom?: number;
          theme?: "light" | "dark";
          readonly?: boolean;
          initialSvg?: string | null;
        }
      ): MoonlightEditorAPI;
    };
  }
}

export interface MoonlightEditorProps {
  /** Initial SVG content */
  initialSvg: string;
  /** Data span for source mapping */
  span: string;
  /** Callback when SVG is changed */
  onSvgChange?: (svg: string, span: string) => void;
  /** Editor width */
  width?: number;
  /** Editor height */
  height?: number;
  /** Read-only mode (shows preview only) */
  readonly?: boolean;
}

/**
 * MoonlightEditor component for SVG editing
 * Falls back to static preview if moonlight is not loaded
 */
export function MoonlightEditor(props: MoonlightEditorProps) {
  const {
    initialSvg,
    span,
    onSvgChange,
    width = 400,
    height = 300,
    readonly = false,
  } = props;

  let containerRef: HTMLDivElement | null = null;
  let editorRef: MoonlightEditorAPI | null = null;
  const [isLoaded, setIsLoaded] = createSignal(false);
  const [currentSvg, setCurrentSvg] = createSignal(initialSvg);

  // Initialize moonlight editor
  const initEditor = () => {
    if (!containerRef || !window.MoonlightEditor) return false;

    try {
      editorRef = window.MoonlightEditor.create(containerRef, {
        width,
        height,
        docWidth: width,
        docHeight: height,
        theme: "light",
        readonly,
        initialSvg: sanitizeSvg(initialSvg),
      });

      // Subscribe to changes
      if (!readonly && onSvgChange) {
        editorRef.onChange(() => {
          const svg = editorRef!.exportSvg();
          setCurrentSvg(svg);
          onSvgChange(svg, span);
        });
      }

      setIsLoaded(true);
      return true;
    } catch (e) {
      console.error("Failed to initialize MoonlightEditor:", e);
      return false;
    }
  };

  // Try to initialize moonlight editor
  onMount(async () => {
    if (!containerRef) return;

    // Try immediate init if already loaded
    if (initEditor()) return;

    // Load script and retry
    const loaded = await loadMoonlight();
    if (loaded) {
      initEditor();
    }
  });

  // Cleanup
  onCleanup(() => {
    if (editorRef) {
      editorRef.destroy();
      editorRef = null;
    }
  });

  // Update editor when external SVG changes
  createEffect(() => {
    const svg = currentSvg();
    if (editorRef && svg !== initialSvg) {
      // Only import if different from what editor exported
      // to avoid infinite loops
    }
  });

  // Fallback: static SVG preview
  const renderFallback = () => (
    <div
      class="moonlight-fallback"
      data-span={span}
      style={{
        width: `${width}px`,
        height: `${height}px`,
        border: "1px solid #e1e4e8",
        borderRadius: "6px",
        overflow: "hidden",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        backgroundColor: "#f6f8fa",
      }}
      ref={(el) => {
        if (el) el.innerHTML = sanitizeSvg(initialSvg);
      }}
    />
  );

  return (
    <div class="moonlight-editor-wrapper" data-span={span}>
      <div
        ref={(el) => {
          containerRef = el;
        }}
        style={{
          width: `${width}px`,
          height: `${height}px`,
          display: isLoaded() ? "block" : "none",
        }}
      />
      {!isLoaded() && renderFallback()}
    </div>
  );
}

// Moonlight CDN URL
const MOONLIGHT_CDN_URL = "https://moonlight.mizchi.workers.dev/moonlight-editor.component.js";

// Track loading state
let loadingPromise: Promise<boolean> | null = null;

/**
 * Load moonlight editor script dynamically
 * Call this to enable full editing capabilities
 */
export async function loadMoonlight(): Promise<boolean> {
  if (window.MoonlightEditor) {
    return true;
  }

  // Return existing promise if already loading
  if (loadingPromise) {
    return loadingPromise;
  }

  loadingPromise = new Promise((resolve) => {
    const script = document.createElement("script");
    script.src = MOONLIGHT_CDN_URL;
    script.async = true;
    script.onload = () => {
      console.log("Moonlight editor loaded successfully");
      resolve(true);
    };
    script.onerror = () => {
      console.error("Failed to load Moonlight editor from CDN");
      resolve(false);
    };
    document.head.appendChild(script);
  });

  return loadingPromise;
}
