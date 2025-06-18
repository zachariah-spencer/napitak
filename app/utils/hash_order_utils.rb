# frozen_string_literal: true

module HashOrderUtils
  def self.front(hash, key)
    raise KeyError, "Key not found" unless hash.key?(key)

    value = hash.delete(key)
    hash.replace({ key => value }.merge(hash))
  end

  def self.back(hash, key)
    raise KeyError, "Key not found" unless hash.key?(key)

    value = hash.delete(key)
    hash[key] = value
    hash
  end
end
