# frozen_string_literal: true

require "clamp"

require "arke/core"

require "arke/ethereum/exceptions"
require "arke/ethereum/secp256k1"
require "arke/ethereum/constant"
require "arke/ethereum/address"
require "arke/ethereum/public_key"
require "arke/ethereum/private_key"
require "arke/ethereum/utils"
require "arke/ethereum/base_convert"

require "arke/strategy/base"
require "arke/strategy/copy"
require "arke/strategy/fixedprice"
require "arke/strategy/microtrades_copy"
require "arke/strategy/microtrades_market"
require "arke/strategy/microtrades"
require "arke/strategy/orderback"
require "arke/strategy/circuitbraker"
require "arke/strategy/candle_sampling"
require "arke/strategy/simple_copy"

require "arke/command"
require "arke/command/order"
require "arke/command/show"
require "arke/command/start"
require "arke/command/version"
require "arke/command/root"
