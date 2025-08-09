import React, { type ReactNode } from "react";
import Link from "@docusaurus/Link";
import useBaseUrl from "@docusaurus/useBaseUrl";
import { translate } from "@docusaurus/Translate";
import IconHome from "@theme/Icon/Home";

export default function HomeBreadcrumbItem(): ReactNode {
  const homeHref = useBaseUrl("/");

  return (
    <Link
      aria-label={translate({
        id: "theme.docs.breadcrumbs.home",
        message: "Home page",
        description: "The ARIA label for the home page in the breadcrumbs",
      })}
      className="flex items-center text-muted-foreground hover:text-foreground transition-colors"
      href={homeHref}
    >
      <IconHome className="w-4 h-4" />
    </Link>
  );
}
