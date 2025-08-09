import React from "react";
import { useThemeConfig } from "@docusaurus/theme-common";
import Link from "@docusaurus/Link";
import useBaseUrl from "@docusaurus/useBaseUrl";

// 🎯 Footer avec ShadcnUI - Mobile First
export default function Footer() {
  const { footer } = useThemeConfig();

  if (!footer) {
    return null;
  }

  const { copyright, links, logo } = footer;

  return (
    <footer className="border-t bg-background text-foreground py-8">
      <div className="mx-auto max-w-7xl px-4">
        {/* Links Grid - Mobile: 1 column centered, Desktop: 3+ columns */}
        {links && links.length > 0 && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-8 md:justify-items-center">
            {links.map((linkColumn, i) => (
              <div key={i} className="text-center md:text-left">
                <h3 className="font-semibold text-foreground mb-4 text-base">
                  {linkColumn.title}
                </h3>
                <ul className="space-y-2">
                  {linkColumn.items.map((item, j) => (
                    <li key={j}>
                      {item.to ? (
                        <Link
                          to={item.to}
                          className="text-sm text-muted-foreground hover:text-foreground transition-colors"
                        >
                          {item.label}
                        </Link>
                      ) : (
                        <a
                          href={item.href}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-sm text-muted-foreground hover:text-foreground transition-colors"
                        >
                          {item.label}
                        </a>
                      )}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        )}

        {/* Bottom Section: Logo + Copyright */}
        <div className="pt-8 border-t border-border">
          <div className="flex flex-col md:flex-row md:items-center md:justify-center">
            {/* Logo */}
            {logo && (
              <div className="flex items-center mb-4 md:mb-0">
                <img
                  src={useBaseUrl(logo.src)}
                  alt={logo.alt}
                  className="h-8 w-auto mr-3"
                />
                {logo.alt && (
                  <span className="font-semibold text-foreground">
                    {logo.alt}
                  </span>
                )}
              </div>
            )}

            {/* Copyright */}
            {copyright && (
              <div className="text-sm text-muted-foreground">
                <div dangerouslySetInnerHTML={{ __html: copyright }} />
              </div>
            )}
          </div>
        </div>
      </div>
    </footer>
  );
}
