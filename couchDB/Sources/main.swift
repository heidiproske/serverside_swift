import Kitura
import SwiftyJSON

let router = Router()

// MARK: Utility functions
func jsonResultWithStatus(_ status: String) -> JSON {
    let result = ["status": status]
    let json = JSON(["result": result])
    return json
}

// MARK: Routes
router.get("/polls/list") { request, response, next in
    defer { next() }
    let json = jsonResultWithStatus("ok")
    response.status(.OK).send(json: json)
}

router.post("/polls/create") { request, response, next in
    defer { next() }
}

router.post("/polls/vote/:pollid/:option") { request, response, next in
    defer { next() }
}


// MARK: Kitura
Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
