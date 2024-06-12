import {
  Address,
  BigInt,
  ByteArray,
  Bytes,
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

  let entityCollection = GalleryCreated.load(
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
    Address.fromString("0x883a24A5315c0E4Ff4451E6E2B760338FDC8faE8")
  );

  let colecciones: Bytes[] = [];

  for (let i = 0; i < entity.collectionIds.length; i++) {
    let coleccion = new Collection(
      Bytes.fromByteArray(ByteArray.fromBigInt(entity.collectionIds[i]))
    );
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
    Address.fromString("0x883a24A5315c0E4Ff4451E6E2B760338FDC8faE8")
  );

  if (entityGallery) {
    entityGallery.collectionIds = entityGallery.collectionIds.concat(
      entity.collectionIds
    );

    let colecciones: Bytes[] = [];

    for (let i = 0; i < entity.collectionIds.length; i++) {
      let coleccion = new Collection(
        Bytes.fromByteArray(ByteArray.fromBigInt(entity.collectionIds[i]))
      );

      colecciones.push(coleccion.id);

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

  entity.save();
}
