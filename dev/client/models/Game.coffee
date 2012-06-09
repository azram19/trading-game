class Game extends Backbone.Model
  default:
    name: 'none'
    channel: 'none'
    players: []
    type: 0
    typeData: {}

window.S.Models.Game = Game
