var mongoose = require('mongoose')

var userSchema = new mongoose.Schema({
    username: {type: String, unique: true},
    password: String,

    current_room: Number,
	entrance: [Number],
	
	equipment: mongoose.Schema.Types.Mixed,
	soul_equipment: mongoose.Schema.Types.Mixed,
	inventory: [mongoose.Schema.Types.Mixed],
	soul_inventory: [Number],
	map: [[]],
	
	level: Number,
	experience: Number,
	max_hp: Number,
	hp: Number,
	max_mp: Number,
	mp: Number,
	attack: Number,
	defense: Number
})

userSchema.statics.register = function(username, password, cb){
	if (username == "") {
		cb(1)
		return
	}
	if (password == "") {
		cb(3)
		return
	}
	
    var new_user = new User({
        username: username,
        password: password,

        current_room: config.starting_zone,
		entrance: [5, 0],
		// equipment: {head: null, torso: null, feet: null, left_hand: null, right_hand: null, neck: null, ring1: null, ring2: null, ring3: null, ring4: null, hands: null, arms: null, face: null, body: null, pocket: null, ears: null},
		equipment: {},
		inventory: [],
		map: [],
		
		level: 1,
		experience: 0,
		max_hp: 100,
		hp: 100,
		max_mp: 80,
		mp: 80,
		attack: 10,
		defense: 10
    })
	GameLogic.equipment_slots.forEach(function(slot) {new_user.equipment[slot] = null})

    new_user.save(function(err){
        if(!err){
            cb(0)
        }else{
            cb(2)
        }
    })

}

userSchema.statics.login = function(username, password, cb){
	if (playersOnline.includes(username)) {
		cb(3, null)
		return
	}
	
    User.findOne({username: username}, function(err, user){
        if(!err && user){
            if(user.password == password){
                cb(0, user)
            }else{
                cb(2, null)
            }
        }else{
            cb(1, null)
        }

    })
}

module.exports = User = gamedb.model('User', userSchema)