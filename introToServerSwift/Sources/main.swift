import HeliumLogger // Trivial Logging API that implements the LoggerAPI
import Kitura
import KituraStencil // This wraps Stencil
import LoggerAPI // General purpose protocol that anyone can use

HeliumLogger.use()
Log.info("About to initialize our router")

let router = Router()
router.setDefault(templateEngine: StencilTemplateEngine())

// Don't care if it was a GET, POST etc - hence using all
router.get("/") { request, response, next in
    defer { next() }

    try response.render("home", context: [:])
}

router.get("/staff") { request, response, next in
    defer { next() }

    response.send("Meet our great team!")
}

router.get("/contact") { request, response, next in
    defer { next() }

    response.send("Get in touch with us!")
}

Kitura.addHTTPServer(onPort: 8090, with: router) // Any port above 1024 is available for any user, under it requires admin

Kitura.run() // Any code after this line will never run
