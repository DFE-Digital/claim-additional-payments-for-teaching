class Reference
  def to_s
    Nanoid.generate(alphabet: characters_to_use, size: 8)
  end

  private

  def characters_to_use
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  end
end
