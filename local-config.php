<?php
/**
 * Configure the tachyon plugin URL.
 */

$tachyon_scheme = isset( $_SERVER['HTTPS'] ) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';

defined( 'TACHYON_URL' ) or define( 'TACHYON_URL', $tachyon_scheme . '://' . $_SERVER['HTTP_HOST'] . '/tchyn/uploads' );
