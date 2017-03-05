import HeliumLogger // Trivial Logging API that implements the LoggerAPI
import Kitura
import LoggerAPI // General purpose protocol that anyone can use

HeliumLogger.use()
Log.info("About to initialize our router")

let router = Router()

// Don't care if it was a GET, POST etc - hence using all
router.all("/") { (request, response, next) in
    response.send("Hello, Kitura")
    next() // like a pipeline
}

router.all("/") { (request, response, next) in
    response.send("Here's the second completion")
    next()
}

Kitura.addHTTPServer(onPort: 8090, with: router) // Any port above 1024 is available for any user, under it requires admin

Kitura.run() // Any code after this line will never run
