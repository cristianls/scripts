# Slugs Românești Optimizate

Un plugin WordPress profesional pentru generarea automată de URL-uri curate în limba română, eliminând diacriticele și cuvintele de legătură pentru o optimizare SEO superioară.

## Descriere

Acest plugin transformă automat titlurile articolelor românești în slug-uri URL curate și optimizate SEO prin:
- Eliminarea diacriticelor românești (ă, â, î, ș, ț) și internaționale
- Înlăturarea cuvintelor de legătură (stop words) organizate pe categorii
- Curățarea caracterelor speciale, simbolurilor și spațiilor
- Limitarea lungimii slug-ului pentru best practices SEO
- Generarea de URL-uri consistente și prietene cu motoarele de căutare

## Inspirație și Îmbunătățiri

Acest plugin este dezvoltat după o idee preluată de la **RO Slugs** (Vali Petcu & Friends), dar aduce îmbunătățiri semnificative prin restructurare completă în PHP modern:

**Plugin original:**
- **Nume**: RO Slugs  
- **Autor**: Vali Petcu & Friends
- **URI Plugin**: http://www.zoso.ro/ro-slugs-plugin/
- **Descriere originală**: "Converteşte diacriticele în litere latine ca să nu se mai buşească slugurile"
- **Versiune**: 2.1

### Îmbunătățiri majore față de RO Slugs original:

#### 🏗️ **Arhitectură Modernă**
- **Original**: Script procedural simplu
- **Îmbunătățit**: Arhitectură OOP cu pattern Singleton
- **Beneficii**: Cod mai curat, mai ușor de întreținut și extensibil
- **Organizare**: Separarea datelor (constante) de logică (metode)
- **Cache**: Sistem de cache pentru performanță optimă

#### 🔤 **Transliterare Extinsă și Organizată**
- **Original**: Transformare de bază a diacriticelor
- **Îmbunătățit**: Mapare completă organizată pe categorii:
  ```php
  // Caractere românești
  ă/â/Â/Ă → a, î/Î → i, ș/ş/Ș/Ş → s, ț/ţ/Ț/Ţ → t
  
  // Caractere internaționale
  à/á/å/ä → a, è/é/ê/ë → e, ì/í/î/ï → i
  
  // Simboluri și caractere speciale
  & → si, @ → at, % → procent, + → plus
  ```

#### 📝 **Gestionarea Avansată a Caracterelor Speciale**
- **Nou**: Transformarea automată a semnelor de punctuație:
  - Ghilimele: `"`, `"`, `'`, `„`, `»` → `-`
  - Cratimă lungă: `–`, `—` → `-`
  - Puncte de suspensie: `…` → `-`
  - Entități HTML: `&lsquo;`, `&rsquo;`, `&ldquo;`, `&rdquo;` → `-`

#### 🚫 **Lista Extinsă și Organizată de Stop Words**
- **Original**: Listă limitată de cuvinte de legătură
- **Îmbunătățit**: **200+ stop words românești organizate pe categorii**:
  ```php
  // Articole și pronume: a, al, ale, ea, ei, el, o, un, unei...
  // Prepoziții: cu, de, din, în, pe, prin, pentru, despre...
  // Conjuncții: și, ca, dar, ori, sau, iar, ci, deci...
  // Adverbe frecvente: aici, acolo, foarte, mai, mult...
  // Verbe auxiliare: am, este, sunt, fi, fie, fiind...
  // Numere: doi, trei, patru, cinci, zece, suta...
  ```

#### 🛡️ **Protecție Inteligentă și Fallback**
- **Nou**: Sistem de fallback inteligent:
  - Pentru articole: `articol-[ID]`
  - Pentru pagini: `pagina-[ID]`
  - Verificare lungimea minimă (2 caractere)
- **Îmbunătățire**: Truncare inteligentă cu păstrarea cuvintelor întregi
- **Siguranță**: Validări multiple pentru edge cases

#### 🔧 **Optimizări Tehnice Avansate**
- **Arhitectură**: Pattern Singleton cu lazy loading
- **Performance**: Cache pentru stop words și harta de transliterare
- **Flexibilitate**: Sistem complet de filtre WordPress pentru customizări
- **Securitate**: Validări extinse și protecții pentru toate tipurile de input
- **Limitare lungime**: SEO best practices (60 caractere implicit)
- **Compatibilitate**: Suport pentru WooCommerce și custom post types

#### 🎯 **Funcționalități Noi**
- **Filtre pentru dezvoltatori**:
  ```php
  // Permite skip pentru anumite posturi
  add_filter('sro_skip_optimization', '__return_true');
  
  // Modifică tipurile de post permise
  add_filter('sro_allowed_post_types', function($types) {
      return array_merge($types, ['custom_type']);
  });
  
  // Personalizează stop words
  add_filter('sro_stop_words', function($words) {
      return array_merge($words, ['cuvant_custom']);
  });
  
  // Modifică lungimea maximă
  add_filter('sro_max_slug_length', function() { return 80; });
  ```

- **Protecția articolelor publicate**: Nu modifică slug-urile articolelor deja publicate
- **Suport multilingv**: Text domain pentru traduceri
- **Hooks de activare/dezactivare**: Pentru instalare și curățare automată

## Instalare

### Ca Mu-Plugin (Recomandat pentru dezvoltatori)
1. Copiază fișierul `slugs-romanesti-optimizate.php` în directorul `/wp-content/mu-plugins/`
2. Dacă directorul `mu-plugins` nu există, creează-l
3. Plugin-ul se va activa automat și nu poate fi dezactivat din interfața WordPress

### Ca Plugin Clasic
1. Încarcă folderul plugin-ului în `/wp-content/plugins/`
2. Activează plugin-ul din panoul de administrare WordPress → Plugins

## Funcționare

Plugin-ul funcționează automat și transparent:
- Se declanșează **doar** la crearea de articole noi sau ciorne
- **Nu modifică** articolele deja publicate (protecție pentru SEO)
- **Nu interferează** cu încărcarea fișierelor media sau alte funcționalități
- Funcționează pentru: `post`, `page`, `product` (WooCommerce)

### Exemple de Transformări

| Titlu Original | Slug Generat |
|---|---|
| "Această este o poveste foarte frumoasă și captivantă" | `poveste-frumoasa-captivanta` |
| "Cum să faci bani pe internet în România în 2024?" | `cum-faci-bani-internet-romania-2024` |
| "10 sfaturi pentru începători – ghid complet și detaliat" | `10-sfaturi-incepatori-ghid-complet-detaliat` |
| "Mâncarea tradițională românească: rețete și secrete" | `mancarea-traditionala-romaneasca-retete-secrete` |
| "Un articol cu doar cuvinte de legătură și care să fie" | `articol-456` |
| "Pagină de contact pentru afacerea ta online" | `contact-afacerea-online` |
| "Produsul nostru cel mai bun din această categorie specială" | `produsul-cel-bun-categorie-speciala` |

## Funcționalități Cheie

### ✅ **Funcționalități de bază**
- Eliminare automată diacritice românești și internaționale
- 200+ stop words românești organizate pe categorii
- Gestionare completă caractere speciale și simboluri
- Curățare cratimele multiple și spații
- Fallback cu ID unic pentru slug-uri goale

### ✅ **Funcționalități avansate**
- Limitarea lungimii slug-ului (60 caractere implicit, configurabil)
- Truncare inteligentă cu păstrarea cuvintelor întregi
- Protecția articolelor publicate (nu modifică URL-uri existente)
- Cache pentru performanță optimă
- Sistem complet de filtre pentru customizări

### ✅ **Dezvoltatori**
- Arhitectură OOP cu pattern Singleton
- Text domain pentru traduceri (`slugs-romanesti-optimizate`)
- Filtre WordPress pentru toate aspectele configurabile
- Hooks de activare/dezactivare
- Compatibil cu toate temele și plugin-urile WordPress

### ✅ **SEO și Performance**
- URL-uri curate și consistente
- Lungime optimă pentru motoarele de căutare
- Fără interfață de configurare - funcționează automat
- Impact zero asupra performanței site-ului
- Cache și lazy loading pentru eficiență maximă

## Compatibilitate

- **WordPress**: 5.0+ (testat până la 6.4)
- **PHP**: 7.4+ (modern PHP cu suport pentru constante de clasă)
- **Compatibil cu**: 
  - Gutenberg și Classic Editor
  - WooCommerce (suport pentru produse)
  - Toate temele WordPress
  - Custom Post Types (configurabil prin filtru)
  - Multisite WordPress

## Configurare pentru Dezvoltatori

### Exemple de customizări comune:

```php
// Adaugă custom post type
add_filter('sro_allowed_post_types', function($types) {
    $types[] = 'evenimente';
    $types[] = 'portofoliu';
    return $types;
});

// Modifică lungimea maximă pentru site-uri cu URL-uri lungi
add_filter('sro_max_slug_length', function() {
    return 100; // în loc de 60 implicit
});

// Adaugă stop words specifice domeniului
add_filter('sro_stop_words', function($words) {
    $custom_words = ['blog', 'site', 'web', 'online'];
    return array_merge($words, $custom_words);
});

// Skip optimizarea pentru anumite categorii
add_filter('sro_skip_optimization', function($skip, $post_id, $post) {
    if (has_category('special', $post)) {
        return true;
    }
    return $skip;
}, 10, 3);
```

## Autor

**Cristian Sucila**  
Website: [https://clsb.net](https://clsb.net)

*Dezvoltat cu experiență în WordPress development și best practices moderne*

## Licență

Acest plugin este disponibil sub licența GPL v2 sau ulterioară, menținând compatibilitatea cu ecosystemul WordPress.

## Contribuții

Contribuțiile sunt binevenite! Pentru bug-uri, sugestii sau îmbunătățiri:
- Deschide un issue pentru raportarea problemelor
- Trimite un pull request pentru îmbunătățiri
- Testează pe diverse configurații WordPress

## Changelog

### v1.4 - Arhitectură Modernă
- **🏗️ Restructurare completă**: Arhitectură OOP cu pattern Singleton
- **📊 Organizare date**: Stop words și transliterare ca constante de clasă  
- **⚡ Performance**: Sistem de cache pentru operațiuni repetitive
- **🛡️ Protecții**: Validări extinse și gestionare edge cases
- **🔧 Flexibilitate**: Sistem complet de filtre WordPress
- **📏 SEO**: Limitarea lungimii slug-ului cu truncare inteligentă
- **🎯 Specificitate**: Eliminat hook-ul `sanitize_title` pentru a evita interferențe
- **🌐 Internationalization**: Text domain și suport pentru traduceri
- **📦 WooCommerce**: Suport nativ pentru produse

### v1.3 - Îmbunătățiri Majore
- Îmbunătățiri față de ideea originală RO Slugs
- Lista extinsă de stop words organizate pe categorii (200+)
- Gestionare avansată caractere speciale și simboluri
- Fallback inteligent cu ID unic (`articol-[ID]`, `pagina-[ID]`)
- Procesare directă din titlul original pentru rezultate precise
- Semnătură completă de funcție cu toți parametrii hook-ului
- Optimizări de performance și robustețe

---

**Mulțumiri**: Vali Petcu & Friends pentru ideea originală din plugin-ul RO Slugs

*Dezvoltat cu ❤️ pentru comunitatea WordPress românească*

---

## Suport și Documentație

Pentru întrebări tehnice sau suport:
1. Consultă documentația WordPress despre [Custom Slugs](https://developer.wordpress.org/reference/functions/wp_unique_post_slug/)
2. Verifică [filtrer-le disponibile](#configurare-pentru-dezvoltatori) pentru customizări
3. Testează pe un environment de dezvoltare înainte de producție

**Plugin testat și optimizat pentru performanță maximă în producție** ✨