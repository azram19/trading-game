Types =
    Entities:
        HQ: 0
        Platform: 1
        Channel: 2
        Signal: 3
        User: 4
    Resources:
        Metal: 5
        Tritium: 6
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
  root['Types'] = Types
