export type SiteMeta = {
  title: string
  description: string
  favicon: string
}

export type Profile = {
  name: string
  role: string
  bio: string
  imageUrl: string
  imageAlt: string
}

export type CardCategory = 'sns' | 'hobby' | 'service'

export type CardCategoryFields = {
  category?: CardCategory
}

export type SocialCard = CardCategoryFields & {
  type: 'social'
  className: string
  url: string
  iconClass: string
  label: string
  sublabel: string
}

export type ScrapeFields = {
  sourceUrl?: string
  scrape?: boolean
  fallbackImage?: string
  fallbackLabel?: string
  fallbackDescription?: string
}

export type LinkCard = CardCategoryFields & {
  type: 'link'
  className: string
  url: string
  previewImageUrl: string
  label: string
  sublabel: string
} & ScrapeFields

export type InstagramCard = CardCategoryFields & {
  type: 'instagram'
  url: string
  iconClass: string
  label: string
  sublabel: string
  images: Array<{
    src: string
    alt: string
    href: string
    sourceUrl?: string
    scrape?: boolean
  }>
} & ScrapeFields

export type Card = SocialCard | LinkCard | InstagramCard

export type SiteConfig = {
  meta: SiteMeta
  profile: Profile
  cards: Card[]
}

const profileImage = '/images/profile-ryo.png'

export const siteConfig: SiteConfig = {
  meta: {
    title: 'Ryo.Tonegawa | Link in Bio',
    description:
      'Ryo.Tonegawa のリンクまとめページ。SNS、制作実績、プロフィールへの導線を1ページで確認できます。',
    favicon: profileImage,
  },
  profile: {
    name: 'Ryo.Tonegawa',
    role: 'フリーランス エンジニア & 講師',
    bio: 'Web開発・講師・DX/AXのご相談、お気軽にどうぞ。',
    imageUrl: profileImage,
    imageAlt: 'Ryo.Tonegawaのプロフィール画像',
  },
  cards: [
    {
      type: 'link',
      className: 'website',
      url: 'https://tori-dev.com/',
      sourceUrl: 'https://tori-dev.com/',
      scrape: true,
      previewImageUrl:
        'https://storage.googleapis.com/creatorspace-public/sites/ogimages/aHR0cHM6Ly90b3JpLWRldi5jb20vaW1hZ2VzL2FsZm9ucy1tb3JhbGVzLVlMU3dqU3k3c3R3LXVuc3BsYXNoLmpwZw==.jpeg',
      label: 'tori-dev',
      sublabel: 'tori-dev.com',
      fallbackImage:
        'https://storage.googleapis.com/creatorspace-public/sites/ogimages/aHR0cHM6Ly90b3JpLWRldi5jb20vaW1hZ2VzL2FsZm9ucy1tb3JhbGVzLVlMU3dqU3k3c3R3LXVuc3BsYXNoLmpwZw==.jpeg',
      fallbackLabel: 'tori-dev',
      fallbackDescription: 'tori-dev.com',
    },
    {
      type: 'social',
      className: 'twitter',
      url: 'https://x.com/tori_create',
      category: 'sns',
      iconClass: 'fa-brands fa-twitter',
      label: 'Twitter',
      sublabel: 'tori_create',
    },
    {
      type: 'social',
      className: 'instagram',
      url: 'https://www.instagram.com/tori_create_7991/',
      category: 'sns',
      iconClass: 'fa-brands fa-instagram',
      label: 'Instagram',
      sublabel: '@tori_create_7991',
    },
    {
      type: 'social',
      className: 'threads',
      url: 'https://www.threads.com/@tori_create_7991',
      category: 'sns',
      iconClass: 'fa-brands fa-threads',
      label: 'Threads',
      sublabel: '@tori_create_7991',
    },
    {
      type: 'social',
      className: 'bluesky',
      url: 'https://bsky.app/profile/tori-create-7991.bsky.social',
      category: 'sns',
      iconClass: 'fa-brands fa-bluesky',
      label: 'Bluesky',
      sublabel: 'bsky.app',
    },
    {
      type: 'social',
      className: 'linkedin',
      url: 'https://linkedin.com/in/tori-dev',
      category: 'sns',
      iconClass: 'fa-brands fa-linkedin',
      label: 'LinkedIn',
      sublabel: 'tori-dev',
    },
    {
      type: 'social',
      className: 'facebook',
      url: 'https://www.facebook.com/profile.php?id=100004853536494',
      category: 'sns',
      iconClass: 'fa-brands fa-facebook',
      label: 'Facebook',
      sublabel: 'ryo.tonegawa',
    },
    {
      type: 'social',
      className: 'wantedly',
      url: 'https://www.wantedly.com/id/ryo_tonegawa',
      category: 'sns',
      iconClass: 'fa-solid fa-briefcase',
      label: '利根川 諒のプロフィール',
      sublabel: 'Wantedly',
    },
    {
      type: 'social',
      className: 'youtrust',
      url: 'https://youtrust.jp/users/ryo_tonegawa',
      category: 'sns',
      iconClass: 'fa-solid fa-users',
      label: 'YOUTRUST',
      sublabel: 'ryo_tonegawa',
    },
    {
      type: 'social',
      className: 'github',
      url: 'https://github.com/tori-create-7991',
      category: 'service',
      iconClass: 'fa-brands fa-github',
      label: 'GitHub',
      sublabel: 'tori-create-7991',
    },
    {
      type: 'link',
      className: 'lancers',
      url: 'https://www.lancers.jp/profile/rito-1345',
      category: 'service',
      sourceUrl: 'https://www.lancers.jp/profile/rito-1345',
      scrape: true,
      previewImageUrl:
        'https://storage.googleapis.com/creatorspace-public/sites/ogimages/aHR0cHM6Ly9pbWcyLmxhbmNlcnMuanAvdXNlcnByb2ZpbGUvOTA5Nzc4LzEzOTY2MzMvNmU1NGQyNjE0MWZhMTQxNmUyZGU2N2EwZWY1Y2U2M2VjNWFjYjAzMGExNGIzMTlhYzliY2RhNDEzYWQxYTUwOC8zNzQ1NjUxN18xNTBfMC5qcGc=.jpeg',
      label: 'tonegawa ryo (rito-1345)',
      sublabel: 'lancers.jp',
      fallbackImage:
        'https://storage.googleapis.com/creatorspace-public/sites/ogimages/aHR0cHM6Ly9pbWcyLmxhbmNlcnMuanAvdXNlcnByb2ZpbGUvOTA5Nzc4LzEzOTY2MzMvNmU1NGQyNjE0MWZhMTQxNmUyZGU2N2EwZWY1Y2U2M2VjNWFjYjAzMGExNGIzMTlhYzliY2RhNDEzYWQxYTUwOC8zNzQ1NjUxN18xNTBfMC5qcGc=.jpeg',
      fallbackLabel: 'tonegawa ryo (rito-1345)',
      fallbackDescription: 'lancers.jp',
    },
    {
      type: 'social',
      className: 'lineworks',
      url: 'https://contact.worksmobile.com/p/worksat-invitation?externalCode=fb5f0b8d-90d5-4f30-a7ca-04ca136376ed',
      category: 'sns',
      iconClass: 'fa-brands fa-line',
      label: 'LINE',
      sublabel: 'works.do',
    },
    {
      type: 'link',
      className: 'yamap',
      url: 'https://yamap.com/users/2542531',
      category: 'hobby',
      sourceUrl: 'https://yamap.com/users/2542531',
      scrape: true,
      previewImageUrl:
        'https://storage.googleapis.com/creatorspace-public/sites/ogimages/aHR0cHM6Ly9hc3NldHMueWFtYXAuY29tL2ltYWdlcy9vZ3BfbmV3LnBuZw==.png',
      label: 'ryo | YAMAP / ヤマップ',
      sublabel: 'yamap.com',
      fallbackImage:
        'https://storage.googleapis.com/creatorspace-public/sites/ogimages/aHR0cHM6Ly9hc3NldHMueWFtYXAuY29tL2ltYWdlcy9vZ3BfbmV3LnBuZw==.png',
      fallbackLabel: 'ryo | YAMAP / ヤマップ',
      fallbackDescription: 'yamap.com',
    },
    {
      type: 'link',
      className: 'sora',
      url: 'https://sora.chatgpt.com/profile/tori_24',
      category: 'hobby',
      sourceUrl: 'https://sora.chatgpt.com/profile/tori_24',
      scrape: true,
      previewImageUrl:
        'https://storage.googleapis.com/creatorspace-public/sites/aHR0cHM6Ly9zb3JhLmNoYXRncHQuY29tL3Byb2ZpbGUvdG9yaV8yNA==/screenshot.jpeg',
      label: 'Sora Profile',
      sublabel: 'sora.chatgpt.com',
      fallbackImage:
        'https://storage.googleapis.com/creatorspace-public/sites/aHR0cHM6Ly9zb3JhLmNoYXRncHQuY29tL3Byb2ZpbGUvdG9yaV8yNA==/screenshot.jpeg',
      fallbackLabel: 'Sora Profile',
      fallbackDescription: 'sora.chatgpt.com',
    },
  ],
}
