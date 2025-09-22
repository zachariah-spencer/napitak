# frozen_string_literal: true

module GameData
  DATA_DIR = "data".freeze
  extend self

  def load_json(filename)
    path = "#{DATA_DIR}/#{filename}.json"
    json = GTK.read_file(path)
    raise "Missing data file: #{path}" unless json

    GTK.parse_json(json)
  end

  def convert_trait_map(raw)
    return nil unless raw

    raw
      .each_with_object({}) do |(trait_id, details), memo|
        memo[trait_id.to_i] = if details.is_a?(Hash)
          details
            .each_with_object({}) do |(key, value), inner|
              inner[key.to_sym] = value
            end
            .freeze
        else
          details
        end
      end
      .freeze
  end

  def convert_potion(raw)
    raw
      .each_with_object({}) do |(key, value), memo|
        sym_key = key.to_sym
        memo[sym_key] = case sym_key
        when :cast_animation
          convert_animation_block(value)
        when :traits
          Array(value).map { |trait| convert_trait_map(trait) }.freeze
        when :finisher_trait
          convert_trait_map(value)
        when :cast_sfx
          value && value.to_sym
        when :ingredients
          value
        else
          value
        end
      end
      .freeze
  end

  def convert_animation_block(raw)
    return nil unless raw

    raw
      .each_with_object({}) { |(key, value), memo| memo[key.to_sym] = value }
      .freeze
  end

  def convert_item(raw)
    raw
      .each_with_object({}) do |(key, value), memo|
        sym_key = key.to_sym
        memo[sym_key] = if sym_key == :ingredients
          value
        else
          value
        end
      end
      .freeze
  end

  def convert_color_map(raw)
    raw
      .each_with_object({}) do |(key, value), memo|
        memo[key.to_i] = value
          .each_with_object({}) do |(inner_key, inner_val), inner_memo|
            inner_memo[inner_key.to_sym] = inner_val
          end
          .freeze
      end
      .freeze
  end

  def convert_numeric_map(raw)
    raw
      .each_with_object({}) { |(key, value), memo| memo[key.to_i] = value }
      .freeze
  end

  FONT = load_json("font").freeze
  CARD_TRAITS = load_json("card_traits").transform_keys(&:to_sym).freeze
  STATUS_EFFECTS_DATA = load_json("status_effects").freeze
  STATUS_TYPES =
    STATUS_EFFECTS_DATA.fetch("types").transform_keys(&:to_sym).freeze
  DAMAGE_TYPES_DATA = load_json("damage_types").freeze
  DAMAGE_TYPES =
    DAMAGE_TYPES_DATA.fetch("types").transform_keys(&:to_sym).freeze
  DAMAGE_TYPE_NAMES = convert_numeric_map(DAMAGE_TYPES_DATA.fetch("type_names"))
  STATUS_EFFECT_COLORS = convert_color_map(STATUS_EFFECTS_DATA.fetch("colors"))
  DAMAGE_TYPE_COLORS = convert_color_map(DAMAGE_TYPES_DATA.fetch("colors"))
  DAMAGE_TYPE_SPRITES = convert_numeric_map(DAMAGE_TYPES_DATA.fetch("sprites"))
  ITEMS_DATA = load_json("items").freeze
  PIDS =
    load_json("pids")
      .each_with_object({}) do |(id, data), memo|
        memo[id] = convert_potion(data)
      end
      .freeze
  IIDS =
    load_json("iids")
      .each_with_object({}) { |(id, data), memo| memo[id] = convert_item(data) }
      .freeze
  SHOP_ITEMS =
    ITEMS_DATA.fetch("shop_items")
      .each_with_object({}) { |(id, data), memo| memo[id] = convert_item(data) }
      .freeze
  REWARD_ITEMS =
    ITEMS_DATA.fetch("reward_items")
      .each_with_object({}) { |(id, data), memo| memo[id] = convert_item(data) }
      .freeze
  ENCOUNTERS =
    load_json("encounters")
      .each_with_object({}) do |(id, data), memo|
        memo[id] = data
          .each_with_object({}) do |(key, value), inner|
            inner[key.to_sym] = value
          end
          .freeze
      end
      .freeze
end

$CARD_TRAITS = GameData::CARD_TRAITS
$STATUS_TYPES = GameData::STATUS_TYPES
$DAMAGE_TYPES = GameData::DAMAGE_TYPES
$DAMAGE_TYPE_NAMES = GameData::DAMAGE_TYPE_NAMES
$STATUS_EFFECT_COLORS = GameData::STATUS_EFFECT_COLORS
$DAMAGE_TYPE_COLORS = GameData::DAMAGE_TYPE_COLORS
$DAMAGE_TYPE_SPRITES = GameData::DAMAGE_TYPE_SPRITES
$PIDS = GameData::PIDS
$IIDS = GameData::IIDS
$ENCOUNTERS = GameData::ENCOUNTERS
$SHOP_ITEMS = GameData::SHOP_ITEMS
$REWARD_ITEMS = GameData::REWARD_ITEMS
$TUTORIAL_INDEX = 0
$FONT = GameData::FONT

$entity_ids = []
$player = nil
$recipe_book = nil
