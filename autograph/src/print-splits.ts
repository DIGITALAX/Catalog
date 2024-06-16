import { Address, BigInt, ByteArray, Bytes } from "@graphprotocol/graph-ts";
import {
  CurrencyAdded as CurrencyAddedEvent,
  CurrencyRemoved as CurrencyRemovedEvent,
  DesignerSplitSet as DesignerSplitSetEvent,
  FulfillerBaseSet as FulfillerBaseSetEvent,
  FulfillerSplitSet as FulfillerSplitSetEvent,
  OracleUpdated as OracleUpdatedEvent,
  PrintSplits,
  TreasurySplitSet as TreasurySplitSetEvent,
} from "../generated/PrintSplits/PrintSplits";
import {
  CurrencyAdded,
  CurrencyRemoved,
  DesignerSplitSet,
  FulfillerBaseSet,
  FulfillerSplitSet,
  OracleUpdated,
  TreasurySplitSet,
} from "../generated/schema";

export function handleCurrencyAdded(event: CurrencyAddedEvent): void {
  let entity = new CurrencyAdded(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.id = Bytes.fromByteArray(
    ByteArray.fromBigInt(BigInt.fromByteArray(event.params.currency))
  );
  entity.currency = event.params.currency;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;
  let datos = PrintSplits.bind(
    Address.fromString("0x8402e22e4712acc9Bb91Fbec752881c4F9f21b1D")
  );

  entity.wei = datos.getWeiByCurrency(event.params.currency);

  entity.save();
}

export function handleCurrencyRemoved(event: CurrencyRemovedEvent): void {
  let entity = new CurrencyRemoved(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.currency = event.params.currency;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleDesignerSplitSet(event: DesignerSplitSetEvent): void {
  let entity = new DesignerSplitSet(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.designer = event.params.designer;
  entity.printType = event.params.printType;
  entity.split = event.params.split;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleFulfillerBaseSet(event: FulfillerBaseSetEvent): void {
  let entity = new FulfillerBaseSet(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.fulfiller = event.params.fulfiller;
  entity.printType = event.params.printType;
  entity.split = event.params.split;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleFulfillerSplitSet(event: FulfillerSplitSetEvent): void {
  let entity = new FulfillerSplitSet(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.fulfiller = event.params.fulfiller;
  entity.printType = event.params.printType;
  entity.split = event.params.split;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleOracleUpdated(event: OracleUpdatedEvent): void {
  let entity = new OracleUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.currency = event.params.currency;
  entity.rate = event.params.rate;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let entityCurrency = CurrencyAdded.load(
    Bytes.fromByteArray(
      ByteArray.fromBigInt(BigInt.fromByteArray(event.params.currency))
    )
  );

  if (entityCurrency) {
    let datos = PrintSplits.bind(
      Address.fromString("0x8402e22e4712acc9Bb91Fbec752881c4F9f21b1D")
    );

    entityCurrency.rate = datos.getRateByCurrency(event.params.currency);

    entityCurrency.save();
  }

  entity.save();
}

export function handleTreasurySplitSet(event: TreasurySplitSetEvent): void {
  let entity = new TreasurySplitSet(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.treasury = event.params.treasury;
  entity.printType = event.params.printType;
  entity.split = event.params.split;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}
