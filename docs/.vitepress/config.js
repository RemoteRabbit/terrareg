import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'terrareg',
  description: 'A modern Neovim plugin for better development workflow',
  base: '/terrareg/',

  head: [
    ['link', { rel: 'icon', href: '/terrareg/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#7c3aed' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:locale', content: 'en' }],
    ['meta', { property: 'og:title', content: 'terrareg | Modern Neovim Plugin' }],
    ['meta', { property: 'og:site_name', content: 'terrareg' }],
    ['meta', { property: 'og:image', content: 'https://remoterabbit.github.io/terrareg/og-image.png' }],
    ['meta', { property: 'og:url', content: 'https://remoterabbit.github.io/terrareg/' }],
  ],

  themeConfig: {
    logo: '/logo.svg',

    nav: [
      { text: 'Guide', link: '/guide/' },
      { text: 'API', link: '/api/' },
      { text: 'Examples', link: '/examples/' },
      {
        text: 'Links',
        items: [
          { text: 'GitHub', link: 'https://github.com/RemoteRabbit/terrareg' },
          { text: 'Issues', link: 'https://github.com/RemoteRabbit/terrareg/issues' },
          { text: 'Discussions', link: 'https://github.com/RemoteRabbit/terrareg/discussions' }
        ]
      }
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Introduction', link: '/guide/' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Quick Start', link: '/guide/quick-start' },
            { text: 'Configuration', link: '/guide/configuration' }
          ]
        },
        {
          text: 'Usage',
          items: [
            { text: 'Basic Usage', link: '/guide/usage' },
            { text: 'Advanced Features', link: '/guide/advanced' },
            { text: 'Best Practices', link: '/guide/best-practices' }
          ]
        }
      ],
      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'Overview', link: '/api/' },
            { text: 'Auto-Generated API', link: '/api/auto-generated' },
            { text: 'Configuration', link: '/api/configuration' },
            { text: 'Utilities', link: '/api/utilities' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/RemoteRabbit/terrareg' }
    ],

    footer: {
      message: 'Released under the GPL-3.0 License.',
      copyright: 'Copyright © 2025 RemoteRabbit'
    },

    search: {
      provider: 'local'
    },

    editLink: {
      pattern: 'https://github.com/RemoteRabbit/terrareg/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },

    lastUpdated: {
      text: 'Updated at',
      formatOptions: {
        dateStyle: 'full',
        timeStyle: 'medium'
      }
    }
  },

  markdown: {
    theme: 'github-dark',
    lineNumbers: true
  }
})
