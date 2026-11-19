/// Bundled preview assets for the built-in prompt libraries (Halloween and
/// Christmas).
///
/// Keep prompt copy and asset locations separate. Keys match `PromptItem.id`.
class PromptPreviewAssets {
  PromptPreviewAssets._();

  static const Map<String, String> halloween = {
    // Text-to-image prompts.
    'pumpkin_king': 'assets/images/haloween/text-to-image/pumpkin_king.png',
    'moonlit_witch': 'assets/images/haloween/text-to-image/moonlit_witch.png',
    'vampire_noble': 'assets/images/haloween/text-to-image/crimson_vampire.png',
    'friendly_ghost':
        'assets/images/haloween/text-to-image/friendly_ghosty.jpg',
    'skeleton_musician':
        'assets/images/haloween/text-to-image/skeleton_musician.jpg',
    'werewolf_howl': 'assets/images/haloween/text-to-image/werewolf_howl.jpg',
    'black_cat_familiar': 'assets/images/haloween/text-to-image/blackcat.jpg',
    'jack_o_lantern_still_life':
        'assets/images/haloween/text-to-image/jacko_lantern.jpg',
    'ghost_bride': 'assets/images/haloween/text-to-image/ghost_bride.jpg',
    'raven_queen': 'assets/images/haloween/text-to-image/raven_queen.jpg',

    // Image-to-image prompts.
    'halloween_vampire':
        'assets/images/haloween/image-to-image/vampire_noble.png',
    'halloween_witch':
        'assets/images/haloween/image-to-image/enchantedd_witch.png',
    'halloween_ghost':
        'assets/images/haloween/image-to-image/spectral_ghost.png',
    'halloween_skeleton':
        'assets/images/haloween/image-to-image/skeleton_makeup.png',
    'halloween_werewolf': 'assets/images/haloween/image-to-image/werewolf.png',
    'halloween_royalty':
        'assets/images/haloween/image-to-image/gothic_royal.png',
    'halloween_retro_bedroom':
        'assets/images/haloween/image-to-image/retro_slasher_night.png',
    'halloween_haunted_mansion':
        'assets/images/haloween/image-to-image/haunted_mansion_portrait.png',
    'halloween_pumpkin_patch':
        'assets/images/haloween/image-to-image/golden_pumpkin.png',
    'halloween_gothic_ballroom':
        'assets/images/haloween/image-to-image/gothic_ball.png',
    'halloween_polaroid_party':
        'assets/images/haloween/image-to-image/polaraid_custom_party.png',
    'halloween_mirror_ghost':
        'assets/images/haloween/image-to-image/mirror_ghost.png',
    'halloween_haunted_carnival':
        'assets/images/haloween/image-to-image/haunted_carnival.png',
    'halloween_apothecary_witch':
        'assets/images/haloween/image-to-image/apothercy_witch.png',
    'halloween_liminal_hallway':
        'assets/images/haloween/image-to-image/liminal_hallway.png',
    'halloween_harvest_scarecrow':
        'assets/images/haloween/image-to-image/harvest_scarecrow.png',
    'halloween_fortune_teller':
        'assets/images/haloween/image-to-image/fortune_teller.png',
    'halloween_graveyard_moon':
        'assets/images/haloween/image-to-image/moonlit_graveyard.png',
    'halloween_cursed_library':
        'assets/images/haloween/image-to-image/library.png',
    'halloween_cat_sorcerer':
        'assets/images/haloween/image-to-image/cat_familiar.jpg',
  };

  /// Christmas text-to-image and image-to-image previews.
  static const Map<String, String> christmas = {
    'santa_workshop':
        'assets/images/christmas/text-to-image/santa_workshop.jpg',
    'frost_queen': 'assets/images/christmas/text-to-image/frost_queen.jpg',
    'gingerbread_village':
        'assets/images/christmas/text-to-image/gingerbread_village.jpg',
    'aurora_reindeer': 'assets/images/christmas/text-to-image/reindeer.jpg',
    'elf_toymaker': 'assets/images/christmas/text-to-image/elf.jpg',
    'lantern_snowman':
        'assets/images/christmas/text-to-image/lantern_snowman.jpg',
    'fireside_cat': 'assets/images/christmas/text-to-image/fireside_cat.jpg',
    'winter_market_stall':
        'assets/images/christmas/text-to-image/winter_market.jpg',
    'frost_dragon': 'assets/images/christmas/text-to-image/frost_dragon.jpg',
    'tree_still_life': 'assets/images/christmas/text-to-image/tree_light.jpg',
    // Image-to-image previews.
    'christmas_santa':
        'assets/images/christmas/image-to-image/jolly_santa.jpg',
    'christmas_elf':
        'assets/images/christmas/image-to-image/workshop_elf.jpg',
    'christmas_sweater':
        'assets/images/christmas/image-to-image/cozy_sweater.jpg',
    'christmas_snow_royalty':
        'assets/images/christmas/image-to-image/winter_royalty.jpg',
    'christmas_nutcracker':
        'assets/images/christmas/image-to-image/nutcracker.jpg',
    'christmas_winter_angel':
        'assets/images/christmas/image-to-image/winter_angel.jpg',
    'christmas_fireplace':
        'assets/images/christmas/image-to-image/bythe_fireplace.jpg',
    'christmas_snowy_street':
        'assets/images/christmas/image-to-image/snowy_village_walk.jpg',
    'christmas_retro_card':
        'assets/images/christmas/image-to-image/vintage_christmas_card.jpg',
    'christmas_woodland':
        'assets/images/christmas/image-to-image/woodland_wanderer.jpg',
    'christmas_cabin_window':
        'assets/images/christmas/image-to-image/cabin_window.jpg',
    'christmas_snow_globe':
        'assets/images/christmas/image-to-image/snow_globe.jpg',
    'christmas_sweater_party':
        'assets/images/christmas/image-to-image/sweater_flash.jpg',
    'christmas_gingerbread_baker':
        'assets/images/christmas/image-to-image/gingerbread_baker.jpg',
    'christmas_ice_queen':
        'assets/images/christmas/image-to-image/ice_queen.jpg',
    'christmas_skating_rink':
        'assets/images/christmas/image-to-image/skater.jpg',
    'christmas_sleigh_ride':
        'assets/images/christmas/image-to-image/sleigh_ride.jpg',
    'christmas_tree_farm':
        'assets/images/christmas/image-to-image/tree_Farm.jpg',
    'christmas_morning_pajamas':
        'assets/images/christmas/image-to-image/christmas_morning.jpg',
    'christmas_carolers':
        'assets/images/christmas/image-to-image/carolers.jpg',
  };

  static String? forPrompt(String promptId) =>
      halloween[promptId] ?? christmas[promptId];
}
