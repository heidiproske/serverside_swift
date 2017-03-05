import HeliumLogger // Trivial Logging API that implements the LoggerAPI
import Kitura
import KituraStencil // This wraps Stencil
import LoggerAPI // General purpose protocol that anyone can use

HeliumLogger.use()
Log.info("About to initialize our router")

// MARK: Website for Million Hairs
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

    do {
        try response.render("staff", context: context)
    } catch {
//        try response.render("error", context: [:])
        print(error)
    }
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

// MARK:- Router Chaining

// MARK: Separate code for same request into smaller chunks
// E.g. localhost:8090/hello renders -> "HelloWorld"
router.get("/hello", handler: { request, response, next in
    defer { next() }
    response.send("Hello")
}, { request, response, next in
    defer { next() }
    response.send("World")
})

// MARK: Separate same endpoint for different request types
router.route("/helloDifferent")
    .get() { request, response, next in
        defer { next() }
        response.send("HelloDiff")
    }.post() { request, response, next in
        defer { next() }
        response.send("WorldDiff")
    }

// MARK:- Router parameters

// MARK: Named parameters
// E.g. localhost:8090/games/Katan -> renders -> "Let's play the Katan game"
// curl -vX GET http://localhost:8090/games/Katan
router.get("/games/:name") { request, response, next in
    defer { next() }
    guard let name = request.parameters["name"] else { return }
    response.send("Let's play the \(name) game")
}

// MARK: Query parameters
// curl -vX GET http://localhost:8090/platforms?name="HOLA" -> renders -> Loading the "HOLA" platform
router.get("/platforms") { request, response, next in
    guard let name = request.queryParameters["name"] else {
        try response.status(.badRequest).end()
        return
    }
    response.send("Loading the \(name) platform")
}

// MARK: Form parameters
router.post("/employees/add", middleware: BodyParser())
router.post("/employees/add") { request, response, next in
    guard let values = request.body, case .urlEncoded(let body) = values else { // Try to get a form out of their body
        try response.status(.badRequest).end()
        return
    }

    if let name = body["name"] {
        response.send("Adding new employee... \(name)")
    }
    next()
}

// MARK: JSON parameters
// curl -vX POST -H "content-type: application/json" http://localhost:8090/employees/edit -d '{"name": "Heidi"}'
router.post("/employees/edit", middleware: BodyParser())
router.post("/employees/edit") { request, response, next in
    guard let values = request.body, case .json(let body) = values else {
        try response.status(.badRequest).end()
        return
    }
    if let name = body["name"].string {
        response.send("Edited employee \(name)")
    }
    next()
}

// MARK: Using RegEx
// curl -vX GET http://localhost:8090/search/2016/twostraws
router.get("/search/([0-9]+)/([A-Za-z]+)") {(request, response, next) in
    response.send("Searching...")
}

// MARK: - Kitura

Kitura.addHTTPServer(onPort: 8090, with: router) // Any port above 1024 is available for any user, under it requires admin

Kitura.run() // Any code after this line will never run
