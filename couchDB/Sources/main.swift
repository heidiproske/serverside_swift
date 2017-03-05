import Kitura

let router = Router()

// routes here

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
