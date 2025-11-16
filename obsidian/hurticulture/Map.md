My original idea for the map was a giant map that was generated upon loading the world. Obviously this is a shit idea, because it takes forever to load and takes a ton of VRAM.

Then, I decided to render only what the player actively needs with a huge render distance using LOD, but the LOD system has taken months off of my project without much to show for.

I've decided to only render a small area like Minecraft. Even Minecraft renders a 16x16 (256 quad) chunk, resulting in 1024 vertices.

For a GTX 1060, ChatGPT recommends staying below a 8 million vertices. Even with a chunk radius of 12, we're rendering 25x25 chunks, which is only 640k vertices.

This seems more performant than I even need. After that I can just put texture on the horizon or add a fog. Maybe even both depending on the weather.

I want the world to be separated by distance. The further the player gets from the center of the map (spawn), the higher the biome difficulty gets.