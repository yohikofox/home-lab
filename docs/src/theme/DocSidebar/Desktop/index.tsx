import React, { useState } from "react";
import { translate } from "@docusaurus/Translate";
import Link from "@docusaurus/Link";
import {
  PropSidebarItem,
  useCurrentSidebarCategory,
} from "@docusaurus/theme-common";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import { Button } from "@/components/ui/button";
import { ChevronRight, ChevronDown, FileText, Folder } from "lucide-react";
import type { Props } from "@theme/DocSidebar/Desktop";

// 🎯 DocSidebar Desktop avec ShadcnUI
export default function DocSidebarDesktop({
  path,
  sidebar,
  onCollapse,
  isHidden,
}: Props) {
  if (isHidden) {
    return null;
  }

  return (
    <aside className="w-64 h-[calc(100vh-4rem)] bg-card border-r border-border sticky top-16">
      <div className="p-4">
        <h2 className="font-semibold text-foreground mb-4">
          {translate({
            id: "sidebar.docs.title",
            message: "Documentation",
            description: "The title of the sidebar",
          })}
        </h2>
      </div>

      <ScrollArea className="h-[calc(100vh-8rem)]">
        <nav className="px-4 pb-4">
          <div className="space-y-1">
            {sidebar.map((item, index) => (
              <SidebarItem key={index} item={item} activePath={path} />
            ))}
          </div>
        </nav>
      </ScrollArea>
    </aside>
  );
}

// Composant pour chaque item de la sidebar
function SidebarItem({
  item,
  activePath,
}: {
  item: PropSidebarItem;
  activePath: string;
}) {
  const [isOpen, setIsOpen] = useState(false);

  if (item.type === "link") {
    const isActive = activePath === item.href;

    return (
      <Link
        href={item.href}
        className={`
          flex items-center gap-2 px-3 py-2 text-sm rounded-md transition-colors
          ${
            isActive
              ? "bg-primary text-primary-foreground font-medium"
              : "text-muted-foreground hover:text-foreground hover:bg-accent"
          }
        `}
      >
        <FileText className="h-4 w-4" />
        {item.label}
      </Link>
    );
  }

  if (item.type === "category") {
    return (
      <Collapsible open={isOpen} onOpenChange={setIsOpen}>
        <CollapsibleTrigger asChild>
          <Button
            variant="ghost"
            className="w-full justify-start px-3 py-2 h-auto text-sm font-medium text-foreground hover:bg-accent relative"
          >
            {/* Chevron en position absolue */}
            <span className="absolute left-[-5px] top-1/2 -translate-y-1/2">
              {isOpen ? (
                <ChevronDown className="h-4 w-4" />
              ) : (
                <ChevronRight className="h-4 w-4" />
              )}
            </span>
            {/* Contenu aligné avec les documents - même padding que les links */}
            <div className="flex items-center gap-2">
              <Folder className="h-4 w-4" />
              {item.label}
            </div>
          </Button>
        </CollapsibleTrigger>

        <CollapsibleContent className="ml-4 space-y-1">
          {item.items.map((subItem, subIndex) => (
            <SidebarItem
              key={subIndex}
              item={subItem}
              activePath={activePath}
            />
          ))}
        </CollapsibleContent>
      </Collapsible>
    );
  }

  return null;
}
