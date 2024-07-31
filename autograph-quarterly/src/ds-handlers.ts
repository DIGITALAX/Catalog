import {
  Bytes,
  JSONValueKind,
  dataSource,
  json,
} from "@graphprotocol/graph-ts";
import { CollectionMetadata } from "../generated/schema";

export function handleCollectionMetadata(content: Bytes): void {
  let metadata = new CollectionMetadata(dataSource.stringParam());
  const value = json.fromString(content.toString()).toObject();
  if (value) {
    let image = value.get("image");
    if (image && image.kind === JSONValueKind.STRING) {
      metadata.image = image.toString();
    }
    let description = value.get("description");
    if (description && description.kind === JSONValueKind.STRING) {
      metadata.description = description.toString().substring(0, 2000);
    }
    let title = value.get("title");
    if (title && title.kind === JSONValueKind.STRING) {
      metadata.title = title.toString();
    }
    let tags = value.get("tags");
    if (tags && tags.kind === JSONValueKind.STRING) {
      metadata.tags = tags.toString();
    }
    let npcs = value.get("npcs");
    if (npcs && npcs.kind === JSONValueKind.STRING) {
      metadata.npcs = npcs.toString();
    }
    let locales = value.get("locales");
    if (locales && locales.kind === JSONValueKind.STRING) {
      metadata.locales = locales.toString();
    }
    let instructions = value.get("instructions");
    if (instructions && instructions.kind === JSONValueKind.STRING) {
      metadata.instructions = instructions.toString().substring(0, 2000);
    }
    let tipo = value.get("tipo");
    if (tipo && tipo.kind === JSONValueKind.STRING) {
      metadata.tipo = tipo.toString();
    }
    let gallery = value.get("tipo");
    if (gallery && gallery.kind === JSONValueKind.STRING) {
      metadata.gallery = gallery.toString();
    }

    let images = value.get("images");
    if (images && images.kind === JSONValueKind.ARRAY) {
      metadata.images = images
        .toArray()
        .filter(
          (item) =>
            item.kind === JSONValueKind.STRING
        )
        .map<string>((item) => item.toString());
    }


    let colors = value.get("colors");
    if (colors && colors.kind === JSONValueKind.ARRAY) {
      metadata.colors = colors
        .toArray()
        .filter(
          (item) =>
            item.kind === JSONValueKind.STRING
        )
        .map<string>((item) => item.toString());
    }

    metadata.save();
  }
}
