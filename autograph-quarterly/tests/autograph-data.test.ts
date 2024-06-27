import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { AutographCreated } from "../generated/schema"
import { AutographCreated as AutographCreatedEvent } from "../generated/AutographData/AutographData"
import { handleAutographCreated } from "../src/autograph-data"
import { createAutographCreatedEvent } from "./autograph-data-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let uri = "Example string value"
    let amount = BigInt.fromI32(234)
    let newAutographCreatedEvent = createAutographCreatedEvent(uri, amount)
    handleAutographCreated(newAutographCreatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("AutographCreated created and stored", () => {
    assert.entityCount("AutographCreated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "AutographCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "uri",
      "Example string value"
    )
    assert.fieldEquals(
      "AutographCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "amount",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
