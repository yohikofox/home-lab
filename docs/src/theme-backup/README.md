# 📦 Theme Components Backup

Ce dossier contient les composants Docusaurus originaux exportés via swizzle.

## 🗂️ Structure

### `/original-swizzled/`
Sauvegarde complète des composants swizzlés avec Docusaurus avant modifications ShadcnUI.

#### Composants sauvegardés :

**Navbar** (swizzled --danger):
- `Navbar/index.tsx` - Composant principal modifié avec ShadcnUI
- `Navbar/Layout/` - Layout original Docusaurus
- `Navbar/Content/` - Contenu original
- `Navbar/Logo/` - Logo original
- `Navbar/ColorModeToggle/` - Toggle original
- `Navbar/Search/` - Recherche originale 
- `Navbar/MobileSidebar/` - Sidebar mobile original complet

**DocSidebar** (swizzled):
- `DocSidebar/index.tsx` - Sidebar modifié avec ShadcnUI ScrollArea
- `DocSidebar/Desktop/` - Version desktop originale
- `DocSidebar/Mobile/` - Version mobile originale

**Footer** (swizzled):
- `Footer/index.tsx` - Footer modifié avec ShadcnUI
- `Footer/Layout/` - Layout original
- `Footer/Links/` - Liens originaux
- `Footer/Logo/` - Logo original
- `Footer/Copyright/` - Copyright original

## 🔄 Utilisation

Ces composants peuvent être restaurés en cas de besoin :
```bash
# Restaurer un composant spécifique
cp src/theme-backup/original-swizzled/Navbar/Layout/index.tsx src/theme/Navbar/Layout/

# Restaurer tout
rm -rf src/theme && cp -r src/theme-backup/original-swizzled src/theme
```

## ⚠️ Important

- Ne pas supprimer ce dossier
- Ces composants sont les versions Docusaurus natives avant transformation ShadcnUI
- Référence pour comprendre les fonctionnalités Docusaurus originales