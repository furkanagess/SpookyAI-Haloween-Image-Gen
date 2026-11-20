import '../models/prompt_category.dart';

/// The Christmas style library: same shape and rules as the Halloween one
/// (see PROMPT_ARCHITECTURE.md). Tags reuse the Christmas scene kits' tags so
/// the engine can pick a matching setting.
class ChristmasPrompts {
  ChristmasPrompts._();

  static const List<PromptCategory> categories = [
    PromptCategory(
      id: "text_to_image",
      name: "Text to Image",
      icon: "🎄",
      description: "Christmas characters and scenes from a short description",
      prompts: [
        PromptItem(
          id: "santa_workshop",
          title: "Santa's Workshop",
          prompt:
              "A jolly Santa in a plush red coat and round spectacles bent over a workbench, carving a wooden toy by lantern light, shelves of painted trains and dolls behind him, a sleepy cat curled on a sack of gifts.",
          isPopular: true,
          tagline: "The busiest night starts with sawdust.",
          description:
              "Santa at his workbench among painted toys and lantern light. Warm, handmade and full of small details.",
          tags: ["santa", "cozy", "vintage"],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "frost_queen",
          title: "Frost Queen",
          prompt:
              "A regal winter queen in a pale blue gown and a cloak of white fur, a crown of frosted crystals, one hand raised as snowflakes swirl around her fingertips, long silver braids, a calm and commanding gaze.",
          isPopular: true,
          tagline: "Snow answers when she lifts a hand.",
          description:
              "A crowned queen in a cloak of white fur calls a swirl of snowflakes. Cold, elegant and quietly powerful.",
          tags: ["snow", "nobility", "fantasy"],
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "gingerbread_village",
          title: "Gingerbread Village",
          prompt:
              "A tiny village of gingerbread houses with icing roofs and gumdrop lamps, candy-cane fences, a frosted sugar-pine tree, dusted with powdered-sugar snow, miniature scale with a shallow depth of field.",
          tagline: "Every roof is made of icing.",
          description:
              "A miniature village of gingerbread houses, gumdrop lamps and candy-cane fences under powdered-sugar snow.",
          tags: ["cozy", "street", "party"],
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "aurora_reindeer",
          title: "Aurora Reindeer",
          prompt:
              "A majestic reindeer with silver-frosted antlers standing in a snowy pine forest, breath misting in the cold air, soft green and violet aurora ribbons glowing above the treetops, quiet and magical.",
          tagline: "Antlers that catch the northern lights.",
          description:
              "A frost-antlered reindeer stands among snowy pines while the aurora glows overhead. Quiet, cold and magical.",
          tags: ["snow", "forest", "fantasy"],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "elf_toymaker",
          title: "Elf Toymaker",
          prompt:
              "A cheerful elf in a green felt tunic and a bell-tipped hat, balancing on a stool to paint a rocking horse, jars of bright paint and ribbons all around, warm lamplight and sawdust in the air.",
          isPopular: true,
          tagline: "One more coat of red paint.",
          description:
              "A busy elf paints a rocking horse surrounded by ribbons and paint jars. Handmade, warm and full of cheer.",
          tags: ["elf", "cozy", "vintage"],
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "lantern_snowman",
          title: "Lantern Snowman",
          prompt:
              "A friendly snowman with a knitted red scarf and a stovepipe hat, holding a glowing brass lantern on a quiet village street at dusk, soft snowfall, warm windows glowing in the background.",
          tagline: "He keeps the lantern lit until morning.",
          description:
              "A scarf-wearing snowman holds a brass lantern on a snowy street while windows glow behind him.",
          tags: ["snow", "street", "cozy"],
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "fireside_cat",
          title: "Fireside Cat",
          prompt:
              "A fluffy ginger cat asleep on a knitted blanket in front of a crackling fireplace, a small decorated tree twinkling beside it, stockings on the mantel, a half-finished cup of cocoa on the rug.",
          tagline: "The best seat in the house.",
          description:
              "A ginger cat naps by the fire next to a twinkling tree. The coziest scene of the season.",
          tags: ["cozy", "tree", "family"],
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "winter_market_stall",
          title: "Winter Market",
          prompt:
              "A wooden stall at an evening Christmas market piled with wreaths, spiced cookies and handmade ornaments, strings of warm lights overhead, steam rising from mugs of mulled cider, shoppers softly blurred behind.",
          tagline: "Cider, lights and handmade things.",
          description:
              "A market stall of wreaths, cookies and ornaments under strings of lights, with steam rising from mugs.",
          tags: ["market", "street", "party"],
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "frost_dragon",
          title: "Frost Dragon",
          prompt:
              "A gentle ice dragon curled around a snow-covered spruce, scales like frosted glass, strings of tiny lights tangled in its horns, sparkling snow drifting from its wings, a glacier and a pale winter sky behind it.",
          ownsScene: true,
          tagline: "It was only trying to help decorate.",
          description:
              "A frosted-glass dragon wraps around a snowy spruce, lights tangled in its horns. Storybook winter fantasy.",
          tags: ["snow", "fantasy", "nobility"],
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
        PromptItem(
          id: "tree_still_life",
          title: "Tree Light Still Life",
          prompt:
              "A close view of a Christmas tree branch hung with glass baubles, a small wooden star and warm fairy lights, soft golden bokeh in the background, a few pine needles and a ribbon in the foreground.",
          isPopular: true,
          tagline: "A whole evening in one branch.",
          description:
              "Glass baubles, a wooden star and fairy lights on a single branch, with warm golden bokeh behind.",
          tags: ["tree", "cozy", "vintage"],
          isPremium: true,
          promptType: PromptType.textToImage,
        ),
      ],
    ),
    PromptCategory(
      id: "image_to_image",
      name: "Image to Image",
      icon: "🎅",
      description: "Turn your photo into a Christmas character or scene",
      prompts: [
        PromptItem(
          id: "christmas_santa",
          kind: StyleKind.fantasy,
          title: "Jolly Santa",
          prompt:
              "the person as a cheerful Santa in a red velvet coat trimmed with white fur and a jingling hat, round spectacles, rosy cheeks and a warm smile",
          isPopular: true,
          tagline: "Ho ho, it suits you.",
          description:
              "A red velvet coat, a fur-trimmed hat and rosy cheeks. You as the most welcome person on the street.",
          tags: ["santa", "cozy", "family"],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_elf",
          kind: StyleKind.fantasy,
          title: "Workshop Elf",
          prompt:
              "the person as a cheerful elf in a green felt tunic with a gold buckle belt, small pointed ears, striped stockings and a bell-tipped hat, holding a wrapped gift",
          isPopular: true,
          tagline: "Gift wrapping is a serious craft.",
          description:
              "A green felt tunic, a bell-tipped hat and a wrapped gift. You as the busiest helper at the pole.",
          tags: ["elf", "fantasy", "cozy"],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_sweater",
          title: "Cozy Sweater",
          prompt:
              "the person in a chunky hand-knit Christmas sweater with reindeer and snowflake patterns, a soft scarf, rosy cheeks, holding a steaming mug of cocoa with both hands",
          isPopular: true,
          tagline: "Itchy, warm and entirely worth it.",
          description:
              "A hand-knit reindeer sweater, a soft scarf and a mug of cocoa. The warmest card in the pile.",
          tags: ["cozy", "family", "snow"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_snow_royalty",
          kind: StyleKind.fantasy,
          title: "Winter Royalty",
          prompt:
              "the person as winter royalty in a pale blue velvet cloak edged with white fur, a slim silver crown set with frosted crystals, their own hair worn loose with a few snowflakes caught in it",
          tagline: "Frost on the crown, calm in the eyes.",
          description:
              "A pale blue cloak, a frosted silver crown and snowflakes in your hair. Quiet, regal and cold in the best way.",
          tags: ["nobility", "snow", "fantasy"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_nutcracker",
          kind: StyleKind.fantasy,
          title: "Storybook Nutcracker",
          prompt:
              "the person as a storybook nutcracker soldier in a red coat with gold braid and brass buttons, a tall black shako hat, white gloves and a proud upright pose",
          tagline: "Standing guard over the tree.",
          description:
              "A red coat with gold braid, brass buttons and a tall hat. A toy soldier with your face and a straight back.",
          tags: ["vintage", "fantasy", "party"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_winter_angel",
          kind: StyleKind.fantasy,
          title: "Winter Angel",
          prompt:
              "the person as a gentle winter angel in a flowing cream gown with soft feathered wings and a small halo of tiny golden lights, a serene expression",
          tagline: "A little light goes a long way.",
          description:
              "A flowing cream gown, soft wings and a halo of tiny lights. Calm and glowing without losing a single detail of you.",
          tags: ["fantasy", "snow", "nobility"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_fireplace",
          title: "By the Fireplace",
          prompt:
              "the person curled in an armchair by a crackling fireplace under a knitted blanket, a decorated tree glowing behind, a cup of cocoa in hand, warm firelight on their face",
          isPopular: true,
          ownsScene: true,
          tagline: "The one evening nothing is urgent.",
          description:
              "You in an armchair with a blanket, a glowing tree and a crackling fire. Christmas Eve, exactly as it should feel.",
          tags: ["cozy", "tree", "family"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_snowy_street",
          title: "Snowy Village Walk",
          prompt:
              "the person walking along a snowy village street at dusk in a long wool coat and scarf, strings of lights overhead, carrying a paper bag of gifts, soft snow falling, glowing shop windows behind",
          ownsScene: true,
          tagline: "Last-minute shopping, but make it cinematic.",
          description:
              "A wool coat, a bag of gifts and a street of glowing windows with snow falling. A film still starring you.",
          tags: ["street", "snow", "party"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_retro_card",
          title: "Vintage Christmas Card",
          prompt:
              "the person in a 1950s style Christmas card portrait, festive knitwear and retro styling, posed beside a shimmering tinsel tree with wrapped gifts at their feet, soft film colors and gentle grain",
          ownsScene: true,
          tagline: "Straight out of a family album.",
          description:
              "Festive knitwear beside a tinsel tree, with soft film colors and gentle grain. A card your grandparents would frame.",
          tags: ["vintage", "family", "cozy"],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_woodland",
          kind: StyleKind.fantasy,
          title: "Woodland Wanderer",
          prompt:
              "the person as a snowy woodland wanderer in a green wool cape with fur trim, a small reindeer antler headband, thick mittens and a glowing lantern in one hand",
          tagline: "Following the lantern into the pines.",
          description:
              "A green wool cape, tiny antlers and a lantern held low. You in the quiet part of the forest where the snow is untouched.",
          tags: ["forest", "snow", "fantasy"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_cabin_window",
          title: "Cabin Window",
          prompt:
              "the person sitting on a cabin window seat with a mug in both hands, snow falling softly outside, warm string lights around the frame, a knitted blanket, soft golden light on their face",
          ownsScene: true,
          tagline: "The best seat in the house.",
          description:
              "A window seat, a warm mug and snow falling past the string lights. Pure cabin calm.",
          tags: ["cabin", "cozy", "snow"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_snow_globe",
          kind: StyleKind.fantasy,
          title: "Snow Globe",
          prompt:
              "the person standing inside a glass snow globe on a mantel, a tiny snowy village and pine trees around them, glittering flakes in the air, glass reflections and a warm glow behind",
          ownsScene: true,
          tagline: "Shake it and the whole world snows.",
          description:
              "You inside a glass globe with a tiny village, pine trees and glittering snow. A keepsake with your face in it.",
          tags: ["snow", "fantasy", "cozy"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_sweater_party",
          title: "Sweater Party Flash",
          prompt:
              "the person at an ugly-sweater party in a loud knit sweater with a blinking tree pattern, tinsel garlands behind, a direct on-camera flash, grainy instant-photo colors, a big laugh",
          ownsScene: true,
          tagline: "The louder the sweater, the better.",
          description:
              "A loud knit sweater, tinsel garlands and a flash that catches a real laugh. The party photo everyone wants.",
          tags: ["party", "vintage", "cozy"],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_gingerbread_baker",
          title: "Gingerbread Baker",
          prompt:
              "the person baking gingerbread in a warm kitchen with flour dust floating in the light, an apron, decorating a small gingerbread house with icing, cookie trays and spices around, warm tungsten light",
          ownsScene: true,
          tagline: "Flour on the nose, icing everywhere.",
          description:
              "Flour dust in warm light, an icing bag in hand and a small gingerbread house taking shape.",
          tags: ["cozy", "family", "vintage"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_ice_queen",
          kind: StyleKind.fantasy,
          title: "Ice Queen",
          prompt:
              "the person as an ice queen with soft frost makeup on the cheekbones, a delicate crown of clear crystals, a pale silver-blue gown with a high collar, their own hair swept back",
          tagline: "Cold looks good on you.",
          description:
              "Soft frost on the cheekbones, a crown of clear crystals and a high-collared silver-blue gown.",
          tags: ["snow", "nobility", "fantasy"],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_skating_rink",
          kind: StyleKind.fantasy,
          title: "Enchanted Ice Lake",
          prompt:
              "the person ice skating on a frozen lake in an enchanted snowy forest at night, tiny glowing lights floating in the air, frosted trees sparkling around them, a bright wool coat and mittens",
          ownsScene: true,
          tagline: "A frozen lake that glows for you.",
          description:
              "A frozen lake deep in a snowy forest, floating lights and frosted trees sparkling all around you.",
          tags: ["forest", "snow", "fantasy"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_sleigh_ride",
          kind: StyleKind.fantasy,
          title: "Flying Sleigh",
          prompt:
              "the person riding a flying sleigh pulled by reindeer high above a snowy village at night, wrapped in a plaid blanket and a fur-trimmed hat, stars and a bright full moon around them",
          ownsScene: true,
          tagline: "Jingle bells, from above the rooftops.",
          description:
              "A reindeer-drawn sleigh high over a snowy village, with the stars and the moon right beside you.",
          tags: ["snow", "fantasy", "vintage"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_tree_farm",
          title: "Tree Farm",
          prompt:
              "the person carrying a freshly cut fir tree over one shoulder at a snowy tree farm, a flannel jacket and beanie, rows of evergreens behind, low golden sunlight, a happy tired smile",
          ownsScene: true,
          tagline: "The tree won. You carried it anyway.",
          description:
              "A flannel jacket, a fresh-cut fir and rows of evergreens in low golden light. The best part of the whole season.",
          tags: ["forest", "family", "tree"],
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_morning_pajamas",
          title: "Christmas Morning",
          prompt:
              "the person in cozy plaid pajamas on Christmas morning, sitting on the floor beside a glowing tree surrounded by wrapped gifts and torn paper, soft sunrise light through the window",
          ownsScene: true,
          tagline: "Nobody is dressed yet.",
          description:
              "Plaid pajamas, a glowing tree and torn wrapping paper in soft sunrise light. The morning everyone remembers.",
          tags: ["family", "tree", "cozy"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
        PromptItem(
          id: "christmas_carolers",
          title: "Lamplight Carolers",
          prompt:
              "the person singing carols on a snowy cobblestone street under gas lamps in a long wool coat and a scarf, holding a songbook, glowing windows behind and gentle snowfall",
          ownsScene: true,
          tagline: "Everyone knows the second verse.",
          description:
              "A cobblestone street, gas lamps and a songbook held open. You in the middle of the best neighborhood tradition.",
          tags: ["street", "snow", "vintage"],
          isPremium: true,
          promptType: PromptType.imageToImage,
        ),
      ],
    ),
  ];
}
