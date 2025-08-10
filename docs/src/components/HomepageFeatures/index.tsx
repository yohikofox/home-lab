import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<'svg'>>;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: '🏗️ Architecture Modulaire',
    Svg: require('@site/static/img/architecture_modular.svg').default,
    description: (
      <>
        Infrastructure répartie sur PC Lenovo (services Docker) et Raspberry Pi 4 (domotique).
        Séparation des préoccupations pour une maintenance optimisée.
      </>
    ),
  },
  {
    title: '🔄 Automatisation Complète',
    Svg: require('@site/static/img/automation_complete.svg').default,
    description: (
      <>
        Workflows N8N pour disaster recovery, monitoring 24/7, et sauvegardes automatiques.
        Notifications Telegram en temps réel.
      </>
    ),
  },
  {
    title: '🔒 Sécurité Intégrée',
    Svg: require('@site/static/img/security_integrated.svg').default,
    description: (
      <>
        SSL Let's Encrypt automatique, authentification centralisée Zitadel,
        et stratégies de sauvegarde robustes.
      </>
    ),
  },
];

function Feature({title, Svg, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
