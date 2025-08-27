<?php
/**
 * Plugin Name:       Slugs Românești Optimizate
 * Description:       Transformă titlurile articolelor în slug-uri curate, eliminând diacriticele românești și cuvintele de legătură.
 * Version:           1.2
 * Author:            Cristian Sucila
 * Author URI:        https://clsb.net
 */

// Nu permite accesul direct la fișier.
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Filtrează slug-ul (URL-ul) la salvarea unui articol pentru a-l optimiza.
 *
 * @param string $slug        Slug-ul curent generat de WordPress.
 * @param int    $post_ID     ID-ul postului editat.
 * @param string $post_status Status-ul postului.
 * @param string $post_type   Tipul de post.
 * @param int    $post_parent ID-ul părintelui postului.
 * @return string             Slug-ul modificat.
 */
// MODIFICAREA 2: Schimbăm semnătura funcției pentru a accepta noii parametri.
function ro_slugs_optimizer( $slug, $post_ID, $post_status, $post_type, $post_parent ) {

    // Folosim titlul original al postului pentru a genera slug-ul.
    $title = get_the_title( $post_ID );
    
    // Dacă titlul este gol, nu avem ce procesa.
    if ( empty( $title ) ) {
        return 'articol-' . $post_ID;
    }
    
    $slug = $title;

    // 1. Transliterează caracterele specifice românești și alte simboluri.
    $map = array(
        '/à|á|å|â|ă|Â|Ă/i' => 'a',
        '/è|é|ê|ẽ|ë/i'    => 'e',
        '/ì|í|î|Î/i'      => 'i',
        '/ò|ó|ô|ø/i'      => 'o',
        '/ù|ú|ů|û/i'      => 'u',
        '/ș|ş|Ș|Ş/i'      => 's',
        '/ț|ţ|Ț|Ţ/i'      => 't',
        '/”|“|…|’|„|»|–|&lsquo;|&rsquo;|&ldquo;|&rdquo;/' => '-',
    );
    $slug = preg_replace( array_keys( $map ), array_values( $map ), $slug );

    // 2. Converteste totul la litere mici.
    $slug = strtolower( $slug );

    // 3. Înlocuiește orice caracter care NU este literă sau cifră cu o cratimă.
    $slug = preg_replace( '/[^a-z0-9]+/', '-', $slug );
    
    // 4. Elimină cuvintele de legătură (stop words).
    $stop_words = array(
        'a', 'acea', 'aceasta', 'acest', 'acesta', 'aceste', 'acestea', 'acestia',
        'acolo', 'acum', 'ai', 'aia', 'aici', 'al', 'ale', 'alea', 'alt', 'alta',
        'altceva', 'alti', 'alte', 'altul', 'altii', 'am', 'aproape', 'as', 'asa',
        'asta', 'astea', 'astia', 'asupra', 'ati', 'atunci', 'au', 'avea', 'avem',
        'aveti', 'azi', 'ca', 'cam', 'cand', 'care', 'carora', 'caruia', 'cat',
        'catre', 'ce', 'cea', 'cel', 'cele', 'ceilalti', 'ceva', 'chiar', 'ci',
        'cinci', 'cine', 'cineva', 'contra', 'cu', 'cum', 'cumva', 'da', 'daca',
        'dar', 'dat', 'datorita', 'de', 'deci', 'deja', 'deoarece', 'despre',
        'desi', 'din', 'dintr', 'dintre', 'doi', 'doilea', 'doua', 'drept',
        'dupa', 'e', 'ea', 'ei', 'el', 'ele', 'eram', 'este', 'esti', 'eu', 'face',
        'fara', 'fata', 'fi', 'fie', 'fiecare', 'fiind', 'fiu', 'foarte', 'fost',
        'iar', 'ieri', 'ii', 'il', 'imi', 'in', 'inainte', 'inapoi', 'inca',
        'incat', 'intre', 'insa', 'isi', 'iti', 'la', 'langa', 'le', 'li', 'lor',
        'lui', 'ma', 'mai', 'mare', 'mi', 'mie', 'mine', 'mult', 'multa', 'multi',
        'ne', 'ni', 'nic', 'nici', 'nimeni', 'niste', 'noastre', 'noastra',
        'nostri', 'nostru', 'nou', 'noua', 'noi', 'nu', 'o', 'opt', 'ori', 'or',
        'oricare', 'orice', 'oricum', 'patra', 'patru', 'pe', 'pentru', 'peste',
        'pic', 'pana', 'prea', 'prin', 'printr', 'putin', 'putina', 'quot', 'sa',
        'sai', 'sale', 'sapte', 'sase', 'sau', 'se', 'si', 'spre', 'sub', 'sunt',
        'suntem', 'sunteti', 'suta', 'ta', 'tale', 'tau', 'te', 'ti', 'tie', 'tine',
        'toata', 'toate', 'tot', 'toti', 'totul', 'totusi', 'trei', 'treia',
        'tu', 'un', 'una', 'unde', 'unei', 'unele', 'unii', 'unor', 'unul', 'va',
        'vi', 'voastre', 'voastra', 'vostri', 'vostru', 'vou', 'voua', 'vreo',
        'vreun', 'zece'
    );
    
    $slug_array = explode( '-', $slug );
    $slug_array = array_diff( $slug_array, $stop_words );
    $slug = implode( '-', $slug_array );

    // 5. Curăță cratimele multiple și cele de la începutul sau sfârșitul slug-ului.
    $slug = trim( preg_replace( '/-+/', '-', $slug ), '-' );

    // MODIFICAREA 3: Folosim noul fallback dacă slug-ul a rămas gol.
    if ( empty( $slug ) ) {
        return 'articol-' . $post_ID;
    }

    return $slug;
}

// MODIFICAREA 1: Schimbăm ultimul număr din 2 în 5 pentru a primi toți parametrii.
add_filter( 'wp_unique_post_slug', 'ro_slugs_optimizer', 10, 5 );