import { describe, expect, it } from "vitest";
import { siteConfig, type Card } from "../src/config";
import { renderIndexHtml } from "../src/render-index";

describe("siteConfig shape", () => {
  it("contains profile and at least one card item", () => {
    expect(siteConfig.profile.name.length).toBeGreaterThan(0);
    expect(siteConfig.profile.bio.length).toBeGreaterThan(0);
    expect(siteConfig.cards.length).toBeGreaterThan(0);
  });
});

describe("renderIndexHtml", () => {
  it("renders all configured external links with noopener and noreferrer", () => {
    const html = renderIndexHtml(siteConfig);

    for (const card of siteConfig.cards) {
      if (!("url" in card)) {
        continue;
      }

      expect(html).toContain(`href="${card.url}"`);
      expect(html).toContain('target="_blank" rel="noopener noreferrer"');
    }
  });

  it("does not render blocked fallback label for Sora card", () => {
    const html = renderIndexHtml(siteConfig);
    expect(html).not.toContain("Just a moment...");
  });

  it("renders meta description", () => {
    const html = renderIndexHtml(siteConfig);
    expect(html).toContain('meta name="description"');
    expect(html).toContain(siteConfig.meta.description);
  });

  it("renders the configurable profile bio", () => {
    const html = renderIndexHtml(siteConfig);

    expect(html).toContain('class="profile-bio"');
    expect(html).toContain(siteConfig.profile.bio);
  });

  it("uses the supplied social URLs and places the website first", () => {
    const html = renderIndexHtml(siteConfig);
    const [firstCard] = siteConfig.cards;

    expect(firstCard).toMatchObject({
      className: "website",
      url: "https://tori-dev.com/",
    });
    expect(html).toContain('href="https://www.instagram.com/tori_create_7991/"');
    expect(html).toContain('href="https://www.threads.com/@tori_create_7991"');
    expect(html).toContain('href="https://bsky.app/profile/tori-create-7991.bsky.social"');
    expect(html).toContain('fa-brands fa-threads');
    expect(html).toContain('fa-brands fa-bluesky');
  });

  it("groups the requested social links under an SNS heading", () => {
    const html = renderIndexHtml(siteConfig);
    const snsCards = siteConfig.cards.filter((card) => card.category === "sns");

    expect(html).toContain('class="category-section category-section--sns category-section--count-9"');
    expect(html).toContain('style="--category-row-count: 5"');
    expect(html).toContain('<h2 id="sns-heading">SNS</h2>');
    expect(html).toContain('class="category-section category-section--hobby category-section--count-2"');
    expect(html).toContain('<h2 id="hobby-heading">HOBBY</h2>');
    expect(html).toContain('class="category-section category-section--service category-section--count-2"');
    expect(html).toContain('<h2 id="service-heading">SERVICE</h2>');
    expect(html.indexOf('id="service-heading"')).toBeLessThan(
      html.indexOf('id="hobby-heading"'),
    );
    expect(snsCards.map((card) => card.label)).toEqual([
      "Twitter",
      "Instagram",
      "Threads",
      "Bluesky",
      "LinkedIn",
      "Facebook",
      "利根川 諒のプロフィール",
      "YOUTRUST",
      "LINE",
    ]);
    expect(snsCards.map((card) => card.type)).toEqual([
      "social",
      "social",
      "social",
      "social",
      "social",
      "social",
      "social",
      "social",
      "social",
    ]);
    expect(
      siteConfig.cards.find((card) => card.className === "yamap"),
    ).toMatchObject({ category: "hobby" });
    expect(
      siteConfig.cards.find((card) => card.className === "wantedly"),
    ).toMatchObject({ category: "sns" });
    expect(
      siteConfig.cards.find((card) => card.className === "youtrust"),
    ).toMatchObject({
      category: "sns",
      url: "https://youtrust.jp/users/ryo_tonegawa",
    });
    expect(
      siteConfig.cards.find((card) => card.className === "lancers"),
    ).toMatchObject({ category: "service" });
    expect(
      siteConfig.cards.find((card) => card.className === "github"),
    ).toMatchObject({ category: "service" });
    expect(
      siteConfig.cards.find((card) => card.className === "lineworks"),
    ).toMatchObject({
      category: "sns",
      label: "LINE",
      url: "https://contact.worksmobile.com/p/worksat-invitation?externalCode=fb5f0b8d-90d5-4f30-a7ca-04ca136376ed",
    });
    expect(
      siteConfig.cards.find((card) => card.className === "sora"),
    ).toMatchObject({ category: "hobby" });
    expect(html).not.toContain('aria-hidden="true">SNS</span>');
    expect(html).not.toContain('class="card instagram-card"');
  });

  it("keeps a category in one section when its cards are not adjacent", () => {
    const extraSocialCard: Card = {
      type: "social",
      className: "example-social",
      url: "https://example.com/social",
      category: "sns",
      iconClass: "fa-solid fa-link",
      label: "Example",
      sublabel: "example.com",
    };
    const html = renderIndexHtml({
      ...siteConfig,
      cards: [...siteConfig.cards, extraSocialCard],
    });

    expect((html.match(/category-section--sns/g) ?? []).length).toBe(1);
    expect(html).toContain('href="https://example.com/social"');
  });

  it("allocates two rows for a categorized Instagram card", () => {
    const instagramCard: Card = {
      type: "instagram",
      category: "sns",
      url: "https://example.com/instagram",
      iconClass: "fa-brands fa-instagram",
      label: "Example Instagram",
      sublabel: "example.com",
      images: [],
    };
    const html = renderIndexHtml({
      ...siteConfig,
      cards: [...siteConfig.cards, instagramCard],
    });

    expect(html).toContain('style="--category-row-count: 7"');
  });
});
