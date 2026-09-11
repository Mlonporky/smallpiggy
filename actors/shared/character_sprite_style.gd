class_name CharacterSpriteStyle
extends RefCounted
## All character sprites share this sampling policy. Their imports must generate mipmaps.
## Style/outline density belongs in the source artwork, not per-character filters.
const FILTER := CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
