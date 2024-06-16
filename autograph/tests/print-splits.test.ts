import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { CurrencyAdded } from "../generated/schema"
import { CurrencyAdded as CurrencyAddedEvent } from "../generated/PrintSplits/PrintSplits"
import { handleCurrencyAdded } from "../src/print-splits"
import { createCurrencyAddedEvent } from "./print-splits-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let currency = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let newCurrencyAddedEvent = createCurrencyAddedEvent(currency)
    handleCurrencyAdded(newCurrencyAddedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("CurrencyAdded created and stored", () => {
    assert.entityCount("CurrencyAdded", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "CurrencyAdded",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "currency",
      "0x0000000000000000000000000000000000000001"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
