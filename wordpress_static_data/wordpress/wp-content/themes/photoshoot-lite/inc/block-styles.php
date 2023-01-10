<?php
/**
 * Block Styles
 *
 * @link https://developer.wordpress.org/reference/functions/register_block_style/
 *
 */

if ( function_exists( 'register_block_style' ) ) {
	/**
	 * Register block styles.
	 *
	 * @since Photoshoot Lite 1.0
	 *
	 * @return void
	 */
	function photoshoot_lite_register_block_styles() {
		// Columns: Overlap.
		register_block_style(
			'core/columns',
			array(
				'name'  => 'photoshoot-lite-columns-overlap',
				'label' => esc_html__( 'Overlap', 'photoshoot-lite' ),
			)
		);

		// Cover: Borders.
		register_block_style(
			'core/cover',
			array(
				'name'  => 'photoshoot-lite-border',
				'label' => esc_html__( 'Borders', 'photoshoot-lite' ),
			)
		);

		// Group: Borders.
		register_block_style(
			'core/group',
			array(
				'name'  => 'photoshoot-lite-border',
				'label' => esc_html__( 'Borders', 'photoshoot-lite' ),
			)
		);

		// Image: Borders.
		register_block_style(
			'core/image',
			array(
				'name'  => 'photoshoot-lite-border',
				'label' => esc_html__( 'Borders', 'photoshoot-lite' ),
			)
		);

		// Image: Frame.
		register_block_style(
			'core/image',
			array(
				'name'  => 'photoshoot-lite-image-frame',
				'label' => esc_html__( 'Frame', 'photoshoot-lite' ),
			)
		);

		// Latest Posts: Dividers.
		register_block_style(
			'core/latest-posts',
			array(
				'name'  => 'photoshoot-lite-latest-posts-dividers',
				'label' => esc_html__( 'Dividers', 'photoshoot-lite' ),
			)
		);

		// Latest Posts: Borders.
		register_block_style(
			'core/latest-posts',
			array(
				'name'  => 'photoshoot-lite-latest-posts-borders',
				'label' => esc_html__( 'Borders', 'photoshoot-lite' ),
			)
		);

		// Media & Text: Borders.
		register_block_style(
			'core/media-text',
			array(
				'name'  => 'photoshoot-lite-border',
				'label' => esc_html__( 'Borders', 'photoshoot-lite' ),
			)
		);

		// Separator: Thick.
		register_block_style(
			'core/separator',
			array(
				'name'  => 'photoshoot-lite-separator-thick',
				'label' => esc_html__( 'Thick', 'photoshoot-lite' ),
			)
		);

		// Social icons: Dark gray color.
		register_block_style(
			'core/social-links',
			array(
				'name'  => 'photoshoot-lite-social-icons-color',
				'label' => esc_html__( 'Dark gray', 'photoshoot-lite' ),
			)
		);
	}
	add_action( 'init', 'photoshoot_lite_register_block_styles' );
}
