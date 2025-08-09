import React, { useState } from "react";
import { translate } from "@docusaurus/Translate";
import Link from "@docusaurus/Link";
import { 
  PropSidebarItem, 
  NavbarSecondaryMenuFiller,
  type NavbarSecondaryMenuComponent 
} from "@docusaurus/theme-common";
import { useNavbarMobileSidebar } from "@docusaurus/theme-common/internal";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible";
import { Button } from "@/components/ui/button";
import { ChevronRight, ChevronDown, FileText, Folder } from "lucide-react";
import type { Props } from "@theme/DocSidebar/Mobile";

// 📱 DocSidebar Mobile intégré dans le menu hamburger avec ShadcnUI
const DocSidebarMobileSecondaryMenu: NavbarSecondaryMenuComponent<Props> = ({
  sidebar,
  path,
}) => {
  const mobileSidebar = useNavbarMobileSidebar();

  return (
    <div className="p-4">
      <h3 className="font-semibold text-foreground mb-4">
        {translate({
          id: "sidebar.docs.title",
          message: "Documentation",
          description: "The title of the mobile sidebar"
        })}
      </h3>
      
      <ScrollArea className="h-[calc(100vh-12rem)]">
        <div className="space-y-1">
          {sidebar.map((item, index) => (
            <SidebarItem
              key={index}
              item={item}
              activePath={path}
              onItemClick={(item) => {
                // Fermer le menu mobile si c'est un lien ou une catégorie avec href
                if (item.type === 'link' || (item.type === 'category' && item.href)) {
                  mobileSidebar.toggle();
                }
              }}
            />
          ))}
        </div>
      </ScrollArea>
    </div>
  );
};

export default function DocSidebarMobile(props: Props) {
  return (
    <NavbarSecondaryMenuFiller
      component={DocSidebarMobileSecondaryMenu}
      props={props}
    />
  );
}

// Composant pour chaque item de la sidebar mobile
function SidebarItem({ 
  item, 
  activePath,
  onItemClick
}: { 
  item: PropSidebarItem;
  activePath: string;
  onItemClick: (item: PropSidebarItem) => void;
}) {
  const [isOpen, setIsOpen] = useState(true);

  if (item.type === "link") {
    const isActive = activePath === item.href;
    
    return (
      <Link
        href={item.href}
        className={`
          flex items-center gap-2 px-3 py-2 text-sm rounded-md transition-colors
          ${isActive 
            ? 'bg-primary text-primary-foreground font-medium' 
            : 'text-muted-foreground hover:text-foreground hover:bg-accent'
          }
        `}
        onClick={() => onItemClick(item)}
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
            className="w-full justify-start gap-2 px-3 py-2 h-auto text-sm font-medium text-foreground hover:bg-accent"
            onClick={() => {
              // Si la catégorie a un href, appeler onItemClick
              if (item.href) {
                onItemClick(item);
              }
            }}
          >
            {isOpen ? (
              <ChevronDown className="h-4 w-4" />
            ) : (
              <ChevronRight className="h-4 w-4" />
            )}
            <Folder className="h-4 w-4" />
            {item.label}
          </Button>
        </CollapsibleTrigger>
        
        <CollapsibleContent className="ml-4 space-y-1">
          {item.items.map((subItem, subIndex) => (
            <SidebarItem
              key={subIndex}
              item={subItem}
              activePath={activePath}
              onItemClick={onItemClick}
            />
          ))}
        </CollapsibleContent>
      </Collapsible>
    );
  }

  return null;
}