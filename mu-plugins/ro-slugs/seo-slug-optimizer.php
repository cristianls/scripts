<?php
/**
 * Plugin Name:       Slugs Românești Optimizate
 * Description:       Transformă titlurile articolelor în slug-uri curate, eliminând diacriticele românești și cuvintele de legătură. Rulează doar înainte de publicare.
 * Version:           1.7 (Fix Complet)
 * Author:            Cristian Sucila (Optimizat)
 * Author URI:        https://clsb.net
 * Text Domain:       slugs-romanesti-optimizate
 * Domain Path:       /languages
 * Requires at least: 5.0
 * Tested up to:      6.4
 * Requires PHP:      7.4
 * License:           GPL v2 or later
 * License URI:       https://www.gnu.org/licenses/gpl-2.0.html
 */

// Previne accesul direct la fișier
if (!defined('ABSPATH')) {
    exit;
}

// Definiește constante pentru plugin
define('SRO_PLUGIN_VERSION', '1.7');
define('SRO_PLUGIN_FILE', __FILE__);
define('SRO_PLUGIN_DIR', plugin_dir_path(__FILE__));
define('SRO_PLUGIN_URL', plugin_dir_url(__FILE__));

/**
 * Clasa principală pentru gestionarea slug-urilor românești
 */
class RomanianSlugsOptimizer {
    
    /**
     * Lista de stop words românești
     */
    private const DEFAULT_STOP_WORDS = [
        // Articole și pronume (inclusiv scurte)
        'a', 'al', 'ale', 'ea', 'ei', 'el', 'ele', 'ii', 'il', 'la', 'le', 'lui', 'o', 'un', 'une', 'unui', 'unei',
        'am', 'ai', 'ma', 'mi', 'te', 'ti', 'va', 'vi', 'ne', 'va', 'imi', 'iti', 'isi',
        
        // Prepoziții
        'cu', 'de', 'din', 'dintre', 'fara', 'in', 'pe', 'prin', 'sub', 'asupra', 'catre', 'contra', 'dupa',
        'inainte', 'inapoi', 'langa', 'pana', 'peste', 'spre', 'printr', 'intre',
        
        // Conjuncții
        'si', 'ca', 'dar', 'ori', 'sau', 'iar', 'ci', 'deci', 'insa', 'totusi', 'pentru',
        
        // Adverbe frecvente
        'aici', 'acolo', 'acum', 'azi', 'ieri', 'cam', 'chiar', 'cum', 'cumva', 'deja', 'foarte', 'mai',
        'mult', 'prea', 'putin', 'tot', 'unde',
        
        // Verbe auxiliare și de legătură
        'are', 'avem', 'aveti', 'au', 'eram', 'este', 'esti', 'sunt', 'suntem', 'sunteti',
        'fi', 'fie', 'fiind', 'fost', 'sa', 'se',
        
        // Numere și cantități
        'doi', 'doua', 'trei', 'patru', 'cinci', 'sase', 'sapte', 'opt', 'noua', 'zece', 'suta',
        
        // Pronume și adjective demonstrative
        'acest', 'acesta', 'aceasta', 'aceste', 'acestea', 'acestia', 'acea', 'asta', 'astea', 'astia',
        'cel', 'cea', 'cei', 'cele', 'care', 'ce', 'cine',
        
        // Cuvinte scurte suplimentare (sub 3 caractere care nu sunt importante)
        'm', 'l', 's', 't', 'n', 'as', 'ar', 'e', 'i', 'da', 'nu'
    ];
    
    /**
     * Harta de transliterare pentru caractere speciale
     */
    private const DEFAULT_TRANSLITERATION_MAP = [
        // Caractere românești - TOATE variantele
        '/[ăĂ]/u' => 'a',
        '/[âÂ]/u' => 'a',
        '/[îÎ]/u' => 'i',
        '/[șşŞȘ]/u' => 's',
        '/[țţŢȚ]/u' => 't',
        
        // Alte caractere cu diacritice
        '/[àáåä]/u' => 'a',
        '/[èéêë]/u' => 'e',
        '/[ìíîï]/u' => 'i',
        '/[òóôöø]/u' => 'o',
        '/[ùúûü]/u' => 'u',
        '/[ñ]/u' => 'n',
        '/[ç]/u' => 'c',
    ];
    
    /**
     * Instanța singleton
     */
    private static $instance = null;
    
    /**
     * Cache pentru stop words
     */
    private static $stop_words_cache = null;
    
    /**
     * Cache pentru harta de transliterare
     */
    private static $transliteration_map_cache = null;
    
    /**
     * Obține instanța singleton
     */
    public static function get_instance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * Constructor privat pentru pattern singleton
     */
    private function __construct() {
        $this->init_hooks();
    }
    
    /**
     * Inițializează hook-urile WordPress
     */
    private function init_hooks() {
        // Hook principal pentru generarea slug-ului
        add_filter('wp_insert_post_data', [$this, 'filter_post_data_before_save'], 10, 2);
        add_action('plugins_loaded', [$this, 'load_textdomain']);
    }
    
    /**
     * Încarcă traducerile plugin-ului
     */
    public function load_textdomain() {
        load_plugin_textdomain(
            'slugs-romanesti-optimizate',
            false,
            dirname(plugin_basename(__FILE__)) . '/languages'
        );
    }
    
    /**
     * Filtrează datele postului înainte de salvare pentru a optimiza slug-ul
     *
     * @param array $data    Array cu datele postului
     * @param array $postarr Array cu datele originale din request
     * @return array         Datele modificate
     */
    public function filter_post_data_before_save($data, $postarr) {
        // Verifică dacă este un tip de post valid pentru optimizare
        if (!$this->should_optimize_post_type($data['post_type'])) {
            return $data;
        }
        
        // Nu modifica slug-ul dacă articolul este deja publicat
        if (isset($postarr['ID'])) {
            $existing_post = get_post($postarr['ID']);
            if ($existing_post && in_array($existing_post->post_status, ['publish', 'private'], true)) {
                return $data;
            }
        }
        
        // Permite dezvoltatorilor să dezactiveze optimizarea
        if (apply_filters('sro_skip_optimization', false, $postarr['ID'] ?? 0, $data)) {
            return $data;
        }
        
        // Dacă nu avem titlu, nu procesăm
        if (empty($data['post_title'])) {
            return $data;
        }
        
        // Generează slug-ul optimizat
        $optimized_slug = $this->process_slug($data['post_title'], $postarr['ID'] ?? 0);
        
        // Dacă avem un slug valid, îl setăm
        if (!empty($optimized_slug)) {
            $data['post_name'] = $optimized_slug;
        }
        
        return $data;
    }
    
    /**
     * Verifică dacă tipul de post trebuie optimizat
     *
     * @param string $post_type Tipul de post
     * @return bool
     */
    private function should_optimize_post_type($post_type) {
        $allowed_types = apply_filters('sro_allowed_post_types', [
            'post',
            'page',
            'product' // pentru WooCommerce
        ]);
        
        return in_array($post_type, $allowed_types, true);
    }
    
    /**
     * Procesează și optimizează slug-ul
     *
     * @param string $title   Titlul original
     * @param int    $post_ID ID-ul postului
     * @return string
     */
    private function process_slug($title, $post_ID) {
        $slug = $title;
        
        // 1. Aplică transliterarea caracterelor speciale
        $slug = $this->transliterate_text($slug);
        
        // 2. Elimină toate caracterele speciale și le înlocuiește cu spații
        $slug = preg_replace('/[^a-z0-9\s]/ui', ' ', $slug);
        
        // 3. Convertește la minuscule
        $slug = mb_strtolower($slug, 'UTF-8');
        
        // 4. Înlocuiește spațiile multiple cu un singur spațiu
        $slug = preg_replace('/\s+/', ' ', trim($slug));
        
        // 5. Transformă spațiile în cratimă
        $slug = str_replace(' ', '-', $slug);
        
        // 6. Elimină stop words și cuvinte scurte
        $slug = $this->remove_stop_words($slug);
        
        // 7. Curăță și finalizează slug-ul
        $slug = $this->clean_slug($slug);
        
        // 8. Verifică dacă slug-ul este valid
        if (empty($slug) || strlen($slug) < 2) {
            return $this->generate_fallback_slug($post_ID, get_post_type($post_ID) ?: 'post');
        }
        
        // 9. Limitează lungimea slug-ului (SEO best practice)
        $max_length = apply_filters('sro_max_slug_length', 60);
        if (strlen($slug) > $max_length) {
            $slug = $this->truncate_slug($slug, $max_length);
        }
        
        return $slug;
    }
    
    /**
     * Transliterează textul folosind o hartă optimizată
     *
     * @param string $text Textul de transliterat
     * @return string
     */
    private function transliterate_text($text) {
        if (self::$transliteration_map_cache === null) {
            self::$transliteration_map_cache = $this->get_transliteration_map();
        }
        
        return preg_replace(
            array_keys(self::$transliteration_map_cache),
            array_values(self::$transliteration_map_cache),
            $text
        );
    }
    
    /**
     * Obține harta de transliterare
     *
     * @return array
     */
    private function get_transliteration_map() {
        return apply_filters('sro_transliteration_map', self::DEFAULT_TRANSLITERATION_MAP);
    }
    
    /**
     * Elimină cuvintele de legătură și cuvinte scurte din slug
     *
     * @param string $slug Slug-ul de procesat
     * @return string
     */
    private function remove_stop_words($slug) {
        if (self::$stop_words_cache === null) {
            self::$stop_words_cache = $this->get_stop_words();
        }
        
        $words = explode('-', $slug);
        $filtered_words = [];
        
        $min_word_length = apply_filters('sro_min_word_length', 4);
        
        foreach ($words as $word) {
            $word = trim($word);
            
            // Elimină cuvintele goale
            if (empty($word)) {
                continue;
            }
            
            // Elimină stop words (verificare exactă)
            if (in_array($word, self::$stop_words_cache, true)) {
                continue;
            }
            
            // Elimină cuvinte prea scurte (sub 4 caractere implicit)
            if (strlen($word) < $min_word_length) {
                continue;
            }
            
            $filtered_words[] = $word;
        }
        
        // Dacă nu a rămas niciun cuvânt, păstrează primele cuvinte mai lungi
        if (empty($filtered_words) && !empty($words)) {
            // Încearcă să găsești cel puțin un cuvânt de lungime decentă
            foreach ($words as $word) {
                $word = trim($word);
                if (strlen($word) >= 3 && !in_array($word, self::$stop_words_cache, true)) {
                    $filtered_words[] = $word;
                    if (count($filtered_words) >= 3) {
                        break;
                    }
                }
            }
            
            // Dacă tot nu avem nimic, ia primele 3 cuvinte non-empty
            if (empty($filtered_words)) {
                $filtered_words = array_filter(array_slice($words, 0, 3), function($w) {
                    return !empty(trim($w));
                });
            }
        }
        
        return implode('-', $filtered_words);
    }
    
    /**
     * Obține lista de stop words românești
     *
     * @return array
     */
    private function get_stop_words() {
        return apply_filters('sro_stop_words', self::DEFAULT_STOP_WORDS);
    }
    
    /**
     * Curăță și finalizează slug-ul
     *
     * @param string $slug Slug-ul de curățat
     * @return string
     */
    private function clean_slug($slug) {
        // Elimină cratimele multiple și cele de la capete
        $slug = preg_replace('/-+/', '-', $slug);
        $slug = trim($slug, '-');
        
        return $slug;
    }
    
    /**
     * Trunchiază slug-ul la o lungime maximă păstrând cuvintele întregi
     *
     * @param string $slug       Slug-ul original
     * @param int    $max_length Lungimea maximă
     * @return string
     */
    private function truncate_slug($slug, $max_length) {
        if (strlen($slug) <= $max_length) {
            return $slug;
        }
        
        $words = explode('-', $slug);
        $truncated = '';
        
        foreach ($words as $word) {
            if (strlen($truncated . '-' . $word) > $max_length) {
                break;
            }
            $truncated = empty($truncated) ? $word : $truncated . '-' . $word;
        }
        
        return $truncated ?: substr($slug, 0, $max_length);
    }
    
    /**
     * Generează un slug de rezervă
     *
     * @param int    $post_ID   ID-ul postului
     * @param string $post_type Tipul postului
     * @return string
     */
    private function generate_fallback_slug($post_ID, $post_type) {
        $prefix = ($post_type === 'page') ? 'pagina' : 'articol';
        return $prefix . '-' . $post_ID;
    }
}

/**
 * Inițializează plugin-ul
 */
function sro_init() {
    RomanianSlugsOptimizer::get_instance();
}

// Înregistrează hook-ul de inițializare
add_action('init', 'sro_init');

/**
 * Hook pentru activarea plugin-ului
 */
register_activation_hook(__FILE__, function() {
    // Setează versiunea plugin-ului în baza de date
    update_option('sro_plugin_version', SRO_PLUGIN_VERSION);
});

/**
 * Hook pentru dezactivarea plugin-ului
 */
register_deactivation_hook(__FILE__, function() {
    // Curăță cache-ul dacă este necesar
    wp_cache_flush();
});