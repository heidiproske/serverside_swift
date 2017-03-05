import Kitura

let router = Router()

Kitura.addHTTPServer(onPort: 8090, with: router) // Any port above 1024 is available for any user, under it requires admin

Kitura.run() // Any code after this line will never run
