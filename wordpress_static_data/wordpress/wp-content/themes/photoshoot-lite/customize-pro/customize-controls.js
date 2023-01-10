( function( api ) {

	// Extends our custom "photoshoot-lite" section.
	api.sectionConstructor['photoshoot-lite'] = api.Section.extend( {

		// No events for this type of section.
		attachEvents: function () {},

		// Always make the section active.
		isContextuallyActive: function () {
			return true;
		}
	} );

} )( wp.customize );