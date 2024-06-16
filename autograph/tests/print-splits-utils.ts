import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  CurrencyAdded,
  CurrencyRemoved,
  DesignerSplitSet,
  FulfillerBaseSet,
  FulfillerSplitSet,
  OracleUpdated,
  TreasurySplitSet
} from "../generated/PrintSplits/PrintSplits"

export function createCurrencyAddedEvent(currency: Address): CurrencyAdded {
  let currencyAddedEvent = changetype<CurrencyAdded>(newMockEvent())

  currencyAddedEvent.parameters = new Array()

  currencyAddedEvent.parameters.push(
    new ethereum.EventParam("currency", ethereum.Value.fromAddress(currency))
  )

  return currencyAddedEvent
}

export function createCurrencyRemovedEvent(currency: Address): CurrencyRemoved {
  let currencyRemovedEvent = changetype<CurrencyRemoved>(newMockEvent())

  currencyRemovedEvent.parameters = new Array()

  currencyRemovedEvent.parameters.push(
    new ethereum.EventParam("currency", ethereum.Value.fromAddress(currency))
  )

  return currencyRemovedEvent
}

export function createDesignerSplitSetEvent(
  designer: Address,
  printType: BigInt,
  split: BigInt
): DesignerSplitSet {
  let designerSplitSetEvent = changetype<DesignerSplitSet>(newMockEvent())

  designerSplitSetEvent.parameters = new Array()

  designerSplitSetEvent.parameters.push(
    new ethereum.EventParam("designer", ethereum.Value.fromAddress(designer))
  )
  designerSplitSetEvent.parameters.push(
    new ethereum.EventParam(
      "printType",
      ethereum.Value.fromUnsignedBigInt(printType)
    )
  )
  designerSplitSetEvent.parameters.push(
    new ethereum.EventParam("split", ethereum.Value.fromUnsignedBigInt(split))
  )

  return designerSplitSetEvent
}

export function createFulfillerBaseSetEvent(
  fulfiller: Address,
  printType: BigInt,
  split: BigInt
): FulfillerBaseSet {
  let fulfillerBaseSetEvent = changetype<FulfillerBaseSet>(newMockEvent())

  fulfillerBaseSetEvent.parameters = new Array()

  fulfillerBaseSetEvent.parameters.push(
    new ethereum.EventParam("fulfiller", ethereum.Value.fromAddress(fulfiller))
  )
  fulfillerBaseSetEvent.parameters.push(
    new ethereum.EventParam(
      "printType",
      ethereum.Value.fromUnsignedBigInt(printType)
    )
  )
  fulfillerBaseSetEvent.parameters.push(
    new ethereum.EventParam("split", ethereum.Value.fromUnsignedBigInt(split))
  )

  return fulfillerBaseSetEvent
}

export function createFulfillerSplitSetEvent(
  fulfiller: Address,
  printType: BigInt,
  split: BigInt
): FulfillerSplitSet {
  let fulfillerSplitSetEvent = changetype<FulfillerSplitSet>(newMockEvent())

  fulfillerSplitSetEvent.parameters = new Array()

  fulfillerSplitSetEvent.parameters.push(
    new ethereum.EventParam("fulfiller", ethereum.Value.fromAddress(fulfiller))
  )
  fulfillerSplitSetEvent.parameters.push(
    new ethereum.EventParam(
      "printType",
      ethereum.Value.fromUnsignedBigInt(printType)
    )
  )
  fulfillerSplitSetEvent.parameters.push(
    new ethereum.EventParam("split", ethereum.Value.fromUnsignedBigInt(split))
  )

  return fulfillerSplitSetEvent
}

export function createOracleUpdatedEvent(
  currency: Address,
  rate: BigInt
): OracleUpdated {
  let oracleUpdatedEvent = changetype<OracleUpdated>(newMockEvent())

  oracleUpdatedEvent.parameters = new Array()

  oracleUpdatedEvent.parameters.push(
    new ethereum.EventParam("currency", ethereum.Value.fromAddress(currency))
  )
  oracleUpdatedEvent.parameters.push(
    new ethereum.EventParam("rate", ethereum.Value.fromUnsignedBigInt(rate))
  )

  return oracleUpdatedEvent
}

export function createTreasurySplitSetEvent(
  treasury: Address,
  printType: BigInt,
  split: BigInt
): TreasurySplitSet {
  let treasurySplitSetEvent = changetype<TreasurySplitSet>(newMockEvent())

  treasurySplitSetEvent.parameters = new Array()

  treasurySplitSetEvent.parameters.push(
    new ethereum.EventParam("treasury", ethereum.Value.fromAddress(treasury))
  )
  treasurySplitSetEvent.parameters.push(
    new ethereum.EventParam(
      "printType",
      ethereum.Value.fromUnsignedBigInt(printType)
    )
  )
  treasurySplitSetEvent.parameters.push(
    new ethereum.EventParam("split", ethereum.Value.fromUnsignedBigInt(split))
  )

  return treasurySplitSetEvent
}
