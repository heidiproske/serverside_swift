import HeliumLogger // Trivial Logging API that implements the LoggerAPI
import Kitura
import KituraStencil // This wraps Stencil
import LoggerAPI // General purpose protocol that anyone can use

HeliumLogger.use()
Log.info("About to initialize our router")

let bios = [
    "kirk": "My name is James Kirk and I love snakes.",
    "picard": "My name is Jean-Luc and I love fish.",
    "archer": "My name is Jonathan and I love beagles.",
    "janeway": "My name is Kathryn and I want to hug every hamster."
]

let router = Router()
router.setDefault(templateEngine: StencilTemplateEngine())

// Note the "static" is defined in prefixes of all our URLs in the master.stencil
router.all("/static", middleware: StaticFileServer()) // Middleware, acts as a pipeline that jumps in when needed (like encryption, compression etc)

router.get("/") { request, response, next in
    defer { next() }

    try response.render("home", context: [:])
}

router.get("/staff") { request, response, next in
    defer { next() }
    var context = [String: Any]()
    context["people"] = bios.keys.sorted()
    try response.render("staff", context: context)
}

router.get("/staff/:name") { request, response, next in
    defer { next() }
    guard let name = request.parameters["name"] else { return }

    var context = [String: Any]()
    if let bio = bios[name] {
        context["name"] = name
        context["bio"] = bio
    }

    context["people"] = bios.keys.sorted()

    try response.render("teamMember", context: context)
}

router.get("/contact") { request, response, next in
    defer { next() }

    try response.render("contact", context: [:])
}

Kitura.addHTTPServer(onPort: 8090, with: router) // Any port above 1024 is available for any user, under it requires admin

Kitura.run() // Any code after this line will never run
