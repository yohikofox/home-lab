import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'Home Lab Documentation',
  tagline: 'Infrastructure as Code et automatisations pour home lab personnel',
  favicon: 'img/favicon.ico',

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // Set the production url of your site here
  url: 'https://docs.example.local',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'homelab-user', // Usually your GitHub org/user name.
  projectName: 'home-lab', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'fr',
    locales: ['fr'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/homelab-user/home-lab/tree/main/docs/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themes: ['@docusaurus/theme-mermaid'],
  
  markdown: {
    mermaid: true,
  },

  themeConfig: {
    // Replace with your project's social card
    image: 'img/docusaurus-social-card.jpg',
    
    // Color mode configuration
    colorMode: {
      defaultMode: 'light',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
    
    // Configuration Mermaid pour les thèmes
    mermaid: {
      theme: {
        light: 'neutral',
        dark: 'dark'
      }
    },
    navbar: {
      title: 'Home Lab Documentation',
      logo: {
        alt: 'Home Lab Logo',
        src: 'img/homelab-logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'Tutorial',
        },
        {
          href: 'https://github.com/facebook/docusaurus',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Introduction',
              to: '/docs/intro',
            },
            {
              label: 'Architecture',
              to: '/docs/ARCHITECTURE',
            },
            {
              label: 'Installation',
              to: '/docs/INSTALLATION',
            },
          ],
        },
        {
          title: 'Infrastructure',
          items: [
            {
              label: 'Services',
              to: '/docs/SERVICES',
            },
            {
              label: 'Réseau',
              to: '/docs/NETWORK',
            },
            {
              label: 'Workflows',
              to: '/docs/WORKFLOWS',
            },
          ],
        },
        {
          title: 'Ressources',
          items: [
            {
              label: 'GitHub Repository',
              href: 'https://github.com/homelab-user/home-lab',
            },
            {
              label: 'Issues & Support',
              href: 'https://github.com/homelab-user/home-lab/issues',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Home Lab Project. Infrastructure as Code & Automation.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
