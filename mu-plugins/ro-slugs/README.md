# Slugs Românești Optimizate

Un mu-plugin WordPress pentru generarea automată de URL-uri curate în limba română, eliminând diacriticele și cuvintele de legătură pentru o optimizare SEO superioară.

## Descriere

Acest plugin transformă automat titlurile articolelor românești în slug-uri URL curate și optimizate SEO prin:
- Eliminarea diacriticelor românești (ă, â, î, ș, ț)
- Înlăturarea cuvintelor de legătură (stop words)
- Curățarea caracterelor speciale și a spațiilor
- Generarea de URL-uri consistente și prietene cu motoarele de căutare

## Inspirație și Îmbunătățiri

Acest plugin este dezvoltat după o idee preluată de la **RO Slugs** (Vali Petcu & Friends), dar aduce îmbunătățiri semnificative:

**Plugin original:**
- **Nume**: RO Slugs  
- **Autor**: Vali Petcu & Friends
- **URI Plugin**: http://www.zoso.ro/ro-slugs-plugin/
- **Descriere originală**: "Converteşte diacriticele în litere latine ca să nu se mai buşească slugurile"
- **Versiune**: 2.1

### Îmbunătățiri față de RO Slugs original:

#### 🔤 **Transliterare Extinsă**
- **Original**: Transformare de bază a diacriticelor
- **Îmbunătățit**: Mapare completă pentru toate variantele de diacritice românești și internaționale:
  - `ă/â/Ă/Â` → `a`
  - `î/Î` → `i` 
  - `ș/ş/Ș/Ş` → `s`
  - `ț/ţ/Ț/Ţ` → `t`
  - Suport pentru caractere cu accent din alte limbi (à, á, è, é, etc.)

#### 📝 **Gestionarea Caracterelor Speciale**
- **Nou**: Transformarea automată a semnelor de punctuație și ghilimelelor în cratimă:
  - Ghilimele: `"`, `"`, `'`, `„`, `»`
  - Cratimă lungă: `–`
  - Puncte de suspensie: `…`
  - Entități HTML: `&lsquo;`, `&rsquo;`, `&ldquo;`, `&rdquo;`

#### 🚫 **Lista Extinsă de Stop Words**
- **Original**: Listă limitată de cuvinte de legătură
- **Îmbunătățit**: **Lista completă de 200+ stop words românești**, incluzând:
  - Articole: `a`, `al`, `ale`, `cea`, `cel`, `cele`, `un`, `una`, `unei`
  - Pronume: `eu`, `tu`, `el`, `ea`, `noi`, `voi`, `ei`, `ele`, `mine`, `tine`
  - Prepoziții: `în`, `pe`, `cu`, `la`, `din`, `pentru`, `despre`, `către`
  - Conjuncții: `și`, `sau`, `dar`, `că`, `dacă`, `deși`, `deoarece`
  - Adverbe: `foarte`, `mai`, `cum`, `când`, `unde`, `aici`, `acolo`
  - Verbe auxiliare: `este`, `sunt`, `era`, `eram`, `fi`, `fiind`

#### 🛡️ **Protecție Avansată Împotriva Slug-urilor Goale**
- **Nou**: Fallback inteligent la `'articol-[ID]'` când slug-ul devine gol după eliminarea stop words
- **Îmbunătățire**: Include ID-ul postului pentru unicitate garantată (ex: `articol-123`)
- **Beneficiu**: Previne erorile și asigură URL-uri unice chiar și pentru titluri compuse doar din stop words

#### 🔧 **Optimizări Tehnice**
- **Cod Curat**: Structură modulară și comentarii detaliate
- **Performance**: Procesare eficientă cu regex optimizate
- **Compatibilitate**: Hook WordPress standard (`wp_unique_post_slug`) cu toate parametrii
- **Robustețe**: Folosește titlul original al postului în loc de slug-ul pre-procesat
- **Siguranță**: Gestionare completă a parametrilor hook-ului WordPress

## Instalare

### Ca Mu-Plugin (Recomandat)
1. Copiază fișierul `ro-slugs-optimizate.php` în directorul `/wp-content/mu-plugins/`
2. Dacă directorul `mu-plugins` nu există, creează-l
3. Plugin-ul se va activa automat

### Ca Plugin Clasic
1. Încarcă folderul plugin-ului în `/wp-content/plugins/`
2. Activează plugin-ul din panoul de administrare WordPress

## Funcționare

Plugin-ul funcționează automat la salvarea articolelor. Nu necesită configurări suplimentare.

### Exemple de Transformări

| Titlu Original | Slug Generat |
|---|---|
| "Această este o poveste frumoasă" | `poveste-frumoasa` |
| "Cum să faci bani pe internet în România?" | `cum-faci-bani-internet-romania` |
| "10 sfaturi pentru începători – ghid complet" | `10-sfaturi-incepatori-ghid-complet` |
| "Mâncarea tradițională românească" | `mancarea-traditionala-romaneasca` |
| "Un articol cu multe și care să fie foarte" | `articol-456` (fallback cu ID) |

## Funcționalități Cheie

- ✅ **Eliminare automată diacritice românești**
- ✅ **200+ stop words românești**
- ✅ **Gestionare caractere speciale**
- ✅ **Curățare cratimele multiple**
- ✅ **Fallback cu ID unic pentru slug-uri goale**
- ✅ **Compatibil cu toate temele WordPress**
- ✅ **Fără interfață de configurare - funcționează automat**
- ✅ **Optimizat pentru performance**

## Compatibilitate

- **WordPress**: 4.0+
- **PHP**: 5.6+
- **Compatibil cu**: Gutenberg, Classic Editor, toate temele WordPress

## Autor

**Cristian Sucila**  
Website: [https://clsb.net](https://clsb.net)

## Licență

Acest plugin este disponibil sub licența GPL v2 sau ulterioară, menținând compatibilitatea cu ecosystemul WordPress.

**Atribuire**: Dezvoltat după ideea din plugin-ul original **RO Slugs** de Vali Petcu & Friends, cu îmbunătățiri semnificative și funcționalități extinse.

## Contribuții

Contribuțiile sunt binevenite! Pentru bug-uri, sugestii sau îmbunătățiri, te rugăm să deschizi un issue sau să trimiți un pull request.

## Changelog

### v1.2
- Îmbunătățiri majore față de ideea originală
- Lista extinsă de stop words (200+)
- Gestionare avansată caractere speciale
- **Fallback inteligent cu ID unic** (`articol-[ID]`)
- **Procesare directă din titlul original** pentru rezultate mai precise
- **Semnătură completă de funcție** cu toți parametrii hook-ului WordPress
- Optimizări de performance și robustețe

---

**Mulțumiri**: Vali Petcu & Friends pentru ideea originală din plugin-ul RO Slugs  
*Dezvoltat cu ❤️ pentru comunitatea WordPress românească*