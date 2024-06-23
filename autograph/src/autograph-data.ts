import {
  Address,
  BigInt,
  ByteArray,
  Bytes,
  JSONValue,
  json,
  store,
} from "@graphprotocol/graph-ts";
import {
  AutographCreated as AutographCreatedEvent,
  AutographData,
  AutographTokensMinted as AutographTokensMintedEvent,
  CollectionDeleted as CollectionDeletedEvent,
  CollectionTokenMinted as CollectionTokenMintedEvent,
  GalleryCreated as GalleryCreatedEvent,
  GalleryDeleted as GalleryDeletedEvent,
  GalleryUpdated as GalleryUpdatedEvent,
  OrderCreated as OrderCreatedEvent,
  PublicationConnected as PublicationConnectedEvent,
} from "../generated/AutographData/AutographData";
import { CollectionMetadata as CollectionMetadataTemplate } from "../generated/templates";
import {
  AutographCreated,
  AutographTokensMinted,
  Collection,
  CollectionDeleted,
  CollectionTokenMinted,
  GalleryCreated,
  GalleryDeleted,
  GalleryUpdated,
  OrderCreated,
  PublicationConnected,
} from "../generated/schema";

export function handleAutographCreated(event: AutographCreatedEvent): void {
  let entity = new AutographCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.uri = event.params.uri;
  entity.amount = event.params.amount;

  let datos = AutographData.bind(
    Address.fromString("0xe24e2baA8e53B06820952d82538b495C2A3fA247")
  );

  entity.price = datos.getAutographPrice();
  entity.pageCount = datos.getAutographPageCount();
  entity.acceptedTokens = datos
    .getAutographAcceptedTokens()
    .map<Bytes>((target: Bytes) => target);
  entity.profileId = datos.getAutographProfileId();
  entity.pubId = datos.getAutographPubId();
  entity.designer = datos.getAutographDesigner();
  entity.mintedTokens = datos.getAutographMinted();

  let pages: string[] = [];
  for (let i = 0; i < entity.pageCount - 1; i++) {
    pages.push(datos.getAutographPage(BigInt.fromI32(i + 1)));
  }

  entity.pages = pages;
  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleAutographTokensMinted(
  event: AutographTokensMintedEvent
): void {
  let entity = new AutographTokensMinted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.amount = event.params.amount;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleCollectionDeleted(event: CollectionDeletedEvent): void {
  let entity = new CollectionDeleted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.collectionId = event.params.collectionId;
  entity.galleryId = event.params.galleryId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let entityCollection = Collection.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.collectionId))
  );

  if (entityCollection) {
    store.remove(
      "Collection",
      Bytes.fromByteArray(
        ByteArray.fromBigInt(event.params.collectionId)
      ).toHexString()
    );
  }

  let entityGallery = GalleryCreated.load(
    Bytes.fromByteArray(
      ByteArray.fromBigInt(BigInt.fromI32(event.params.galleryId))
    )
  );

  if (entityGallery) {
    let newCollectionIds: BigInt[] = [];

    for (let i = 0; i < entityGallery.collectionIds.length; i++) {
      if (entityGallery.collectionIds[i] != event.params.collectionId) {
        newCollectionIds.push(entityGallery.collectionIds[i]);
      }
    }
    entityGallery.collectionIds = newCollectionIds;

    entityGallery.save();
  }

  entity.save();
}

export function handleCollectionTokenMinted(
  event: CollectionTokenMintedEvent
): void {
  let entity = new CollectionTokenMinted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.tokenIds = event.params.tokenIds;
  entity.collectionIds = event.params.collectionIds;
  entity.galleryIds = event.params.galleryIds;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleGalleryCreated(event: GalleryCreatedEvent): void {
  let entity = new GalleryCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.id = Bytes.fromByteArray(
    ByteArray.fromBigInt(BigInt.fromI32(event.params.galleryId))
  );
  entity.collectionIds = event.params.collectionIds;
  entity.designer = event.params.designer;
  entity.galleryId = event.params.galleryId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let datos = AutographData.bind(
    Address.fromString("0xe24e2baA8e53B06820952d82538b495C2A3fA247")
  );

  let colecciones: Bytes[] = [];

  for (let i = 0; i < entity.collectionIds.length; i++) {
    let coleccion = new Collection(
      Bytes.fromByteArray(ByteArray.fromBigInt(entity.collectionIds[i]))
    );
    if (coleccion.amount < 3) {
      coleccion.mix = false;
    } else {
      coleccion.mix = true;
    }
    coleccion.collectionId = entity.collectionIds[i];
    coleccion.acceptedTokens = datos
      .getCollectionAcceptedTokensByGalleryId(
        entity.collectionIds[i],
        entity.galleryId
      )
      .map<Bytes>((target: Bytes) => target);
    coleccion.price = datos.getCollectionPriceByGalleryId(
      entity.collectionIds[i],
      entity.galleryId
    );
    coleccion.amount = datos.getCollectionAmountByGalleryId(
      entity.collectionIds[i],
      entity.galleryId
    );
    coleccion.designer = datos.getCollectionDesignerByGalleryId(
      entity.collectionIds[i],
      entity.galleryId
    );
    coleccion.uri = datos.getCollectionURIByGalleryId(
      entity.collectionIds[i],
      entity.galleryId
    );
    coleccion.galleryId = entity.galleryId;
    coleccion.type = datos.getCollectionTypeByGalleryId(
      entity.collectionIds[i],
      entity.galleryId
    );
    coleccion.mintedTokens = datos.getMintedTokenIdsByGalleryId(
      entity.collectionIds[i],
      entity.galleryId
    );

    let ipfsHash = coleccion.uri.split("/").pop();
    if (ipfsHash != null) {
      coleccion.collectionMetadata = ipfsHash;
      CollectionMetadataTemplate.create(ipfsHash);
    }
    colecciones.push(coleccion.id);
    coleccion.save();
  }

  entity.collections = colecciones;

  entity.save();
}

export function handleGalleryDeleted(event: GalleryDeletedEvent): void {
  let entity = new GalleryDeleted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.designer = event.params.designer;
  entity.galleryId = event.params.galleryId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let entityGallery = GalleryCreated.load(
    Bytes.fromByteArray(
      ByteArray.fromBigInt(BigInt.fromI32(event.params.galleryId))
    )
  );

  if (entityGallery) {
    store.remove(
      "GalleryCreated",
      Bytes.fromByteArray(
        ByteArray.fromBigInt(BigInt.fromI32(event.params.galleryId))
      ).toHexString()
    );
  }

  entity.save();
}

export function handleGalleryUpdated(event: GalleryUpdatedEvent): void {
  let entity = new GalleryUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.collectionIds = event.params.collectionIds;
  entity.designer = event.params.designer;
  entity.galleryId = event.params.galleryId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let entityGallery = GalleryCreated.load(
    Bytes.fromByteArray(
      ByteArray.fromBigInt(BigInt.fromI32(event.params.galleryId))
    )
  );

  let datos = AutographData.bind(
    Address.fromString("0xe24e2baA8e53B06820952d82538b495C2A3fA247")
  );

  if (entityGallery) {
    entityGallery.collectionIds = entityGallery.collectionIds.concat(
      entity.collectionIds
    );

    let colecciones: Bytes[] | null = entityGallery.collections;

    if (colecciones == null) {
      colecciones = [];
    }

    for (let i = 0; i < entity.collectionIds.length; i++) {
      let coleccion = new Collection(
        Bytes.fromByteArray(ByteArray.fromBigInt(entity.collectionIds[i]))
      );

      colecciones.push(coleccion.id);

      if (coleccion.amount < 3) {
        coleccion.mix = false;
      } else {
        coleccion.mix = true;
      }

      coleccion.collectionId = entity.collectionIds[i];
      coleccion.acceptedTokens = datos
        .getCollectionAcceptedTokensByGalleryId(
          entity.collectionIds[i],
          entity.galleryId
        )
        .map<Bytes>((target: Bytes) => target);
      coleccion.price = datos.getCollectionPriceByGalleryId(
        entity.collectionIds[i],
        entity.galleryId
      );
      coleccion.amount = datos.getCollectionAmountByGalleryId(
        entity.collectionIds[i],
        entity.galleryId
      );
      coleccion.designer = datos.getCollectionDesignerByGalleryId(
        entity.collectionIds[i],
        entity.galleryId
      );
      coleccion.uri = datos.getCollectionURIByGalleryId(
        entity.collectionIds[i],
        entity.galleryId
      );
      coleccion.galleryId = entity.galleryId;
      coleccion.type = datos.getCollectionTypeByGalleryId(
        entity.collectionIds[i],
        entity.galleryId
      );
      coleccion.mintedTokens = datos.getMintedTokenIdsByGalleryId(
        entity.collectionIds[i],
        entity.galleryId
      );

      let ipfsHash = coleccion.uri.split("/").pop();
      if (ipfsHash != null) {
        coleccion.collectionMetadata = ipfsHash;
        CollectionMetadataTemplate.create(ipfsHash);
      }

      coleccion.save();
    }

    entityGallery.collections = colecciones;

    entityGallery.save();
  }

  entity.save();
}

export function handleOrderCreated(event: OrderCreatedEvent): void {
  let entity = new OrderCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.subOrderTypes = event.params.subOrderTypes;
  entity.total = event.params.total;
  entity.orderId = event.params.orderId;
  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let datos = AutographData.bind(
    Address.fromString("0xe24e2baA8e53B06820952d82538b495C2A3fA247")
  );

  entity.buyer = datos.getOrderBuyer(entity.orderId);
  entity.fulfillment = datos.getOrderFulfillment(entity.orderId);
  entity.amounts = datos.getOrderAmounts(entity.orderId);
  entity.subTotals = datos.getOrderSubTotals(entity.orderId);
  entity.parentIds = datos.getOrderParentIds(entity.orderId);
  entity.currencies = datos
    .getOrderCurrencies(entity.orderId)
    .map<Bytes>((target: Bytes) => target);

  let collectionIdsArray: BigInt[][] = datos.getOrderCollectionIds(
    entity.orderId
  );

  let jsonString = "[";
  for (let i = 0; i < collectionIdsArray.length; i++) {
    jsonString += "[";
    for (let j = 0; j < collectionIdsArray[i].length; j++) {
      jsonString += '"' + collectionIdsArray[i][j].toString() + '"';
      if (j < collectionIdsArray[i].length - 1) jsonString += ",";
    }
    jsonString += "]";
    if (i < collectionIdsArray.length - 1) jsonString += ",";
  }
  jsonString += "]";
  entity.collectionIds = jsonString;

  let mintedTokensArray: BigInt[][] = datos.getOrderMintedTokens(
    entity.orderId
  );

  let jsonStringMinted = "[";
  for (let i = 0; i < mintedTokensArray.length; i++) {
    jsonStringMinted += "[";
    for (let j = 0; j < mintedTokensArray[i].length; j++) {
      jsonStringMinted += '"' + mintedTokensArray[i][j].toString() + '"';
      if (j < mintedTokensArray[i].length - 1) jsonStringMinted += ",";
    }
    jsonStringMinted += "]";
    if (i < mintedTokensArray.length - 1) jsonStringMinted += ",";
  }
  jsonStringMinted += "]";
  entity.mintedTokens = jsonStringMinted;

  const colIds = datos.getOrderCollectionIds(entity.orderId);

  for (let i = 0; i < colIds.length; i++) {
    for (let j = 0; j < colIds[i].length; j++) {
      let entityCollection = Collection.load(
        Bytes.fromByteArray(ByteArray.fromBigInt(colIds[i][j]))
      );

      if (entityCollection) {
        const gId = datos.getCollectionGallery(entityCollection.collectionId);

        entityCollection.mintedTokens = datos.getMintedTokenIdsByGalleryId(
          entityCollection.collectionId,
          gId
        );

        if (entityCollection.mintedTokens == null) {
          entityCollection.mintedTokens = [];
        }

        if (
          entityCollection.amount -
            (entityCollection.mintedTokens as BigInt[]).length >
          2
        ) {
          entityCollection.mix = true;
        } else {
          entityCollection.mix = false;
        }

        entityCollection.save();
      }
    }
  }

  entity.save();
}

export function handlePublicationConnected(
  event: PublicationConnectedEvent
): void {
  let entity = new PublicationConnected(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.pubId = event.params.pubId;
  entity.profileId = event.params.profileId;
  entity.collectionId = event.params.collectionId;
  entity.galleryId = event.params.galleryId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let entityCollection = Collection.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.collectionId))
  );

  if (entityCollection) {
    let pubIds: BigInt[] | null = entityCollection.pubIds;
    let profileIds: BigInt[] | null = entityCollection.profileIds;

    if (pubIds == null) {
      pubIds = [];
    }

    if (profileIds == null) {
      profileIds = [];
    }

    profileIds.push(entity.profileId);
    pubIds.push(entity.pubId);

    entityCollection.pubIds = pubIds;
    entityCollection.profileIds = profileIds;

    entityCollection.save();
  }

  entity.save();
}
