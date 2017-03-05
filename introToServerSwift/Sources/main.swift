import HeliumLogger // Trivial Logging API that implements the LoggerAPI
import Kitura
import LoggerAPI // General purpose protocol that anyone can use

HeliumLogger.use()
Log.info("About to initialize our router")

let router = Router()

// Don't care if it was a GET, POST etc - hence using all
router.get("/") { request, response, next in
    response.send("<html>")
    response.send("<body>")
    response.send("<h1>Welcome to Million Hairs</h1>")
    response.send("</body>")
    response.send("</html>")
    next() // like a pipeline
}

router.get("/staff") { request, response, next in
    response.send("Meet our great team!")
    next()
}

router.get("/contact") { request, response, next in
    response.send("Get in touch with us!")
    next()
}

Kitura.addHTTPServer(onPort: 8090, with: router) // Any port above 1024 is available for any user, under it requires admin

Kitura.run() // Any code after this line will never run
