import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
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
} from "../generated/AutographData/AutographData"

export function createAutographCreatedEvent(
  uri: string,
  amount: BigInt
): AutographCreated {
  let autographCreatedEvent = changetype<AutographCreated>(newMockEvent())

  autographCreatedEvent.parameters = new Array()

  autographCreatedEvent.parameters.push(
    new ethereum.EventParam("uri", ethereum.Value.fromString(uri))
  )
  autographCreatedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return autographCreatedEvent
}

export function createAutographTokensMintedEvent(
  amount: i32
): AutographTokensMinted {
  let autographTokensMintedEvent = changetype<AutographTokensMinted>(
    newMockEvent()
  )

  autographTokensMintedEvent.parameters = new Array()

  autographTokensMintedEvent.parameters.push(
    new ethereum.EventParam(
      "amount",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(amount))
    )
  )

  return autographTokensMintedEvent
}

export function createCollectionDeletedEvent(
  collectionId: BigInt,
  galleryId: i32
): CollectionDeleted {
  let collectionDeletedEvent = changetype<CollectionDeleted>(newMockEvent())

  collectionDeletedEvent.parameters = new Array()

  collectionDeletedEvent.parameters.push(
    new ethereum.EventParam(
      "collectionId",
      ethereum.Value.fromUnsignedBigInt(collectionId)
    )
  )
  collectionDeletedEvent.parameters.push(
    new ethereum.EventParam(
      "galleryId",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(galleryId))
    )
  )

  return collectionDeletedEvent
}

export function createCollectionTokenMintedEvent(
  tokenIds: Array<BigInt>,
  collectionIds: Array<BigInt>,
  galleryIds: Array<i32>
): CollectionTokenMinted {
  let collectionTokenMintedEvent = changetype<CollectionTokenMinted>(
    newMockEvent()
  )

  collectionTokenMintedEvent.parameters = new Array()

  collectionTokenMintedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenIds",
      ethereum.Value.fromUnsignedBigIntArray(tokenIds)
    )
  )
  collectionTokenMintedEvent.parameters.push(
    new ethereum.EventParam(
      "collectionIds",
      ethereum.Value.fromUnsignedBigIntArray(collectionIds)
    )
  )
  collectionTokenMintedEvent.parameters.push(
    new ethereum.EventParam(
      "galleryIds",
      ethereum.Value.fromI32Array(galleryIds)
    )
  )

  return collectionTokenMintedEvent
}

export function createGalleryCreatedEvent(
  collectionIds: Array<BigInt>,
  designer: Address,
  galleryId: i32
): GalleryCreated {
  let galleryCreatedEvent = changetype<GalleryCreated>(newMockEvent())

  galleryCreatedEvent.parameters = new Array()

  galleryCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "collectionIds",
      ethereum.Value.fromUnsignedBigIntArray(collectionIds)
    )
  )
  galleryCreatedEvent.parameters.push(
    new ethereum.EventParam("designer", ethereum.Value.fromAddress(designer))
  )
  galleryCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "galleryId",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(galleryId))
    )
  )

  return galleryCreatedEvent
}

export function createGalleryDeletedEvent(
  designer: Address,
  galleryId: i32
): GalleryDeleted {
  let galleryDeletedEvent = changetype<GalleryDeleted>(newMockEvent())

  galleryDeletedEvent.parameters = new Array()

  galleryDeletedEvent.parameters.push(
    new ethereum.EventParam("designer", ethereum.Value.fromAddress(designer))
  )
  galleryDeletedEvent.parameters.push(
    new ethereum.EventParam(
      "galleryId",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(galleryId))
    )
  )

  return galleryDeletedEvent
}

export function createGalleryUpdatedEvent(
  collectionIds: Array<BigInt>,
  designer: Address,
  galleryId: i32
): GalleryUpdated {
  let galleryUpdatedEvent = changetype<GalleryUpdated>(newMockEvent())

  galleryUpdatedEvent.parameters = new Array()

  galleryUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "collectionIds",
      ethereum.Value.fromUnsignedBigIntArray(collectionIds)
    )
  )
  galleryUpdatedEvent.parameters.push(
    new ethereum.EventParam("designer", ethereum.Value.fromAddress(designer))
  )
  galleryUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "galleryId",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(galleryId))
    )
  )

  return galleryUpdatedEvent
}

export function createOrderCreatedEvent(
  subOrderTypes: Array<i32>,
  total: BigInt,
  orderId: BigInt
): OrderCreated {
  let orderCreatedEvent = changetype<OrderCreated>(newMockEvent())

  orderCreatedEvent.parameters = new Array()

  orderCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "subOrderTypes",
      ethereum.Value.fromI32Array(subOrderTypes)
    )
  )
  orderCreatedEvent.parameters.push(
    new ethereum.EventParam("total", ethereum.Value.fromUnsignedBigInt(total))
  )
  orderCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "orderId",
      ethereum.Value.fromUnsignedBigInt(orderId)
    )
  )

  return orderCreatedEvent
}

export function createPublicationConnectedEvent(
  pubId: BigInt,
  profileId: BigInt,
  collectionId: BigInt,
  galleryId: i32
): PublicationConnected {
  let publicationConnectedEvent = changetype<PublicationConnected>(
    newMockEvent()
  )

  publicationConnectedEvent.parameters = new Array()

  publicationConnectedEvent.parameters.push(
    new ethereum.EventParam("pubId", ethereum.Value.fromUnsignedBigInt(pubId))
  )
  publicationConnectedEvent.parameters.push(
    new ethereum.EventParam(
      "profileId",
      ethereum.Value.fromUnsignedBigInt(profileId)
    )
  )
  publicationConnectedEvent.parameters.push(
    new ethereum.EventParam(
      "collectionId",
      ethereum.Value.fromUnsignedBigInt(collectionId)
    )
  )
  publicationConnectedEvent.parameters.push(
    new ethereum.EventParam(
      "galleryId",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(galleryId))
    )
  )

  return publicationConnectedEvent
}
