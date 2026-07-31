import type { Card, CardCategory, SiteConfig } from "./config";

const EXTERNAL_REL = 'target="_blank" rel="noopener noreferrer"';

function escapeHtml(value: string): string {
  return value
    .replaceAll("\r", "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function renderSocialCard(card: Extract<Card, { type: "social" }>): string {
  return `
      <a href="${escapeHtml(card.url)}" ${EXTERNAL_REL} class="card social-card ${escapeHtml(card.className)}">
        <div class="icon-wrapper"><i class="${escapeHtml(card.iconClass)}"></i></div>
        <div class="card-label">${escapeHtml(card.label)}</div>
        <div class="card-sublabel">${escapeHtml(card.sublabel)}</div>
      </a>`;
}

function renderInstagramCard(card: Extract<Card, { type: "instagram" }>): string {
  const [hero, ...stories] = card.images;

  const heroHtml = hero
    ? `<a href="${escapeHtml(hero.href)}" ${EXTERNAL_REL} class="instagram-tile instagram-tile--hero"><img src="${escapeHtml(hero.src)}" alt="${escapeHtml(hero.alt)}" loading="lazy"></a>`
    : "";

  const storiesHtml = stories
    .map(
      (image) =>
        `<a href="${escapeHtml(image.href)}" ${EXTERNAL_REL} class="instagram-tile instagram-tile--story"><img src="${escapeHtml(image.src)}" alt="${escapeHtml(image.alt)}" loading="lazy"></a>`,
    )
    .join("\n          ");

  return `
      <div class="card instagram-card">
        <div class="instagram-header">
            <div class="icon-wrapper"><i class="${escapeHtml(card.iconClass)}"></i></div>
            <div class="header-text">
                <a href="${escapeHtml(card.url)}" ${EXTERNAL_REL} class="instagram-title-link">
                  <div class="card-label">${escapeHtml(card.label)}</div>
                  <div class="card-sublabel">${escapeHtml(card.sublabel)}</div>
                </a>
            </div>
        </div>
        <div class="instagram-hero">
          ${heroHtml}
        </div>
        <div class="instagram-stories">
          ${storiesHtml}
        </div>
      </div>`;
}

function renderLinkCard(card: Extract<Card, { type: "link" }>): string {
  return `
      <a href="${escapeHtml(card.url)}" ${EXTERNAL_REL} class="card link-card ${escapeHtml(card.className)}">
         <div class="link-preview" style="background-image: url('${escapeHtml(card.previewImageUrl)}');"></div>
         <div class="link-info">
            <div class="card-label">${escapeHtml(card.label)}</div>
            <div class="card-sublabel">${escapeHtml(card.sublabel)}</div>
         </div>
      </a>`;
}

function renderCard(card: Card): string {
  if (card.type === "social") {
    return renderSocialCard(card);
  }
  if (card.type === "instagram") {
    return renderInstagramCard(card);
  }
  return renderLinkCard(card);
}

function getCategoryRowCount(cards: Card[]): number {
  let rows = 0;
  let occupiedColumns = 0;

  for (const card of cards) {
    if (card.type === "instagram") {
      occupiedColumns = 0;
      rows += 2;
      continue;
    }

    if (card.type === "link") {
      occupiedColumns = 0;
      rows += 1;
      continue;
    }

    if (occupiedColumns === 0) {
      rows += 1;
    }
    occupiedColumns += 1;
    if (occupiedColumns === 2) {
      occupiedColumns = 0;
    }
  }

  return Math.max(rows, 1);
}

function renderCategorySection(category: CardCategory, cards: Card[]): string {
  const headingId = `${category}-heading`;
  const rowCount = getCategoryRowCount(cards);

  return `
      <section class="category-section category-section--${escapeHtml(category)} category-section--count-${cards.length}" style="--category-row-count: ${rowCount}" aria-labelledby="${headingId}">
        <h2 id="${headingId}">${escapeHtml(category.toUpperCase())}</h2>
        <div class="category-cards">
${cards.map((card) => renderCard(card)).join("\n")}
        </div>
      </section>`;
}

export function renderIndexHtml(config: SiteConfig): string {
  const renderedCards: string[] = [];
  const renderedCategories = new Set<CardCategory>();

  for (const card of config.cards) {
    if (!card.category) {
      renderedCards.push(renderCard(card));
      continue;
    }

    const category = card.category;
    if (renderedCategories.has(category)) {
      continue;
    }
    renderedCategories.add(category);
    const categoryCards = config.cards.filter(
      (candidate) => candidate.category === category,
    );
    renderedCards.push(renderCategorySection(category, categoryCards));
  }
  const cards = renderedCards.join("\n");

  return `<!DOCTYPE html>
<html lang="ja">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="${escapeHtml(config.meta.description)}" />
    <title>${escapeHtml(config.meta.title)}</title>
    <link rel="stylesheet" href="style.css" />
    <link
      rel="stylesheet"
      href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.6.0/css/all.min.css"
    />
    <link rel="icon" type="image/png" href="${escapeHtml(config.meta.favicon)}" />
  </head>
  <body>
    <div class="bento-container">
      <div class="card profile-card">
        <div class="profile-content">
          <img src="${escapeHtml(config.profile.imageUrl)}" alt="${escapeHtml(config.profile.imageAlt)}" class="profile-img" />
          <div class="profile-text">
            <h1>${escapeHtml(config.profile.name)}</h1>
            <p>${escapeHtml(config.profile.role)}</p>
            <p class="profile-bio">${escapeHtml(config.profile.bio)}</p>
          </div>
        </div>
      </div>
${cards}
    </div>
  </body>
</html>
`;
}
