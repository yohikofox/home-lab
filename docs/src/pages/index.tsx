import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/intro">
            📖 Découvrir l'architecture
          </Link>
          <Link
            className="button button--outline button--lg"
            to="/docs/INSTALLATION">
            🚀 Guide d'installation
          </Link>
        </div>
      </div>
    </header>
  );
}

function TechStackSection() {
  return (
    <section className={styles.techStack}>
      <div className="container">
        <div className="row">
          <div className="col col--6">
            <h2>🐳 Stack Docker (PC Lenovo)</h2>
            <ul>
              <li><strong>Vaultwarden</strong> - Gestionnaire de mots de passe</li>
              <li><strong>Zitadel</strong> - Authentification centralisée SSO</li>
              <li><strong>N8N</strong> - Automation et workflows</li>
              <li><strong>Nginx Proxy Manager</strong> - Reverse proxy + SSL</li>
              <li><strong>PiHole</strong> - DNS + Blocage publicitaire</li>
              <li><strong>Portainer</strong> - Management Docker</li>
            </ul>
          </div>
          <div className="col col--6">
            <h2>🍓 Stack Domotique (Raspberry Pi 4)</h2>
            <ul>
              <li><strong>Home Assistant OS</strong> - Hub domotique central</li>
              <li><strong>Zigbee2MQTT</strong> - Passerelle protocoles IoT</li>
              <li><strong>Frigate</strong> - Analyse vidéo avec IA</li>
              <li><strong>Mosquitto MQTT</strong> - Broker messages IoT</li>
              <li><strong>Add-ons HA</strong> - Terminal, File Editor, etc.</li>
            </ul>
          </div>
        </div>
      </div>
    </section>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`Accueil - ${siteConfig.title}`}
      description="Documentation complète d'un home lab moderne avec Docker, Home Assistant, automatisation N8N et stratégies de disaster recovery. Architecture PC Lenovo + Raspberry Pi 4.">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
        <TechStackSection />
      </main>
    </Layout>
  );
}
