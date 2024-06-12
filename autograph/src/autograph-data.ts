import {
  AutographCreated as AutographCreatedEvent,
  AutographTokensMinted as AutographTokensMintedEvent,
  CollectionDeleted as CollectionDeletedEvent,
  CollectionTokenMinted as CollectionTokenMintedEvent,
  GalleryCreated as GalleryCreatedEvent,
  GalleryDeleted as GalleryDeletedEvent,
  GalleryUpdated as GalleryUpdatedEvent,
  OrderCreated as OrderCreatedEvent,
  PublicationConnected as PublicationConnectedEvent
} from "../generated/AutographData/AutographData"
import {
  AutographCreated,
  AutographTokensMinted,
  CollectionDeleted,
  CollectionTokenMinted,
  GalleryCreated,
  GalleryDeleted,
  GalleryUpdated,
  OrderCreated,
  PublicationConnected
} from "../generated/schema"

export function handleAutographCreated(event: AutographCreatedEvent): void {
  let entity = new AutographCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.uri = event.params.uri
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAutographTokensMinted(
  event: AutographTokensMintedEvent
): void {
  let entity = new AutographTokensMinted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleCollectionDeleted(event: CollectionDeletedEvent): void {
  let entity = new CollectionDeleted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.collectionId = event.params.collectionId
  entity.galleryId = event.params.galleryId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleCollectionTokenMinted(
  event: CollectionTokenMintedEvent
): void {
  let entity = new CollectionTokenMinted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.tokenIds = event.params.tokenIds
  entity.collectionIds = event.params.collectionIds
  entity.galleryIds = event.params.galleryIds

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleGalleryCreated(event: GalleryCreatedEvent): void {
  let entity = new GalleryCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.collectionIds = event.params.collectionIds
  entity.designer = event.params.designer
  entity.galleryId = event.params.galleryId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleGalleryDeleted(event: GalleryDeletedEvent): void {
  let entity = new GalleryDeleted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.designer = event.params.designer
  entity.galleryId = event.params.galleryId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleGalleryUpdated(event: GalleryUpdatedEvent): void {
  let entity = new GalleryUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.collectionIds = event.params.collectionIds
  entity.designer = event.params.designer
  entity.galleryId = event.params.galleryId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOrderCreated(event: OrderCreatedEvent): void {
  let entity = new OrderCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.subOrderTypes = event.params.subOrderTypes
  entity.total = event.params.total
  entity.orderId = event.params.orderId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handlePublicationConnected(
  event: PublicationConnectedEvent
): void {
  let entity = new PublicationConnected(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.pubId = event.params.pubId
  entity.profileId = event.params.profileId
  entity.collectionId = event.params.collectionId
  entity.galleryId = event.params.galleryId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
