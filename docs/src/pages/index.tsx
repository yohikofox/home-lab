import type { ReactNode } from "react";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import { Button } from "@/components/ui/button";
import {
  Server,
  Network,
  Shield,
  Zap,
  Code2,
  BookOpen,
  ArrowRight,
  Github,
  Play,
} from "lucide-react";

// 🎯 Hero Zone avec présentation du projet
function HeroSection() {
  const { siteConfig } = useDocusaurusContext();

  return (
    <section className="relative bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 text-white py-20 md:py-32">
      <div
        className="absolute inset-0 opacity-50"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23334155' fill-opacity='0.1'%3E%3Ccircle cx='30' cy='30' r='2'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
        }}
      ></div>

      <div className="relative mx-auto max-w-7xl px-4">
        <div className="text-center">
          {/* Badge */}
          <div className="inline-flex items-center rounded-full border border-slate-700 bg-slate-800/50 px-4 py-2 text-sm font-medium text-slate-300 mb-8">
            <Zap className="mr-2 h-4 w-4" />
            Infrastructure as Code & Automation
          </div>

          {/* Title */}
          <h1 className="text-4xl md:text-6xl font-bold bg-gradient-to-r from-white to-slate-300 bg-clip-text text-transparent mb-6">
            {siteConfig.title}
          </h1>

          {/* Subtitle */}
          <p className="text-xl md:text-2xl text-slate-300 mb-8 max-w-3xl mx-auto leading-relaxed">
            {siteConfig.tagline}
          </p>

          {/* Description */}
          <p className="text-lg text-slate-400 mb-12 max-w-2xl mx-auto">
            Une documentation complète pour construire et maintenir un home lab
            moderne avec des technologies cloud-native, de l'automatisation et
            des meilleures pratiques DevOps.
          </p>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <Button
              asChild
              size="lg"
              className="bg-blue-600 hover:bg-blue-700 text-white"
            >
              <Link to="/docs/intro">
                <BookOpen className="mr-2 h-5 w-5" />
                Commencer la documentation
                <ArrowRight className="ml-2 h-4 w-4" />
              </Link>
            </Button>

            <Button
              asChild
              variant="outline"
              size="lg"
              className="border-slate-600 text-slate-500 hover:bg-slate-800 hover:text-slate-300"
            >
              <Link to="/docs/INSTALLATION">
                <Play className="mr-2 h-5 w-5" />
                Guide d'installation
              </Link>
            </Button>
          </div>
        </div>
      </div>
    </section>
  );
}

// 🎯 Sections explicatives avec features
function FeaturesSection() {
  const features = [
    {
      icon: <Server className="h-8 w-8 text-blue-500" />,
      title: "Infrastructure Moderne",
      description:
        "Docker, Kubernetes, et orchestration de services avec les dernières technologies cloud-native.",
    },
    {
      icon: <Network className="h-8 w-8 text-green-500" />,
      title: "Réseau Sécurisé",
      description:
        "Topologie réseau avancée avec VLANs, firewalls, et segmentation pour un environnement sécurisé.",
    },
    {
      icon: <Code2 className="h-8 w-8 text-purple-500" />,
      title: "Infrastructure as Code",
      description:
        "Terraform, Ansible et GitOps pour une infrastructure reproductible et versionée.",
    },
    {
      icon: <Shield className="h-8 w-8 text-red-500" />,
      title: "Sécurité Intégrée",
      description:
        "Bonnes pratiques de sécurité, monitoring, et compliance pour un environnement robuste.",
    },
  ];

  return (
    <section className="py-20 bg-background">
      <div className="mx-auto max-w-7xl px-4">
        {/* Section Header */}
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-bold text-foreground mb-4">
            Pourquoi ce Home Lab ?
          </h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Une approche méthodique pour construire un laboratoire personnel qui
            reflète les standards de production modernes.
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-16">
          {features.map((feature, index) => (
            <div
              key={index}
              className="border border-border rounded-lg p-6 hover:shadow-lg transition-shadow"
            >
              <div className="flex items-start gap-4">
                <div className="flex-shrink-0">{feature.icon}</div>
                <div>
                  <h3 className="text-xl font-semibold text-foreground mb-2">
                    {feature.title}
                  </h3>
                  <p className="text-muted-foreground">{feature.description}</p>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Architecture Preview */}
        <div className="text-center">
          <h3 className="text-2xl font-bold text-foreground mb-4">
            Architecture Complète
          </h3>
          <p className="text-muted-foreground mb-8 max-w-3xl mx-auto">
            De la planification réseau au déploiement d'applications, découvrez
            une architecture pensée pour l'évolutivité et la maintenabilité.
          </p>

          <Button asChild variant="outline" size="lg">
            <Link to="/docs/ARCHITECTURE">
              Voir l'architecture
              <ArrowRight className="ml-2 h-4 w-4" />
            </Link>
          </Button>
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={`Accueil - ${siteConfig.title}`}
      description="Documentation complète pour un home lab moderne avec Infrastructure as Code, automatisation et bonnes pratiques DevOps"
    >
      <HeroSection />
      <FeaturesSection />
    </Layout>
  );
}
