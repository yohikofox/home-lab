/**
 * HomeLab Pro - Enhanced JavaScript Functionality
 * Version: 1.0.0
 * Provides advanced interactions and animations for technical documentation
 */

document.addEventListener('DOMContentLoaded', function() {
  
  // ==========================================
  // CODE BLOCK ENHANCEMENTS
  // ==========================================
  
  // Add copy buttons to code blocks
  function addCopyButtons() {
    const codeBlocks = document.querySelectorAll('pre code');
    codeBlocks.forEach(block => {
      const pre = block.parentElement;
      if (pre && !pre.querySelector('.copy-button')) {
        const button = document.createElement('button');
        button.className = 'copy-button';
        button.innerHTML = '📋 Copy';
        button.title = 'Copy code to clipboard';
        
        button.addEventListener('click', async () => {
          try {
            await navigator.clipboard.writeText(block.textContent);
            button.innerHTML = '✅ Copied!';
            button.style.color = 'var(--homelab-success)';
            
            setTimeout(() => {
              button.innerHTML = '📋 Copy';
              button.style.color = '';
            }, 2000);
          } catch (err) {
            console.error('Failed to copy code: ', err);
            button.innerHTML = '❌ Failed';
            setTimeout(() => {
              button.innerHTML = '📋 Copy';
            }, 2000);
          }
        });
        
        pre.style.position = 'relative';
        pre.appendChild(button);
      }
    });
  }
  
  // ==========================================
  // MERMAID DIAGRAM ENHANCEMENTS
  // ==========================================
  
  function enhanceMermaidDiagrams() {
    const mermaidElements = document.querySelectorAll('.mermaid');
    mermaidElements.forEach(element => {
      // Add zoom functionality
      element.style.cursor = 'pointer';
      element.title = 'Click to zoom';
      
      element.addEventListener('click', function() {
        this.classList.toggle('mermaid-zoomed');
        if (this.classList.contains('mermaid-zoomed')) {
          this.style.transform = 'scale(1.2)';
          this.style.zIndex = '1000';
          this.style.position = 'relative';
          this.style.background = 'var(--homelab-surface-1)';
          this.style.borderRadius = 'var(--ifm-border-radius-lg)';
        } else {
          this.style.transform = '';
          this.style.zIndex = '';
          this.style.position = '';
        }
      });
    });
  }
  
  // ==========================================
  // TABLE ENHANCEMENTS
  // ==========================================
  
  function enhanceTables() {
    const tables = document.querySelectorAll('table');
    tables.forEach(table => {
      // Add responsive wrapper
      if (!table.parentElement.classList.contains('table-responsive')) {
        const wrapper = document.createElement('div');
        wrapper.className = 'table-responsive';
        table.parentNode.insertBefore(wrapper, table);
        wrapper.appendChild(table);
      }
      
      // Add sorting functionality to headers
      const headers = table.querySelectorAll('th');
      headers.forEach((header, index) => {
        if (!header.querySelector('.sort-indicator')) {
          header.style.cursor = 'pointer';
          header.innerHTML += '<span class="sort-indicator"> ↕</span>';
          
          header.addEventListener('click', () => {
            sortTableByColumn(table, index);
          });
        }
      });
    });
  }
  
  function sortTableByColumn(table, columnIndex) {
    const tbody = table.querySelector('tbody');
    const rows = Array.from(tbody.querySelectorAll('tr'));
    
    // Determine sort direction
    const currentSort = table.getAttribute('data-sort-column');
    const currentDir = table.getAttribute('data-sort-direction');
    const isAscending = currentSort !== String(columnIndex) || currentDir === 'desc';
    
    // Sort rows
    rows.sort((a, b) => {
      const aText = a.children[columnIndex].textContent.trim();
      const bText = b.children[columnIndex].textContent.trim();
      
      // Try to parse as numbers
      const aNum = parseFloat(aText);
      const bNum = parseFloat(bText);
      
      if (!isNaN(aNum) && !isNaN(bNum)) {
        return isAscending ? aNum - bNum : bNum - aNum;
      }
      
      return isAscending ? aText.localeCompare(bText) : bText.localeCompare(aText);
    });
    
    // Update DOM
    rows.forEach(row => tbody.appendChild(row));
    
    // Update sort indicators
    table.querySelectorAll('.sort-indicator').forEach(indicator => {
      indicator.textContent = ' ↕';
    });
    
    const activeHeader = table.querySelectorAll('th')[columnIndex];
    const indicator = activeHeader.querySelector('.sort-indicator');
    indicator.textContent = isAscending ? ' ↑' : ' ↓';
    
    // Store sort state
    table.setAttribute('data-sort-column', columnIndex);
    table.setAttribute('data-sort-direction', isAscending ? 'asc' : 'desc');
  }
  
  // ==========================================
  // SEARCH ENHANCEMENTS
  // ==========================================
  
  function addQuickSearch() {
    // Add keyboard shortcut for search (Ctrl+K or Cmd+K)
    document.addEventListener('keydown', function(e) {
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        const searchInput = document.querySelector('.navbar__search-input, [role="searchbox"]');
        if (searchInput) {
          searchInput.focus();
        }
      }
    });
  }
  
  // ==========================================
  // ACCESSIBILITY ENHANCEMENTS
  // ==========================================
  
  function enhanceAccessibility() {
    // Add skip navigation link
    if (!document.querySelector('.skip-nav')) {
      const skipNav = document.createElement('a');
      skipNav.href = '#main';
      skipNav.className = 'skip-nav';
      skipNav.textContent = 'Skip to main content';
      skipNav.style.cssText = `
        position: absolute;
        left: -9999px;
        z-index: 999999;
        padding: 8px 16px;
        background: var(--homelab-cyan);
        color: var(--homelab-dark-primary);
        text-decoration: none;
        border-radius: 4px;
      `;
      
      skipNav.addEventListener('focus', function() {
        this.style.left = '8px';
        this.style.top = '8px';
      });
      
      skipNav.addEventListener('blur', function() {
        this.style.left = '-9999px';
      });
      
      document.body.insertBefore(skipNav, document.body.firstChild);
    }
  }
  
  // ==========================================
  // THEME PERSISTENCE
  // ==========================================
  
  function initThemePersistence() {
    // Ensure dark mode preference is maintained
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
      document.documentElement.setAttribute('data-theme', savedTheme);
    }
    
    // Listen for theme changes
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === 'data-theme') {
          const theme = document.documentElement.getAttribute('data-theme');
          localStorage.setItem('theme', theme);
        }
      });
    });
    
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-theme']
    });
  }
  
  // ==========================================
  // INITIALIZE ALL ENHANCEMENTS
  // ==========================================
  
  // Initialize all enhancements
  addCopyButtons();
  enhanceTables();
  addQuickSearch();
  enhanceAccessibility();
  initThemePersistence();
  
  // Initialize Mermaid enhancements after a short delay
  setTimeout(() => {
    enhanceMermaidDiagrams();
  }, 1000);
  
  // Re-run enhancements when navigating in SPA
  let lastUrl = location.href;
  new MutationObserver(() => {
    const url = location.href;
    if (url !== lastUrl) {
      lastUrl = url;
      setTimeout(() => {
        addCopyButtons();
        enhanceTables();
        enhanceMermaidDiagrams();
      }, 500);
    }
  }).observe(document, { subtree: true, childList: true });
  
  console.log('🚀 HomeLab Pro enhancements loaded successfully!');
});

// ==========================================
// CSS INJECTION FOR ENHANCEMENTS
// ==========================================

const enhancementStyles = `
  /* Copy button styles */
  .copy-button {
    position: absolute;
    top: 12px;
    right: 12px;
    background: var(--homelab-surface-glass-strong);
    border: 1px solid var(--homelab-surface-glass);
    color: var(--homelab-text-tertiary);
    font-size: 0.75rem;
    padding: 6px 10px;
    border-radius: 6px;
    cursor: pointer;
    transition: var(--homelab-transition-fast);
    backdrop-filter: blur(10px);
    z-index: 10;
    opacity: 0;
    visibility: hidden;
  }
  
  pre:hover .copy-button {
    opacity: 1;
    visibility: visible;
  }
  
  .copy-button:hover {
    background: var(--homelab-cyan);
    color: var(--homelab-dark-primary);
    border-color: var(--homelab-cyan);
  }
  
  /* Table responsive wrapper */
  .table-responsive {
    overflow-x: auto;
    border-radius: var(--ifm-border-radius);
    box-shadow: var(--homelab-shadow-sm);
  }
  
  /* Sort indicators */
  .sort-indicator {
    color: var(--homelab-text-tertiary);
    font-size: 0.8em;
    margin-left: 4px;
  }
  
  /* Mermaid zoom styles */
  .mermaid-zoomed {
    transition: transform var(--homelab-transition-slow);
  }
`;

// Inject styles
const styleSheet = document.createElement('style');
styleSheet.textContent = enhancementStyles;
document.head.appendChild(styleSheet);