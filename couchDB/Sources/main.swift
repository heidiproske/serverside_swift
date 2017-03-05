import CouchDB
import Foundation
import Kitura
import SwiftyJSON

let router = Router()

// MARK: Database
let connectionProperties = ConnectionProperties(host: "localhost", port: 5984, secured: false) // Couch DB port
let client = CouchDBClient(connectionProperties: connectionProperties)
let database = client.database("polls")

// MARK: Routes
router.get("/polls/list") { request, response, next in
    defer { next() }
    // Re the completion blocks, note that Kitura is a synchronous API masking as an async one. Don't be fooled.
    // The trailing closure is really just for readability.
    database.retrieveAll(includeDocuments: true) { docs, error in
        /*
         $ curl -X GET "$COUCH/polls/_all_docs?include_docs=false"
         {"total_rows":2,"offset":0,"rows":[
         {"id":"245226ca9fc3a879cece6242ff002911","key":"245226ca9fc3a879cece6242ff002911","value":{"rev":"1-06284d0a1c326569bcdd158574cbcdcc"}},
         {"id":"245226ca9fc3a879cece6242ff0030dd","key":"245226ca9fc3a879cece6242ff0030dd","value":{"rev":"1-d4e29de380f7794b5414b9e42fc15106"}}
         ]}
         */
        if let error = error {
            // We're an API, so must send back JSON response
            let status = ["status": "error", "message": error.localizedDescription]
            let json = JSON(["result": status])
            response.status(.internalServerError).send(json: json)
            return
        } else {
            let status = ["status": "ok"]
            var polls = [[String: Any]]()

            if let docs = docs {
                // TODO: append a new poll with the data from this doc
            }

            let result: [String: Any] = ["result": status, "polls": polls]
            let json = JSON(result)
            response.status(.OK).send(json: json)
        }
    }
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

// MARK: - Curl Commands

// When you get started, figure out the URL for your CouchDB instance. i.e. launch the admin console
// e.g. http://127.0.0.1:5984
// When running curl commands using CouchDB, you might want to make an alias to simplify the commands
// $ COUCH="localhost:5984"

// MARK: Create database
/*
 $ curl -X GET $COUCH/polls
 {"error":"not_found","reason":"Database does not exist."}

 $ curl -X PUT $COUCH/polls
 {"ok":true}
 
 $ curl -X GET $COUCH/polls
 {"db_name":"polls","update_seq":"0-g1AAAABXeJzLYWBgYMpgTmEQTM4vTc5ISXLIyU9OzMnILy7JAUklMiTV____PyuRAY-iPBYgydAApP5D1GYBAJmvHGw","sizes":{"file":8488,"external":0,"active":0},"purge_seq":0,"other":{"data_size":0},"doc_del_count":0,"doc_count":0,"disk_size":8488,"disk_format_version":6,"data_size":0,"compact_running":false,"instance_start_time":"0"}
 */
