Types =
    Entities:
        HQ: 1
        Platform: 2
        Channel: 3
        Signal: 4
        Player: 5
    Resources:
        Metal: 6
        Tritium: 7
        Names: [
            "Metal"
            "Tritium"
        ]
        Amounts: [
            100
            100
        ]
    Platforms:
        Normal: 0


if module? and module.exports
  exports = module.exports = Types
else
  window['Types'] = Types
