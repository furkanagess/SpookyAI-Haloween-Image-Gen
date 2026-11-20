import '../../../../core/theme/seasons/season_palette.dart';
import '../../../../core/theme/seasons/season_theme.dart';
import '../models/prompt_category.dart';
import 'christmas_prompts.dart';

class PromptService {
  static const List<PromptCategory> _halloweenCategories = [
    PromptCategory(
      id: "text_to_image",
      name: "Text to Image",
      icon: "🎨",
      description: "Halloween characters and scenes from a short description",
      prompts: [
        PromptItem(
          id: "pumpkin_king",
          title: "Pumpkin King",
          prompt:
              "A pumpkin-headed king on a throne of twisted roots, tattered crimson cape, crown of black iron thorns, carved face glowing from within, in a moonlit pumpkin patch full of glowing jack-o'-lanterns.",
          isPopular: true,
          tagline: "A crown of thorns, a lantern for a scepter.",
          description:
              "A towering king with a glowing carved face rules from a throne of twisted roots. Autumn folklore in a crimson velvet cape.",
          tags: ["pumpkin", "fantasy", "horror"],
          ownsScene: true,
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "moonlit_witch",
          title: "Moonlit Witch",
          prompt:
              "A witch with long silver hair and a pointed hat holding a glowing green potion, midnight-blue robes, a black cat at her feet, on a misty hilltop under a huge full moon.",
          isPopular: true,
          tagline: "She brews by moonlight, the cat supervises.",
          description:
              "A silver-haired witch lifts a glowing green potion, midnight robes stitched with stars and a black cat at her feet.",
          tags: ["witch", "moon", "fantasy"],
          ownsScene: true,
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "vampire_noble",
          title: "Crimson Vampire",
          prompt:
              "A pale aristocratic vampire in a high-collared black velvet coat raising a crystal goblet, faint fangs, in a candle-lit gothic castle hall with arched windows and red drapes.",
          tagline: "Velvet, rings and centuries of charm.",
          description:
              "An aristocrat in a high-collared coat raises a crystal goblet. Pale, elegant and just a little dangerous.",
          tags: ["vampire", "gothic", "nobility"],
          ownsScene: true,
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "friendly_ghost",
          title: "Friendly Ghost",
          prompt:
              "A cute ghost in a flowing white sheet with big round glowing eyes, floating and holding a tiny lantern, in a cozy old attic with wooden beams and a round window at night, warm lantern glow.",
          isPopular: true,
          tagline: "The least scary ghost in the house.",
          description:
              "A round-eyed ghost drifts along with a tiny lantern, trailing soft light. Storybook sweet, never frightening.",
          tags: ["ghosts", "fantasy", "supernatural"],
          ownsScene: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "skeleton_musician",
          title: "Skeleton Musician",
          prompt:
              "A skeleton in a tattered tailcoat and top hat playing the violin with passion, on the wooden stage of a dusty vintage theater, red velvet curtains, a single warm spotlight.",
          tagline: "A dapper skeleton, a violin, no regrets.",
          description:
              "Bones polished like ivory, a tattered tailcoat and a single candle flame floating over the strings, mid-dance.",
          tags: ["skeletons", "horror", "vintage"],
          ownsScene: true,
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "werewolf_howl",
          title: "Werewolf Howl",
          prompt:
              "A werewolf howling with its head thrown back, torn shirt over thick fur, glowing amber eyes, on a rocky ridge above a dark pine forest under a bright full moon, thin mist.",
          tagline: "One howl at the full moon.",
          description:
              "A powerful werewolf with its head thrown back, torn shirt and amber eyes, every strand of fur catching the moonlight.",
          tags: ["horror", "supernatural", "moon"],
          ownsScene: true,
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "black_cat_familiar",
          title: "Black Cat Familiar",
          prompt:
              "A black cat with yellow eyes and a tiny crooked witch hat sitting on an old spellbook, a lit candle and dried herbs beside it, on a wooden desk in a witch's cottage, warm candlelight.",
          isPopular: true,
          tagline: "Small cat, big spellbook.",
          description:
              "A sleek black cat in a crooked witch hat sits on an antique spellbook, with a candle and dried herbs close by.",
          tags: ["witch", "fantasy", "supernatural"],
          ownsScene: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "jack_o_lantern_still_life",
          title: "Jack-o'-Lantern Still Life",
          prompt:
              "Five hand-carved jack-o'-lanterns of different sizes and faces on a rustic wooden table, candles glowing inside, scattered autumn leaves and small gourds, warm light across the table.",
          ownsScene: true,
          tagline: "Five pumpkins, five moods.",
          description:
              "A candlelit table of hand-carved jack-o'-lanterns, scattered leaves and a lace cloth, glowing like an October evening.",
          tags: ["pumpkin", "vintage"],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "ghost_bride",
          title: "Ghost Bride",
          prompt:
              "A ghostly bride in a tattered lace gown and smoky veil holding wilted black roses, sorrowful expression, edges fading into mist, in an overgrown Victorian graveyard at night, stone angels in fog.",
          tagline: "A wedding that never quite ended.",
          description:
              "A veiled bride drifts like smoke, holding black roses. Calm, sorrowful and slowly dissolving into mist.",
          tags: ["ghosts", "gothic", "supernatural"],
          ownsScene: true,
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "raven_queen",
          title: "Raven Queen",
          prompt:
              "A gothic queen in a feathered black gown and a crown of raven feathers, ravens on her outstretched arms, dark lipstick, in a ruined cathedral with broken stained-glass windows, cold dawn light.",
          tagline: "Ravens answer to her.",
          description:
              "A gothic queen in a feathered gown, crowned with raven feathers, with ravens perched on her outstretched arms.",
          tags: ["gothic", "nobility", "fantasy"],
          ownsScene: true,
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
      ],
    ),
    PromptCategory(
      id: "image_to_image",
      name: "Image to Image",
      icon: "📸",
      description: "Turn your photo into a Halloween look",
      prompts: [
        PromptItem(
          id: "halloween_vampire",
          kind: StyleKind.fantasy,
          title: "Vampire Noble",
          prompt:
              "the person as an elegant vampire in a high-collared black velvet coat with red silk lining, pale makeup, subtle fangs, hair swept back, in the candle-lit hall of an old gothic mansion, warm candlelight",
          isPopular: true,
          tagline: "Become the one the night waits for.",
          description:
              "A high-collared velvet coat, subtle fangs and a calm gaze. You, as an elegant vampire who never loses composure.",
          tags: ["vampire", "gothic", "nobility"],
          ownsScene: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_witch",
          kind: StyleKind.fantasy,
          title: "Enchanted Witch",
          prompt:
              "the person as a witch in a wide-brimmed pointed hat and dark embroidered robes, holding a small glowing lantern, in a cozy witch's cottage with a bubbling cauldron and hanging herbs, warm firelight",
          isPopular: true,
          tagline: "Your own spell, your own hat.",
          description:
              "A wide-brimmed hat, silver-embroidered robes and a lantern's glow. You, as a witch who knows exactly what they're doing.",
          tags: ["witch", "fantasy", "moon"],
          ownsScene: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_ghost",
          kind: StyleKind.fantasy,
          title: "Spectral Ghost",
          prompt:
              "the person as a gentle ghost in flowing pale clothing with a soft glow and faint mist around them, serene expression, in the hallway of an old Victorian house, soft moonlight through lace curtains",
          tagline: "Soft glow, solid you.",
          description:
              "Flowing pale clothing, a faint mist at the hem and a quiet ethereal glow. Your face stays clear while the world turns spectral.",
          tags: ["ghosts", "supernatural", "gothic"],
          ownsScene: true,
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_skeleton",
          title: "Skeleton Makeup",
          prompt:
              "the person with elegant skeleton face paint in soft white and charcoal, dark clothing, a marigold behind the ear, in a candle-lit courtyard decorated for Día de Muertos, warm evening light",
          isPopular: true,
          tagline: "Bone structure, but make it art.",
          description:
              "Skeleton makeup that follows your own features, dark tailoring and a marigold behind the ear. Day of the Dead elegance.",
          tags: ["skeletons", "horror", "vintage"],
          ownsScene: true,
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_werewolf",
          kind: StyleKind.fantasy,
          title: "Werewolf",
          prompt:
              "the person as a subtle werewolf with light fur along the jaw, amber eyes, small fangs and a torn flannel shirt, at the edge of a misty pine forest at night under a full moon, cool moonlight",
          tagline: "Just a hint of wolf.",
          description:
              "Light fur along the jaw, amber eyes and a torn flannel shirt. Subtle enough that you're still unmistakably you.",
          tags: ["horror", "supernatural", "moon"],
          ownsScene: true,
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_royalty",
          kind: StyleKind.fantasy,
          title: "Gothic Royalty",
          prompt:
              "the person as gothic royalty in black velvet and lace with a high ruffled collar and a slim jeweled crown, seated in a gothic castle throne room with tall candelabras, warm candlelight",
          tagline: "Black velvet and a slim crown.",
          description:
              "Gothic royalty with a ruffled collar, jewels and a proud, calm pose, as if the castle was always yours.",
          tags: ["nobility", "gothic", "fantasy"],
          ownsScene: true,
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_retro_bedroom",
          title: "Retro Slasher Night",
          prompt:
              "the person lounging on pink satin sheets in a retro 90s teen bedroom, holding a corded phone, movie posters on the wall, a tall shadowy figure out of focus in the doorway, warm lamp light",
          isPopular: true,
          ownsScene: true,
          tagline: "Pink sheets, corded phone, something at the door.",
          description:
              "You on a 90s sleepover bed with popcorn and movie posters, and a shadowy figure out of focus in the doorway.",
          tags: ["retro", "horror", "vintage"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_haunted_mansion",
          kind: StyleKind.fantasy,
          title: "Haunted Mansion Portrait",
          prompt:
              "the person in a Victorian mourning outfit standing at the foot of a grand staircase in a candle-lit mansion, dusty chandelier and cobwebs, faint ghostly figures in the shadows, soft warm candle light on the face",
          ownsScene: true,
          tagline: "Candlelight on a very old staircase.",
          description:
              "You in Victorian mourning at the foot of a grand staircase, dusty chandeliers above and ghosts barely visible in the dark.",
          tags: ["house", "gothic", "ghosts"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_pumpkin_patch",
          title: "Golden Pumpkin Patch",
          prompt:
              "the person in an oversized cozy knit sweater sitting among pumpkins in a golden-hour pumpkin patch, hay bales, light drifting fog, soft warm backlight in their hair",
          isPopular: true,
          ownsScene: true,
          tagline: "Golden hour, big sweater, endless pumpkins.",
          description:
              "A cozy autumn portrait among hay bales and drifting fog, with warm backlight glowing in your hair.",
          tags: ["pumpkin", "party"],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_gothic_ballroom",
          title: "Gothic Masquerade Ball",
          prompt:
              "the person in a black velvet masquerade outfit in a vast candle-lit gothic ballroom, crystal chandeliers, dancing couples softly blurred behind, holding an ornate mask at their side, soft golden candle glow",
          ownsScene: true,
          tagline: "The masquerade starts at midnight.",
          description:
              "Black velvet in a candlelit ballroom, crystal chandeliers overhead and dancers softly blurred behind you.",
          tags: ["nobility", "gothic", "party"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_polaroid_party",
          title: "Polaroid Costume Party",
          prompt:
              "the person at an 80s Halloween costume party in a sequined jacket and a witch hat, tinsel streamers and paper skeletons on the wall behind, a harsh on-camera flash, grainy instant-photo colors",
          ownsScene: true,
          tagline: "Hard flash, soft nostalgia.",
          description:
              "An 80s costume party caught on instant film: sequins, tinsel, paper skeletons and a flash that blows out the background.",
          tags: ["retro", "party", "vintage"],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_mirror_ghost",
          kind: StyleKind.fantasy,
          title: "Mirror Ghost Portrait",
          prompt:
              "the person in Victorian lace and a high collar standing before an antique mirror in candlelight, their reflection a faint pale ghost with a slight smile, sepia tones, dust motes in the air",
          ownsScene: true,
          tagline: "Your reflection knows something.",
          description:
              "Candlelight, lace and an antique mirror where your reflection looks back a little too calmly.",
          tags: ["ghosts", "gothic", "vintage"],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_haunted_carnival",
          title: "Haunted Carnival",
          prompt:
              "the person at a deserted carnival at night, a neon ferris wheel glowing through low fog behind them, striped tents and flickering bulbs, a vintage jacket, soft light on their face",
          ownsScene: true,
          tagline: "The rides still run after closing.",
          description:
              "A neon ferris wheel through the fog, empty striped tents and flickering bulbs. A carnival that never quite closed.",
          tags: ["party", "horror", "retro"],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_apothecary_witch",
          kind: StyleKind.fantasy,
          title: "Apothecary Witch",
          prompt:
              "the person as a cottage witch in an herb-filled apothecary kitchen, bundles of dried herbs hanging overhead, a cauldron steaming beside them, amber lamplight, a linen apron over dark robes",
          ownsScene: true,
          tagline: "Soup, but make it a spell.",
          description:
              "Dried herbs, a steaming cauldron and amber lamps. You as the witch who runs the coziest kitchen in the woods.",
          tags: ["witch", "cozy", "fantasy"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_liminal_hallway",
          title: "Liminal Hallway",
          prompt:
              "the person in a vintage bat-wing cape standing in an endless empty office hallway, flickering fluorescent lights, worn carpet, an uncanny quiet, slightly desaturated colors",
          ownsScene: true,
          tagline: "Somewhere between floors.",
          description:
              "An endless hallway of flickering lights and worn carpet. Unsettling in the quietest way, with you in a bat-wing cape.",
          tags: ["liminal", "horror", "retro"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_harvest_scarecrow",
          title: "Harvest Scarecrow",
          prompt:
              "the person as a friendly scarecrow in a patched plaid shirt and straw hat, small stitched marks on the cheeks, straw tufts at the cuffs, a cornfield glowing at golden hour behind them",
          ownsScene: true,
          tagline: "Stuffed with straw, full of charm.",
          description:
              "A patched shirt, stitched cheeks and straw at the cuffs in a golden cornfield. A scarecrow you would wave back at.",
          tags: ["pumpkin", "fantasy", "kids"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_fortune_teller",
          title: "Fortune Teller",
          prompt:
              "the person as a fortune teller in a velvet tent, layered scarves and gold coin jewelry, a glowing crystal ball between their hands, candles and tarot cards on a draped table, warm flickering light",
          ownsScene: true,
          tagline: "Your future, by candlelight.",
          description:
              "Layered scarves, gold coins and a glowing crystal ball between your hands. The tent where every card means something.",
          tags: ["supernatural", "fantasy", "vintage"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_graveyard_moon",
          title: "Moonlit Graveyard",
          prompt:
              "the person in a long black coat standing among old mossy gravestones under a full moon, low mist around their ankles, a small lantern in hand, cool moonlight with a hint of warm glow",
          ownsScene: true,
          tagline: "A quiet walk, nothing to see here.",
          description:
              "Mossy gravestones, low mist and a lantern held low under a full moon. Calm, cold and just a little too quiet.",
          tags: ["graveyard", "moon", "gothic"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_cursed_library",
          kind: StyleKind.fantasy,
          title: "Cursed Library",
          prompt:
              "the person reading by candlelight in a tall dusty library, floating books and drifting pages around them, a dark academia sweater and scarf, a black cat on the desk, warm amber light",
          ownsScene: true,
          tagline: "Every book is whispering.",
          description:
              "A tall dusty library where the books hover, the pages drift and a black cat guards the desk.",
          tags: ["fantasy", "gothic", "supernatural"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "halloween_cat_sorcerer",
          kind: StyleKind.fantasy,
          title: "Cat Familiar",
          prompt:
              "the person as a young sorcerer in a dark velvet jacket with a silver moon brooch, a black cat on their shoulder, in an old wizard's library with tall bookshelves and floating candles, warm light",
          tagline: "The cat chose you, not the other way.",
          description:
              "A velvet jacket, a silver moon brooch and a black cat on your shoulder. Quietly powerful, and the cat knows it.",
          tags: ["witch", "moon", "fantasy"],
          ownsScene: true,
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
      ],
    ),
  ];

  /// Every season's library, for app-wide counts.
  static List<List<PromptCategory>> get allSeasonLibraries => [
    for (final id in SeasonId.values) _libraryFor(id),
  ];

  /// Exhaustive on purpose: a new [SeasonId] will not compile until it has
  /// its own library (see docs/SEASONS.md).
  static List<PromptCategory> _libraryFor(SeasonId id) => switch (id) {
    SeasonId.halloween => _halloweenCategories,
    SeasonId.christmas => ChristmasPrompts.categories,
  };

  /// The library of the active season.
  static List<PromptCategory> get _promptCategories =>
      _libraryFor(SeasonPalette.current.id);

  static List<PromptCategory> getAllCategories() {
    return _promptCategories;
  }

  static PromptCategory? getCategoryById(String id) {
    try {
      return _promptCategories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<PromptItem> getPopularPrompts() {
    final List<PromptItem> popularPrompts = [];
    for (final category in _promptCategories) {
      popularPrompts.addAll(
        category.prompts.where((prompt) => prompt.isPopular),
      );
    }
    return popularPrompts;
  }

  static List<PromptItem> getTextToImagePrompts() {
    final textToImageCategory = _promptCategories.firstWhere(
      (category) => category.id == 'text_to_image',
    );
    return textToImageCategory.prompts;
  }

  static List<PromptItem> getImageToImagePrompts() {
    final imageToImageCategory = _promptCategories.firstWhere(
      (category) => category.id == 'image_to_image',
    );
    return imageToImageCategory.prompts;
  }

  /// The ready-made style with this title in any season (the gallery stores
  /// a style's title as the image's label), or null for a typed prompt.
  static PromptItem? findByTitle(String title) {
    final t = title.trim();
    for (final library in allSeasonLibraries) {
      for (final c in library) {
        for (final p in c.prompts) {
          if (p.title == t) return p;
        }
      }
    }
    return null;
  }

  /// The style a saved picture was made with: its stored label is the
  /// style title, or (older pictures) the library text itself.
  static PromptItem? findForSaved(String saved) =>
      findByTitle(saved) ?? findByPrompt(saved);

  /// What a saved picture is called on screen, in the gallery and on its
  /// detail screen alike. Never the library prompt text.
  static String savedTitle(String saved) => findForSaved(saved)?.title ?? saved;

  /// Library prompt whose text is exactly [prompt] (whitespace-normalized),
  /// or null when the user typed or edited their own.
  static PromptItem? findByPrompt(String prompt) {
    String norm(String s) => s
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[,.;:!\s]+$'), '');
    final target = norm(prompt);
    for (final category in [
      ..._halloweenCategories,
      ...ChristmasPrompts.categories,
    ]) {
      for (final item in category.prompts) {
        if (norm(item.prompt) == target) return item;
      }
    }
    return null;
  }

  static List<PromptItem> searchPrompts(String query) {
    if (query.isEmpty) return [];

    final List<PromptItem> results = [];
    final lowercaseQuery = query.toLowerCase();

    for (final category in _promptCategories) {
      for (final prompt in category.prompts) {
        if (prompt.title.toLowerCase().contains(lowercaseQuery) ||
            prompt.prompt.toLowerCase().contains(lowercaseQuery)) {
          results.add(prompt);
        }
      }
    }

    return results;
  }

  static List<PromptItem> getPromptsByTag(String tag) {
    final List<PromptItem> results = [];
    final lowercaseTag = tag.toLowerCase();

    for (final category in _promptCategories) {
      for (final prompt in category.prompts) {
        if (prompt.tags.any(
          (promptTag) => promptTag.toLowerCase().contains(lowercaseTag),
        )) {
          results.add(prompt);
        }
      }
    }

    return results;
  }
}
