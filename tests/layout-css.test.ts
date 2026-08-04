import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const css = readFileSync(
  resolve(process.cwd(), "src/style.css"),
  "utf-8",
);

describe("layout hardening styles", () => {
  it("removes magic height calculation from instagram grid", () => {
    expect(css).not.toContain("height: calc(100% - 80px)");
    expect(css).toContain(".instagram-card");
    expect(css).toContain("display: flex");
    expect(css).toContain(".instagram-hero");
    expect(css).toContain(".instagram-stories");
    expect(css).toContain("flex: 1");
  });

  it("prevents link card preview from collapsing", () => {
    expect(css).toContain(".link-preview");
    expect(css).toContain("min-height: 100%");
  });

  it("allows long link text to wrap without horizontal overflow", () => {
    expect(css).toContain(".link-info");
    expect(css).toContain("min-width: 0");
    expect(css).toContain("overflow-wrap: anywhere");
  });

  it("renders service social cards at the full category width", () => {
    expect(css).toContain(".category-section--service .social-card");
    expect(css).toContain("grid-column: span 2");
  });

  it("keeps the final LINE social card accessible and full width", () => {
    expect(css).toContain(".category-section--sns .lineworks");
    expect(css).toContain(".lineworks { background-color: #007a33; color: white; }");
    expect(css).toContain(".lineworks .card-sublabel { color: white; }");
  });
});
