const { exec } = require('child_process')

module.exports = RoomInstance = {
	instances: [],
	
	newInstance: function(roomID) {
		// instances.push(this)
		this.roomID = roomID
		this.clients = []
		
		exec(config.client + ' -server -' + roomID, (err, stdout, stderr) => {
			if (err) {
				console.log(err)
				return
			}

			// the *entire* stdout and stderr (buffered)
			console.log(`stdout: ${stdout}`)
			console.log(`stderr: ${stderr}`)
		})
	}
}