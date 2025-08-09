# 🎨 Theme Components - Structure Minimale

Composants Docusaurus remplacés par des versions ShadcnUI minimales.

## 📁 Structure Actuelle

### ✅ Composants Actifs

**`Navbar/index.tsx`** - Navbar minimale
- Header sticky avec logo placeholder
- Structure de base pour ajouts progressifs

**`DocSidebar/index.tsx`** - Sidebar minimale  
- Affichage basique de la sidebar
- À étendre avec navigation réelle

**`Footer/index.tsx`** - Footer minimal
- Copyright simple
- Structure de base

## 🗂️ Dossiers Conservés

La structure complète des dossiers Docusaurus est préservée pour ajouts futurs :

```
theme/
├── Navbar/
│   ├── ColorModeToggle/     # 🔄 À recréer
│   ├── Content/             # 🔄 À recréer  
│   ├── Layout/              # 🔄 À recréer
│   ├── Logo/                # 🔄 À recréer
│   ├── MobileSidebar/       # 🔄 À recréer
│   │   ├── Header/
│   │   ├── Layout/
│   │   ├── PrimaryMenu/
│   │   ├── SecondaryMenu/
│   │   └── Toggle/
│   ├── Search/              # 🔄 À recréer
│   └── index.tsx            # ✅ Actif
├── DocSidebar/
│   ├── Desktop/             # 🔄 À recréer
│   ├── Mobile/              # 🔄 À recréer  
│   └── index.tsx            # ✅ Actif
└── Footer/
    ├── Copyright/           # 🔄 À recréer
    ├── Layout/              # 🔄 À recréer
    ├── LinkItem/            # 🔄 À recréer
    ├── Links/               # 🔄 À recréer
    ├── Logo/                # 🔄 À recréer
    └── index.tsx            # ✅ Actif
```

## 🚀 Prochaines Étapes

1. **Logo/ColorMode** - Intégrer hooks Docusaurus
2. **Navigation** - Lire config `navbar.items`
3. **Mobile Menu** - Sheet ShadcnUI
4. **DocSidebar** - Navigation docs réelle
5. **Footer** - Liens depuis config

## 📦 Sauvegarde

Composants originaux disponibles dans `/src/theme-backup/original-swizzled/`