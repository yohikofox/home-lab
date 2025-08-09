import React from "react";
import { useColorMode } from "@docusaurus/theme-common";
import { Button } from "../../../components/ui/button";
import { Sun, Moon } from "lucide-react";

// 🎨 Simple Toggle: Light ↔ Dark (default: System)
export default function ColorModeToggle() {
  const { colorMode, setColorMode } = useColorMode();

  const handleToggle = () => {
    // Cycle: light → dark → light
    if (colorMode === "light") {
      setColorMode("dark");
    } else {
      setColorMode("light");
    }
  };

  return (
    <Button 
      variant="ghost" 
      size="icon" 
      onClick={handleToggle}
      className="h-10 w-10"
      aria-label={colorMode === "light" ? "Switch to dark mode" : "Switch to light mode"}
    >
      {colorMode === "light" ? (
        <Sun className="h-4 w-4 transition-all duration-300" />
      ) : (
        <Moon className="h-4 w-4 transition-all duration-300" />
      )}
    </Button>
  );
}